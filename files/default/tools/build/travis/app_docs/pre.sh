#!/bin/bash -ex

if [ "$ENVIRONMENT" = "development" ]
then
  bundle update
  bundle ex berks update
else
  bundle install --without development
  bundle ex berks install -e development
fi

sudo apt-get install graphviz
sudo pip install sphinx
mkdir -p build/logs
pear channel-discover pear.phpdoc.org
pear install phpdoc/phpDocumentor
phpenv rehash
set +H
