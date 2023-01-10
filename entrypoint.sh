#!/bin/bash

set -euo pipefail

bundle exec rails db:create db:migrate

exec "$@"
