#!/bin/bash -ex

cd $TRAVIS_BUILD_DIR/sphinx && make html
cd $TRAVIS_BUILD_DIR && git clone https://github.com/NetCommons3/NetCommons3.git
export APP_ROOT=$TRAVIS_BUILD_DIR/NetCommons3/app
cd $TRAVIS_BUILD_DIR && phpdoc -d $APP_ROOT -t $TRAVIS_BUILD_DIR/phpdoc/ -i "$APP_ROOT/Plugin/DebugKit/*,$APP_ROOT/Plugin/Migrations/*,$APP_ROOT/Plugin/MobileDetect/*,$APP_ROOT/Config/*,$APP_ROOT/Plugin/Public/*,$APP_ROOT/Test/*"
