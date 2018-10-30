# Kernelbuilder docker setup

This builder is setup using Gentoo toolchains and system image.

## General setup for the container

 - /src is the directory for the kernel sources git repo, mounted read-only
 - /build is the checked out kernel and temporary output (tmpfs recommended, but can grow quite large)
 - /install is where the kernels are installed to, currently unused
 - /logs are where logs are written out to, emails into /logs/emails

## A few words on performance

Since this setup makes it easy to produce toolchains and userland
for several of the x86\_64 sub-ABIs, I've experimented a bit with x86
(32-bit) vs x86\_64 vs x32. I've also made `-march=native` builds to
see if running with generically tuned toolchains leaves performance on
the floor on my hardware.

My hardware is a 32-core Threadripper 2990WX, with 64GB RAM and NVMe
(Samsung 980 EVO).

Without including all performance data, in general most runs are along
the below runtimes. There is some noise in the data from run to run,
but most of them come out around these relative ballparks when building
both 32- and 64-bit targets:

 - Generic x86\_64:    2419 seconds time elapsed
 - `-mtune-native`:    2386 seconds time elapsed
 - Generic x86:        2392 seconds time elapsed
 - Generic x32:        2171 seconds time elapsed

So:

 - Building with `-march=native` buys ~1%
 - Building with a x86 toolchain buys ~5-6%
 - Building with a x32 toolchain buys ~10%

Conclusion: The choice for me right now is quite simple. I am using
the x32 docker image for the main builder workload.

### Building the locally tuned version:

```
docker build -t local/stage3-native -f Dockerfile.gentoo-base .
docker build -t local/builder .
```

### Building the other images

I've gotten lazy and written an ugly script for it. A Makefile would
be nicer but since Docker caches intermediate layers it's not quite
as needed.

```
./build-images.sh
```

## Running the image to do a build

A few of the polling-loop hacks I have aren't in this repo, but this is
how they launch the container:

```
#!/bin/bash

[...]

container="local/kernelbuilder"

# build <remote> <ref>
build() {
        CNTR="${container}"
        case $2 in
                v3*)
                        CNTR="${container}-7.3.0"
                        ;;
                v4.[2-9]*)
                        CNTR="${container}-7.3.0"
                        ;;
                v4.1[0-8]*)
                        CNTR="${container}-7.3.0"
                        ;;
        esac
        docker run -t --mount type=bind,src=/home/build/work/batch,dst=/src,ro \
                --mount type=bind,src=/ds/logs/buildlogs,dst=/logs \
                --tmpfs /build:size=60G,exec \
                --net none \
                -e ARCH="riscv x86 arm arm64" \
                ${CNTR} \
                "$1/$2"
}
```
