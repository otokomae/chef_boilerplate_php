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

chef_gem 'chef-helpers'
require 'chef-helpers'

begin
  hhvm = 'hhvm'
  include_recipe 'hhvm'
  service 'hhvm' do
    action [:enable, :start]
  end
  template '/etc/hhvm/server.ini' do
    source 'hhvm/server.ini.erb'
  end
rescue
  hhvm = ''
end

# Install packages necessary for this project
%w(
  php5 php5-mysql php5-curl php5-cli php5-imagick php5-xdebug php5-mcrypt php5-xsl php-pear
  libapache2-mod-php5
  python-pip
).each do |pkg|
  package pkg do
    action [:install, :upgrade]
  end
end

# Install pre-commit hooks
%W( php #{node[:boilerplate_php][:framework][:type]} ).each do |hooks|
  remote_directory "/usr/share/git-core/templates/hooks/#{hooks}" do
    files_mode 0755
    source "git/hooks/#{hooks}"
  end
end

template '/usr/share/git-core/templates/hooks/pre-commit' do
  source 'git/pre-commit'
  mode 0755
  only_if { ::File.exist?("#{node[:boilerplate][:app_root]}/.git/hooks") }
end

execute 'initialize git hooks' do
  command 'git init'
  cwd node[:boilerplate][:app_root]
  only_if { ::File.exist?(node[:boilerplate][:app_root]) }
end

# Install gem packages
# execute 'install php related gem packages' do
#   command "cd #{node[:boilerplate][:app_root]}; gemrat guard-phpcs guard-phpmd guard-phpunit2 --no-version"
#   only_if { ::File.exist?("#{node[:boilerplate][:app_root]}/Gemfile") }
# end

ruleset =
  if File.exist?(
    run_context.cookbook_collection[:boilerplate_php]
    .preferred_filename_on_disk_location(
      run_context.node,
      :files, "build/#{node[:boilerplate_php][:framework][:type]}/phpmd/rules.xml"
    ))
    "build/#{node[:boilerplate_php][:framework][:type]}/phpmd/rules.xml"
  else
    'build/default/phpmd/rules.xml'
  end
directory '/etc/phpmd'
cookbook_file '/etc/phpmd/rules.xml' do
  source ruleset
end

# Install packages
%w( sphinx sphinxcontrib-phpdomain ).each do |p|
  python_pip p
end

# Install or update composer
include_recipe 'composer'
composer node[:boilerplate][:app_root] do
  owner 'www-data'
  group 'www-data'
  action [:install, :update]
  only_if { ::File.exist?("#{node[:boilerplate][:app_root]}/composer.json") }
end

# Update composer packages
execute 'update composer packages' do
  command "cd #{node[:boilerplate][:app_root]}; #{hhvm} `which composer` update"
  only_if { ::File.exist?("#{node[:boilerplate][:app_root]}/composer.json") }
end

# Setup framework specific permissions
directory "#{node[:boilerplate][:app_root]}/app/tmp" do
  mode 0777
  recursive true
  only_if { node[:boilerplate_php][:cakephp] }
end

# Add write permission to default session.save_path
directory '/var/lib/php5' do
  owner 'www-data'
  group 'www-data'
  mode 0755
end

# Deploy configuration files
## Setup php
%w( cli apache2 ).each do |type|
  template "/etc/php5/#{type}/php.ini" do
    source 'php/php.ini.erb'
  end
end

## Setup apache
include_recipe 'apache2'

%w( sphinx phpdoc ).each do |site|
  next unless node[:boilerplate_php][site]
  template "#{node[:apache][:dir]}/sites-available/#{site}.conf" do
    source "apache2/#{site}.conf.erb"
    notifies :restart, 'service[apache2]'
  end
  apache_site site do
    enable true
  end
end

## Setup jenkins
if node[:boilerplate_jenkins]
  include_recipe 'jenkins::master'

  jobs = []
  %w(
    development staging production
  ).each do |environment|
    %w(
      chef_boilerplate_php
    ).each do |type|
      jobs << [environment, type].join('_')
    end
  end
  jobs.each do |job|
    next unless has_template?("jenkins/jobs/#{job}/config.xml.erb")

    xml = File.join(Chef::Config[:file_cache_path], "jenkins-jobs-#{job}-config.xml")
    template xml do
      source "jenkins/jobs/#{job}/config.xml.erb"
    end

    jenkins_job job do
      config xml
      not_if { ::File.exist?("#{node[:jenkins][:master][:home]}/jobs/#{job}/config.xml") }
    end

    template "#{node[:jenkins][:master][:home]}/jobs/#{job}/config.xml" do
      source "jenkins/jobs/#{job}/config.xml.erb"
    end
  end

  %w(
    analysis-core checkstyle cloverphp dry htmlpublisher jdepend php plot pmd violations xunit
  ).each do |p|
    jenkins_plugin p
  end

  remote_directory '/usr/local/bin/tools/build/jenkins' do
    files_mode 0755
    source 'tools/build/jenkins'
  end
end

## Setup phpenv
# execute 'install phpenv' do
#   command 'git clone git://github.com/phpenv/phpenv.git .phpenv'
# end

# execute 'export phpenv' do
#   command 'echo \'export PATH="$HOME/.phpenv/bin:$PATH"\' >> ~/.bash_profile'
# end

# execute 'phpenv rehash' do
#   command 'echo \'eval "$(phpenv init -)"\' >> ~/.bash_profile && exec $SHELL && phpenv rehash'
# end
