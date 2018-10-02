Kernelbuilder docker setup.

This builder is setup using gentoo toolchains and system image, rebuilt
for the local architecture to maximize efficiency (it does make a bit
of difference).

General setup for the container:

/src is the directory for the kernel sources
/build is the temporary output (tmpfs recommended, but can grow quite large)
/install is where the kernel is installed to
/logs are where logs are written out to


Build the locally tuned version:

docker build -t local/stage3-native -f Dockerfile.gentoo-base
