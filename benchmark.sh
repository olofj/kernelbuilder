#!/bin/bash

# Note that fstrim is done with sudo, you'll need it passwordless for
# that command (or take it out)

# This only builds ARM (32-bit), since it's the current investigation to
# compare amd64 vs x86 vs amd64-x32.

REF=next/master
ARCH=${ARCH:-arm}

purge_dirs() {
	echo "Cleaning up temporary workspace"
       	docker run --mount type=bind,src=/tmp/logs,dst=/logs \
		--mount type=bind,src=/work/scratch,dst=/build \
		--net none \
		--entrypoint /bin/sh \
		alpine:latest \
		-c 'rm -rf /logs/* /build/* /build/.??*'
}

kmsg() {
	sudo bash -c "echo $* > /dev/kmsg"
}

mkdir /tmp/logs ; chmod 777 /tmp/logs
echo "Setting kernel.perf_event_paranoid = -1"
sudo sysctl -w kernel.perf_event_paranoid=-1

if ! grep -q zram /proc/swaps ; then
	sudo zramctl  -s 20G /dev/zram0
	sudo mkswap /dev/zram0
	sudo swapon /dev/zram0
	sudo mount -t tmpfs -o size=80G none /work/scratch
fi

# less for bug repro
#for cont in builder-generic-x32 ; do
for cont in builder-generic-x32 builder-generic-x86 builder-generic; do
	kmsg "cleaning up"
	purge_dirs
	kmsg "fstrimming"
	sudo fstrim -av
	kmsg "building"
	echo 3 > /proc/sys/vm/drop_caches
	echo " :::::   BUILDING ${cont} warmup"
	perf stat -a -o perfstat.${cont}.warmup \
	       	docker run --mount type=bind,src=/home/build/work/batch,dst=/src,ro \
			--mount type=bind,src=/tmp/logs,dst=/logs \
			--mount type=bind,src=/work/scratch,dst=/build \
			--net none \
			-e ARCH="${ARCH}" \
			local/${cont} \
			${REF} | tee output.${cont}.warmup
	kmsg "build done"
	cat /proc/swaps
	sudo zramctl /dev/zram0
	df
	cat perfstat.${cont}.warmup
	cp /tmp/logs/emails/* .

	kmsg "cleaning up"
	purge_dirs
	kmsg "fstrimming"
	sudo fstrim -av
	kmsg "building"
	echo 3 > /proc/sys/vm/drop_caches
	echo " :::::   BUILDING ${cont}"
	perf stat -a -o perfstat.${cont} \
	       	docker run --mount type=bind,src=/home/build/work/batch,dst=/src,ro \
			--mount type=bind,src=/tmp/logs,dst=/logs \
			--mount type=bind,src=/work/scratch,dst=/build \
			--net none \
			-e ARCH="${ARCH}" \
			local/${cont} \
			${REF} | tee output.${cont}
	kmsg "build done"
	cat /proc/swaps
	sudo zramctl /dev/zram0
	df
	cat perfstat.${cont}
	for e in  /tmp/logs/emails/* ; do 
		cp ${e} email.${cont}.$(basename ${e})
	done
done
