#!/usr/bin/env bash

set -eu

pg_restore --verbose --clean --no-acl --no-owner -h localhost -d fleetyards_dev ./dumps/latest.dump
