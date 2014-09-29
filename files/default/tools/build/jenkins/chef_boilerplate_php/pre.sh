#!/bin/bash -ex

if [ "$ENVIRONMENT" = "development" ]
then
  bundle update
  berks update
else
  bundle install --without development
  berks install -e development
fi
