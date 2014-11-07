#!/bin/bash -ex

APP=`basename $CLASS_DOC_SOURCE_URI | perl -pi -e 's/([^\/]+)\.git$/$1/'`
CLASS_DOC_SOURCE_ROOT=$WORKSPACE/$APP
APP_ROOT=$CLASS_DOC_SOURCE_ROOT/app
LOG=/var/log/jenkins/phpdoc.log

# Clear previous build
rm -rf $APP
cat /dev/null > $LOG

# Generate sphinx docs
cd $WORKSPACE/sphinx
make html
cd -

# Install all plugins
git clone $CLASS_DOC_SOURCE_URI
cd $CLASS_DOC_SOURCE_ROOT
cp tools/build/app/cakephp/composer.json .
hhvm `which composer` update --prefer-dist

# Init phpdoc options
for p in `cat app/Config/vendors.txt`
do
  IGNORE_PLUGINS="$IGNORE_PLUGINS,*/app/Plugin/$p/*"
done
IGNORE_PLUGINS=`echo $IGNORE_PLUGINS | cut -c 2-`

# Exit on parse error
phpdoc parse -d $APP_ROOT -t $WORKSPACE/phpdoc -i $IGNORE_PLUGINS,*/Config/* --force --ansi >> $LOG
[ `grep -c '\[37;41m' $LOG` -ne 0 ] && cat $LOG && exit 1

# Generate class docs
phpdoc -d $APP_ROOT -t $WORKSPACE/phpdoc -i $IGNORE_PLUGINS,*/Config/*
