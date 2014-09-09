#!/bin/bash -ex

sudo apt-get install graphviz
sudo pip install sphinx
mkdir -p build/logs
pear channel-discover pear.phpdoc.org
pear install phpdoc/phpDocumentor
phpenv rehash
set +H

WORKSPACE=$TRAVIS_BUILD_DIR
