#!/usr/bin/env bash

set -eu

pushd ./docker-compose

docker-compose up -d

popd
