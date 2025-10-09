#!/bin/bash
# Script to test build the docker image locally

GIT_DIR=$(pwd)

# Import buildvars
BUILD_DATE=$(cat ${GIT_DIR}/buildvars | awk '/^BUILD_DATE=/' | cut -d= -f2)
BUILD_VERSION=$(cat ${GIT_DIR}/buildvars | awk '/^DOCKER_IMAGE_VERSION=/' | cut -d= -f2)

# Check if BUILD_VERSION is already released
# Check for latest released
if [[ $(curl -s https://api.github.com/repos/megavolts/lego_cli/releases | grep "status" | cut -d\" -f4) = 404 ]];
    then
    echo "No release existing"
else
    LATEST_RELEASE=$(curl -s https://api.github.com/repos/megavolts/lego_cli/releases | jq '.[0] | .name' -r | grep -Eo '([0-9]+)(\.?[0-9]+)*' | head -1)

    if [[ $LATEST_RELEASE = $BUILD_VERSION ]];
        then
        echo "Release $BUILD_VERSION already exist. Updated build version with next revisoin"
        PACKAGE_VERSION=$( $BUILD_VERSION | cut -d- -f1)
        BUILD_REVISION=$( $BUILD_VERSION | cut -d- -f1)
        BUILD_REVISION=$(( $BUILD_REVISION +1 ))
        BUILD_VERSION=$PACKAGE_VERSION-$BUILD_REVISION
    fi
fi

echo "Building docker image version $BUILD_VERSION on $BUILD_DATE"

docker buildx build $GIT_DIR/lego_cli/ \
        -t megavolts/lego_cli:testbuild \
        --build-arg BUILD_VERSION=$BUILD_VERSION \
        --build-arg BUILD_DATE=$BUILD_DATE \
        --build-arg TARGETARCH="linux/amd64" \
        --load