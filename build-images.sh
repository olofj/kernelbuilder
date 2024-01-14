#!/bin/bash

# Lazy script to rebuild all images.

VER="${VER:-$(date +%Y%m%d_%H%M)}"

do_toolchain() {
	GCC=${1:-"FOO=1"}
	BIN=${2:-"BAR=1"}
	# Do nothing if it already exists
	docker image inspect local/toolchains"${SUF}":${VER} > /dev/null  && return

	rm -f base.${VER} run.${VER}
	docker build --iidfile base.${VER}  .
	docker run -e "${GCC}" -e "${BIN}" --cidfile run.${VER} --privileged -t -i -v $(pwd):/src --entrypoint=/src/build-commands.sh --user=root $(cat base.${VER})
	docker commit $(cat run.${VER}) local/toolchains"${SUF}":"${VER}"
}

do_builder() {
	(sed -e "s/%%VER%%/${VER}/g" -e "s@local/toolchains@local/toolchains${SUF}@g" <<EOF
FROM local/toolchains:%%VER%%

VOLUME ["/src"]
VOLUME ["/build"]

USER build
WORKDIR /src
ENTRYPOINT ["/bin/bash"]
EOF

	) > Dockerfile.${VER}
	docker build -f Dockerfile.${VER} -t local/kernelbuilder"${SUF}":"${VER}" -t local/kernelbuilder"${SUF}":latest .
	rm Dockerfile.${VER}
}

do_toolchain
do_builder


#docker build --rm --build-arg GCCVER="~8.3.0" -t local/kernelbuilder-8.3.0:latest -t local/kernelbuilder-8.3.0:"${VER}" .
#docker build --rm --build-arg GCCVER="~7.3.0" -t local/kernelbuilder-7.3.0:latest -t local/kernelbuilder-7.3.0:"${VER}" .
