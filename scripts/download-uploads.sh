#!/usr/bin/env bash

set -eu

s3cmd sync "s3://fleetyards" ./public
