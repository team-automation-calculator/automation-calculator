#!/usr/bin/env bash

#Least awful way I can think of making this work on CircleCI after a day at work and two beers
echo $SEMVER_MAJOR_VERSION"."$SEMVER_MINOR_VERSION"."$SEMVER_PATCH"-"$CIRCLE_BUILD_NUM