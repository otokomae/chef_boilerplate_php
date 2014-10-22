#!/bin/bash -ex

foodcritic -f any --tags ~FC001 --tags ~FC014 .
rspec --color --format progress
rubocop
kitchen test --destroy=always -c `ohai cpu/total`
# knife cookbook site share boilerplate_php Utilities -u topaz2
