#!/bin/bash

set -euo pipefail

bundle exec rails db:create

# Two pods that start together both run db:migrate. Rails takes a Postgres
# advisory lock, and the pod that loses it fails with
# ActiveRecord::ConcurrentMigrationError. Retry so that pod waits for the winner
# and then finds nothing to migrate. Any migrate failure is retried; a migration
# that is really broken still fails the container once the attempts run out.
# The command is the `until` condition, so `set -e` does not exit on a failure.
migrate_max_attempts=6
migrate_retry_delay_seconds=5
migrate_attempt=1

until bundle exec rails db:migrate; do
  if [ "$migrate_attempt" -ge "$migrate_max_attempts" ]; then
    echo "entrypoint: db:migrate failed (attempt ${migrate_attempt} of ${migrate_max_attempts}); giving up" >&2
    exit 1
  fi

  echo "entrypoint: db:migrate failed (attempt ${migrate_attempt} of ${migrate_max_attempts}); retrying in ${migrate_retry_delay_seconds}s" >&2
  sleep "$migrate_retry_delay_seconds"
  migrate_attempt=$((migrate_attempt + 1))
done

exec "$@"
