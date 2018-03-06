#!/usr/bin/env bash

REPO=automationcalculator/automation-calculator-rails

latest_image=$REPO":latest"
semver_tag=$(./create_docker_image_tag.sh)
semver_image=$REPO":"$semver_tag
docker tag $latest_image $semver_image
