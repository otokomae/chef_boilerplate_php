default[:boilerplate_php][:git] = {
  hooks: {
    lint: 'php/lint',
    phpcs: 'php/phpcs',
    phpmd: 'php/phpmd',
    phpunit: 'php/phpunit'
  }
}

default[:boilerplate_php][:framework] = {
  type: :symfony
}
default[:boilerplate_php][:symfony] = {
  version: '2.x',
  git: {
    hooks: {
    }
  }
}
default[:boilerplate_php][:cakephp] = {
  version: '2.x',
  git: {
    hooks: {
      phpcs: 'cakephp/phpcs',
      phpunit: 'cakephp/phpunit'
    }
  }
}
default[:boilerplate_php][:sphinx] = {
  host: 'sphinx.local',
  port: '80',
  path: '/'
}
default[:boilerplate_php][:phpdoc] = {
  host: 'phpdoc.local',
  port: '80',
  path: '/'
}

# Merge framework specific hooks
default[:boilerplate_php][:git][:hooks].update(default[:boilerplate_php][node[:boilerplate_php][:framework][:type]][:git][:hooks])
