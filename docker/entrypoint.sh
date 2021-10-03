#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /fleetyards/tmp/pids/server.pid

if [[ -z "${INITIAL_DB_SETUP}" ]]; then
  bundle exec rails db:create db:schema:load
fi

bundle exec rails db:migrate

# bundle exec thor search:index

# bundle exec rails db:seed

exec "$@"
