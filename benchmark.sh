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
		--entrypoint /bin/bash \
		local/stage3-native \
		-c 'rm -rf /logs/* /build/* /build/.??*'
}

mkdir /tmp/logs ; chmod 777 /tmp/logs
echo "Setting kernel.perf_event_paranoid = -1"
sudo sysctl -w kernel.perf_event_paranoid=-1

for cont in builder-generic-x32 builder-generic-x86 builder-generic builder ; do
	purge_dirs
	sudo fstrim -av
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
	cat perfstat.${cont}.warmup
	cp /tmp/logs/emails/* .

	purge_dirs
	sudo fstrim -av
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
	cat perfstat.${cont}
	cp /tmp/logs/emails/* .
done
