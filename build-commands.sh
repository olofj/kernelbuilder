#!/bin/bash -ex
# Slightly slimmer Gentoo
export FEATURE="buildpkg usepkg nodoc noinfo noman"

# X86 toolchain (and picking it by default)
emerge crossdev sys-devel/gcc sys-devel/binutils sys-libs/binutils-libs  \
	 vim dev-vcs/git strace bc lzop elfutils cpio sys-devel/multilib-gcc-wrapper \
	dev-python/pip dev-libs/libyaml u-boot-tools

# Sparse is good to have for check builds

GCCVER="${GCCVER-">=11.2.0"}"
BINUTILSVER="${BINUTILSVER-">=2.37"}"

mkdir -p /var/db/repos/localrepo-crossdev/{profiles,metadata}
echo 'crossdev' > /var/db/repos/localrepo-crossdev/profiles/repo_name
echo 'masters = gentoo' > /var/db/repos/localrepo-crossdev/metadata/layout.conf
chown -R portage:portage /var/db/repos/localrepo-crossdev


mkdir -p /etc/portage/repos.conf
cat > /etc/portage/repos.conf/crossdev.conf <<EOF
[crossdev]
location = /var/db/repos/localrepo-crossdev
priority = 10
masters = gentoo
auto-sync = no
EOF


cd /src/jobclient && make && cp jobclient jobserver jobforce jobcount /usr/local/bin/

# x86_64 toolchain if needed 
#x86_64-pc-linux-gnu-gcc --version || crossdev --gcc ${GCCVER} --binutils ${BINUTILSVER} -s1 -t amd64

# ARM toolchains
crossdev -s1 -t arm
crossdev -s1 -t arm64
#crossdev --gcc ${GCCVER} --binutils ${BINUTILSVER} -s1 -t arm
#crossdev --gcc ${GCCVER} --binutils ${BINUTILSVER} -s1 -t arm64

# RISCV toolchain
crossdev -s1 -t riscv64
#crossdev --gcc ${GCCVER} --binutils ${BINUTILSVER} -s1 -t riscv64

# POWER toolchain
#crossdev --gcc ${GCCVER} --binutils ${BINUTILSVER} -s1 -t ppc64

# MIPS toolchain
#crossdev --gcc ${GCCVER} --binutils ${BINUTILSVER} -s1 -t mips64

# Timezone
echo "US/Pacific" > /etc/timezone
emerge --config sys-libs/timezone-data

# Cleanup and don't carry the portage stuff
#rm -rf /usr/portage /var/log/portage /usr/local/portage-crossdev

# CLeanup some other stuff too that's not needed
#rm -rf /usr/share/gtk-doc /usr/share/locale && rm -rf /usr/share/binutils-data/*/*/info /usr/share/sgml && rm -rf /usr/lib/python*/test && cd / && find / -name __pycache__  | xargs rm -rf

su build -c 'pip3 install --user git+https://github.com/devicetree-org/dt-schema.git@master'
su user -c 'pip3 install --user git+https://github.com/devicetree-org/dt-schema.git@master'
