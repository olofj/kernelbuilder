FROM gentoo/portage:latest as portage

FROM local/stage3-native as toolchains

# Slightly slimmer Gentoo
ENV FEATURE="nodoc noinfo noman"

# copy the entire portage volume in
COPY --from=portage /usr/portage /usr/portage

COPY crossdev.conf /etc/portage/repos.conf/crossdev.conf
COPY toolchain.unmask /etc/portage/package.keywords/toolchain
RUN mkdir /usr/local/portage-crossdev

COPY 0001-Add-RISC-V-support-to-crossdev.patch 0002-Add-riscv-to-the-Linux-short-list.patch /etc/portage/patches/sys-devel/crossdev/
RUN emerge crossdev

# X86 8.2.0 toolchain (and picking it by default)

RUN emerge crossdev sys-devel/gcc sys-devel/binutils sys-libs/binutils-libs \
 && gcc-config x86_64-pc-linux-gnu-8.2.0

# ARM toolchains

RUN crossdev --gcc 8.2.0 --binutils 2.31.1 -s1 -t arm \
 && crossdev --gcc 8.2.0 --binutils 2.31.1 -s1 -t arm64

# RISCV toolchain

RUN crossdev --gcc 8.2.0 --binutils 2.31.1 -s1 -t riscv64-unknown-linux-gnu --k 4.17 --l 2.28 --without-headers

# POWER toolchain

RUN crossdev --gcc 8.2.0 --binutils 2.31.1 -s1 -t ppc64

# Tools needed to do builds

RUN emerge vim dev-vcs/git strace bc lzop

# Cleanup and don't carry the portage stuff

#RUN rm -rf /usr/portage /var/log/portage /usr/local/portage-crossdev

# Re-populate to lose wasted space by portage
#FROM scratch
#COPY --from=toolchains / /

RUN groupadd -g 1001 build
RUN useradd -m -u 1001 -g 1001 -s /bin/bash build

COPY batchbuild /usr/local/bin/batchbuild
COPY makefile /home/build/makefile.batchbuild
COPY buildreport /usr/local/bin/

USER build
WORKDIR /src
ENTRYPOINT ["/usr/local/bin/batchbuild"]
CMD "."