#!/bin/bash
readonly version=${1:-"0.2.0"}
readonly namespace="bigsisl/binserve"
readonly image="$namespace:$version"

pushd "$(dirname "$0")"
docker build . \
    --build-arg BINSERVE_VERSION="$version" \
    -t "$image"
popd

docker push $image
