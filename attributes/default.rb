default[:boilerplate_php][:framework] = {
  :type => :symfony
}
default[:boilerplate_php][:symfony] = {
  :version => '2.x'
}
default[:boilerplate_php][:cakephp] = false
default[:boilerplate_php][:sphinx] = {
  :host => 'sphinx.local',
  :port => '80',
  :path => '/'
}
default[:boilerplate_php][:phpdoc] = {
  :host => 'phpdoc.local',
  :port => '80',
  :path => '/'
}
