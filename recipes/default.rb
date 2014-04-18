#
# Cookbook Name:: boilerplate_php
# Recipe:: default
#
# Copyright (C) 2014, Jun Nishikawa <topaz2@m0n0m0n0.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

include_recipe 'boilerplate'

# apt_repository "hhvm-#{node[:lsb][:codename]}" do
#   uri 'http://dl.hhvm.com/ubuntu'
#   distribution node[:lsb][:codename]
#   components ['main']
#   key 'http://dl.hhvm.com/conf/hhvm.gpg.key'
#   not_if { ::File.exist?("/etc/apt/sources.list.d/hhvm-#{node[:lsb][:codename]}.list") }
# end

# Install packages necessary for this project
%w(
  php5 php5-mysql php5-curl php5-cli php5-imagick php5-xdebug php5-mcrypt php5-xsl php-pear
  apache2-mpm-prefork libapache2-mod-php5
  python-pip
).each do |pkg|
  package pkg do
    action [:install, :upgrade]
    version node.default[:versions][pkg] if node.default[:versions][pkg].kind_of? String
  end
end

# Install gem packages
execute 'install php related gem packages' do
  command "cd #{node[:boilerplate][:app_root]}; gemrat guard-phpcs guard-phpmd guard-phpunit2 --no-version"
  only_if { ::File.exist?("#{node[:boilerplate][:app_root]}/Gemfile") }
end

# Install pear packages
%w( pear.phpunit.de pear.phpmd.org pear.pdepend.org pear.phpdoc.org ).each do |channel|
  php_pear_channel channel do
    action :discover
  end
end
if node[:boilerplate_php].key?(:cakephp) && node[:boilerplate_php][:cakephp]
  # cakephp 2.x is not compatible with phpunit 4.x
  execute 'install phpunit' do
    command 'pear config-set auto_discover 1; pear install --alldeps phpunit/PHPUnit-3.7.32'
    not_if { ::File.exist?('/usr/bin/phpunit') }
  end

  execute 'install phpcs' do
    command 'pear channel-discover pear.cakephp.org; pear install --alldeps cakephp/CakePHP_CodeSniffer'
    not_if { ::File.exist?('/usr/bin/phpcs') }
  end
else
  execute 'install phpunit' do
    command 'pear config-set auto_discover 1; pear install --alldeps phpunit/PHPUnit'
    not_if { ::File.exist?('/usr/bin/phpunit') }
  end

  execute 'install phpcs' do
    command 'pear install --alldeps pear/PHP_CodeSniffer'
    not_if { ::File.exist?('/usr/bin/phpcs') }
  end
end

execute 'install phpmd' do
  command 'pear install --alldeps phpmd/PHP_PMD'
  not_if { ::File.exist?('/usr/bin/phpmd') }
end

execute 'install pdepend' do
  command 'pear install --alldeps pdepend/PHP_Depend'
  not_if { ::File.exist?('/usr/bin/pdepend') }
end

execute 'install phpcpd' do
  command 'pear install --alldeps phpunit/phpcpd'
  not_if { ::File.exist?('/usr/bin/phpcpd') }
end

execute 'install phploc' do
  command 'pear install --alldeps phpunit/phploc'
  not_if { ::File.exist?('/usr/bin/phploc') }
end

execute 'install phpcb' do
  command 'pear install --alldeps phpunit/PHP_CodeBrowser'
  not_if { ::File.exist?('/usr/bin/phpcb') }
end

execute 'install phpdoc' do
  command 'pear install --alldeps phpdoc/phpDocumentor'
  not_if { ::File.exist?('/usr/bin/phpdoc') }
end

# Install packages
%w( sphinx sphinxcontrib-phpdomain ).each do |p|
  python_pip p
end

# Install or update composer
composer "#{node[:boilerplate][:app_root]}" do
  owner 'www-data'
  group 'www-data'
  action [:install, :update]
end

# Update composer packages
execute 'update composer packages' do
  command "cd #{node[:boilerplate][:app_root]}; `which composer` update"
  only_if { ::File.exist?("#{node[:boilerplate][:app_root]}/composer.json") }
end

# Deploy configuration files
## Setup php
template '/etc/php5/cli/php.ini' do
  source 'php/php.ini.erb'
  mode 0644
  variables(:directives => node[:php][:directives])
end

## Setup apache
include_recipe 'apache2'

%w( sphinx phpdoc ).each do |site|
  next unless node[:boilerplate_php][site]
  template "#{node[:apache][:dir]}/sites-available/#{site}" do
    source "apache2/#{site}.erb"
    notifies :restart, 'service[apache2]'
  end
  apache_site site do
    enable true
  end
end

# Setup pre-commit hook
template "#{node[:boilerplate][:app_root]}/.git/hooks/pre-commit" do
  source 'git/pre-commit'
  mode 0755
  only_if { ::File.exist?("#{node[:boilerplate][:app_root]}/.git/hooks") }
end

## Setup jenkins
if node[:boilerplate].key?(:jenkins) && node[:boilerplate][:jenkins]
  include_recipe 'jenkins::master'

  if node[:boilerplate_php].key?(:cakephp)
    cmd = 'cd /var/lib/jenkins/jobs/ && git clone https://github.com/vitorpc/cakephp-jenkins-template.git cakephp-template && chown -R jenkins:nogroup cakephp-template'
    template = 'cakephp-template'
  else
    cmd = 'cd /var/lib/jenkins/jobs/ && mkdir php-template && cd php-template && wget https://raw.github.com/sebastianbergmann/php-jenkins-template/master/config.xml && cd .. && chown -R jenkins:nogroup php-template'
    template = 'php-template'
  end
  execute 'install jenkins template for php project' do
    command cmd
    not_if { ::File.exist?("/var/lib/jenkins/jobs/#{template}") }
  end

  %w(
    analysis-core checkstyle cloverphp dry htmlpublisher jdepend php plot pmd violations xunit
  ).each do |p|
    jenkins_plugin p
  end
end
