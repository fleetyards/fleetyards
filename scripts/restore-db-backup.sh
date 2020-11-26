#!/usr/bin/env bash

set -eu

docker-compose exec postgres pg_restore --verbose --clean --no-acl --no-owner -h localhost -d fleetyards_dev /backups/latest.dump
