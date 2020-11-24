#!/usr/bin/env bash

set -eu

aws s3 sync "s3://fleetyards" ./public
