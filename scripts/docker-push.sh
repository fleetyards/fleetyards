#!/usr/bin/env bash

set -eu

pushd docker

echo
echo "Base Container..."
echo

pushd base

docker build -t fleetyards/base:2.5.1 .
docker push fleetyards/base:2.5.1

popd

echo
echo "CI Container..."
echo

pushd ci

docker build -t fleetyards/ci:2.5.1 .
docker push fleetyards/ci:2.5.1

popd

echo
echo "...Done"
echo

popd
