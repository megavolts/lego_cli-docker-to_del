#!/bin/bash
# Script to test build the docker image locally

GIT_DIR=$(pwd)

# Import buildvars
DOCKER_IMAGE_VERSION=$(cat ${GIT_DIR}/buildvars | awk '/^DOCKER_IMAGE_VERSION=/' | cut -d= -f2)
RELEASE_VERSION=$(echo $DOCKER_IMAGE_VERSION | cut -d= -f2 | cut -d- -f1)
RELEASE_TAG=v$DOCKER_IMAGE_VERSION

# Check for late previous released

echo $RELEASE_NOTE