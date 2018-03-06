#!/usr/bin/env bash

REPO="automationcalculator/automation-calculator-rails"
tag=$(./scripts/create_docker_image_tag.sh)
docker push $REPO:$tag