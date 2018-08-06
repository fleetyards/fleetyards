#!/usr/bin/env bash

set -eu

pushd docker

echo
echo "Build Container..."
echo

docker build -t fleetyards/app:2.5.1 .

echo
echo "Push Container..."
echo

docker push fleetyards/app:2.5.1

echo
echo "...Done"
echo

popd
