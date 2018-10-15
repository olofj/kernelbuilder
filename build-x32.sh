#!/bin/bash

# Hacked script to build x32 gentoo stage3 docker image, adapted from
# https://github.com/gentoo/gentoo-docker-images.git
# This needs the stage3 dockerfile from the above repo, i.e. run this from
# a checked out version of it.

TARGET=stage3-x32
VERSION=${VERSION:-$(date -u +%Y%m%d)}

export BOOTSTRAP="multiarch/alpine:x86-v3.7"

docker build --build-arg BOOTSTRAP="${BOOTSTRAP}" --build-arg SUFFIX="x32"  -t "gentoo/${TARGET}:${VERSION}" -f "stage3.Dockerfile" .
docker tag "gentoo/${TARGET}:${VERSION}" "gentoo/${TARGET}:latest"
