#!/bin/bash

# Lazy script to rebuild all images.

docker build --rm -t local/kernelbuilder:latest -t local/kernelbuilder:"$(date +%Y%m%d_%H%M)" .
docker build --rm --build-arg GCCVER="~8.3.0" -t local/kernelbuilder-8.3.0:latest -t local/kernelbuilder-8.3.0:"$(date +%Y%m%d_%H%M)" .
docker build --rm --build-arg GCCVER="~7.3.0" -t local/kernelbuilder-7.3.0:latest -t local/kernelbuilder-7.3.0:"$(date +%Y%m%d_%H%M)" .
