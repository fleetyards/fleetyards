#!/usr/bin/env bash

set -eu

PGPASSWORD=password pg_restore --verbose --clean --no-acl --no-owner -h localhost -U root -p 8271 -d fleetyards_main_dev ./dumps/latest.dump
