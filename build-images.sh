#!/bin/bash

# Lazy script to rebuild all images.

# -march=native container. Not sure it buys us anything yet, but here it is.
#docker build -t local/stage3-native -f Dockerfile.gentoo-base .

docker build -t local/builder .
for img in generic generic-x86 generic-x32 ; do
	docker build -t local/builder-${img} -f Dockerfile.${img} .
done

