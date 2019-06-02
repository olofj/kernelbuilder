#!/bin/bash

# Note that fstrim is done with sudo, you'll need it passwordless for
# that command (or take it out)

# This only builds ARM (32-bit), since it's the current investigation to
# compare amd64 vs x86 vs amd64-x32.

REF=misc/to-build
ARCH=${ARCH:-arm64}

kmsg() {
	sudo bash -c "echo $* > /dev/kmsg"
}

echo "Setting kernel.perf_event_paranoid = -1"
sudo sysctl -w kernel.perf_event_paranoid=-1

# less for bug repro
#for cont in builder-generic-x32 ; do
for cont in local/kernelbuilder ; do
	mv /tmp/logs $(mktemp -u /tmp/logs.XXXXX)
	mkdir -p /tmp/logs/misc
	chmod 777 /tmp/logs/misc
	chmod 777 /tmp/logs
#	kmsg "fstrimming"
#	sudo fstrim -av
	kmsg "building"
	echo 3 > /proc/sys/vm/drop_caches
	echo " :::::   BUILDING ${cont} warmup"
	perf stat -a -o perfstat.$(uname -r).warmup \
	       	docker run --mount type=bind,src=/home/build/work/batch,dst=/src,ro \
			--mount type=bind,src=/tmp/logs,dst=/logs \
			--tmpfs /build,size=60G,exec \
			--net none \
			-e ARCH="${ARCH}" \
			${cont} \
			misc ${REF} | tee output.$(uname -r).warmup
	kmsg "build done"
	cat perfstat.$(uname -r).warmup
	cp /tmp/logs/emails/* .

	mv /tmp/logs $(mktemp -u /tmp/logs.XXXXX)
	mkdir -p /tmp/logs/misc
	chmod 777 /tmp/logs/misc
	chmod 777 /tmp/logs
#	kmsg "fstrimming"
#	sudo fstrim -av
	kmsg "building"
	echo 3 > /proc/sys/vm/drop_caches
	echo " :::::   BUILDING ${cont}"
	perf stat -a -o perfstat.$(uname -r) \
	       	docker run --mount type=bind,src=/home/build/work/batch,dst=/src,ro \
			--mount type=bind,src=/tmp/logs,dst=/logs \
			--tmpfs /build,size=60G,exec \
			--net none \
			-e ARCH="${ARCH}" \
			${cont} \
			misc ${REF} | tee output.$(uname -r)
	kmsg "build done"
	cat perfstat.$(uname -r)
	for e in  /tmp/logs/emails/* ; do 
		cp ${e} email.$(uname -r).$(basename ${e})
	done
done
