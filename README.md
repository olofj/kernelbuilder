# Kernelbuilder docker setup

This builder is setup using gentoo toolchains and system image, rebuilt
for the local architecture to maximize efficiency (it does make a bit
of difference, specifig numbers pending).

## General setup for the container

 - /src is the directory for the kernel sources git repo, mounted read-only
 - /build is the checked out kernel and temporary output (tmpfs recommended, but can grow quite large)
 - /install is where the kernels are installed to, currently unused
 - /logs are where logs are written out to


## Build the locally tuned version:

```
docker build -t local/stage3-native -f Dockerfile.gentoo-base .
docker build -t local/builder .
```

Running the image to do a build

```
docker run --mount type=bind,src=/home/build/work/batch,dst=/src,ro \
	--mount type=bind,src=/ds/logs/buildlogs,dst=/logs \
	--mount type=bind,src=/work/scratch,dst=/build \
	--net none \
	local/builder \
	arm-soc/for-next
```
