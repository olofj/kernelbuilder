FROM gentoo/portage:latest as portage
FROM gentoo/stage3-x32:latest as toolchains

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

RUN emerge crossdev sys-devel/gcc sys-devel/binutils sys-libs/binutils-libs 

# Tools needed to do builds
RUN emerge vim dev-vcs/git strace bc lzop
RUN emerge elfutils cpio

# Sparse is good to have for check builds
RUN emerge sparse

ARG GCCVER=">=9.1.0"

# x86_64 toolchain if needed 
RUN x86_64-pc-linux-gnu-gcc --version || crossdev --gcc ${GCCVER} --binutils \>=2.32 -s1 -t x86_64

# ARM toolchains
RUN crossdev --gcc ${GCCVER} --binutils \>=2.32 -s1 -t arm
RUN crossdev --gcc ${GCCVER} --binutils \>=2.32 -s1 -t arm64

# RISCV toolchain
RUN crossdev --gcc ${GCCVER} --binutils \>=2.32 -s1 -t riscv64-unknown-linux-gnu --k 4.17 --l 2.28 --without-headers

# POWER toolchain
RUN crossdev --gcc ${GCCVER} --binutils \>=2.32 -s1 -t ppc64

# MIPS toolchain
RUN crossdev --gcc ${GCCVER} --binutils \>=2.32 -s1 -t mips64

# Timezone
RUN echo "US/Pacific" > /etc/timezone
RUN emerge --config sys-libs/timezone-data

RUN emerge dev-python/pip

RUN emerge libyaml

# Cleanup and don't carry the portage stuff
RUN rm -rf /usr/portage /var/log/portage /usr/local/portage-crossdev

# CLeanup some other stuff too that's not needed
RUN rm -rf /usr/share/gtk-doc /usr/share/locale \
 && rm -rf /usr/share/binutils-data/*/*/info /usr/share/sgml \
 && rm -rf /usr/lib/python*/test \
 && cd / && find / -name __pycache__  | xargs rm -rf

# Re-populate to lose wasted space by portage
FROM scratch
COPY --from=toolchains / /

# Local user, scripts
RUN groupadd -g 1001 build
RUN useradd -m -u 1001 -g 1001 -s /bin/bash build

# Let's do a 1000 too
RUN groupadd -g 1000 user
RUN useradd -m -u 1000 -g 1000 -s /bin/bash user

RUN su build -c 'pip3 install --user git+https://github.com/devicetree-org/dt-schema.git@master'
RUN su user -c 'pip3 install --user git+https://github.com/devicetree-org/dt-schema.git@master'

COPY batchbuild /usr/local/bin/batchbuild
COPY makefile /home/build/makefile.batchbuild
COPY buildreport /usr/local/bin/

USER build
WORKDIR /src
ENTRYPOINT ["/usr/local/bin/batchbuild"]
CMD "."
ENV PATH=${PATH}:/home/build/.local/bin:/home/user/.local/bin

# Volumes for the expected mountpoints:
#   /src is read-only sources (git repo)
#   /build is temporary build output (tmpfs)
#   /logs is where emails and logs are published
VOLUME ["/src"]
VOLUME ["/build"]
VOLUME ["/logs"]
