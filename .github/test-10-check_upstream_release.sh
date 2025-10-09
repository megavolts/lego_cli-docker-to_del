#!/bin/bash
# Script to test build the docker image locally

GIT_DIR=$(pwd)
echo $GIT_DIR

# Check upstream version
echo "Check Upstream Release"
## Upstream Release
BOOL="$(curl -s https://api.github.com/repos/go-acme/lego/releases | jq '.[0] | .prerelease')"
if $BOOL; then
    echo "Pre-release, skipping"
    exit 1
else
    LEGO_VERSION="$(curl -s https://api.github.com/repos/go-acme/lego/releases | jq '.[0] | .name' -r | grep -Eo '([0-9]+)(\.?[0-9]+)*' | head -1)"
fi

## Get current version in lego_cli docker
DOCKER_LEGO_VERSION="$(cat ${LEGO_DIR}/buildvars | awk '/^DOCKER_IMAGE_VERSION=/' | cut -d= -f2 | cut -d- -f1)"
DOCKER_REVISION="$(cat ${LEGO_DIR}/buildvars | awk '/^DOCKER_IMAGE_VERSION=/' | cut -d= -f2 | cut -d- -f2))"

## Notify if update is found
if ! [[ "${LEGO_VERSION}" = "${DOCKER_LEGO_VERSION}" ]]; then
echo "Update found for Unbound"
BUILD_REVISION=0
BUILD_DATE=$(date  --iso-8601)
LEGO_VERSION=$LEGO_VERSION
BUILD_REVISION=$BUILD_REVISION
DOCKER_IMAGE_VERSION=$LEGO_VERSION-$BUILD_REVISION

echo BUILD_DATE=$BUILD_DATE > buildvars
echo LEGO_VERSION=$LEGO_VERSION >> buildvars
echo DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION >> buildvars
echo "Upcoming release version: $DOCKER_IMAGE_VERSION"

else
echo "No update found"
BUILD_REVISION=$DOCKER_REVISION
fi 