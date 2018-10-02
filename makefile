# makefile for parallel kernel builds, sorry for my primitive
# skills, I'm sure it can be written in a simpler way

CROSS_COMPILE_arm = arm-unknown-linux-gnueabi-
CROSS_COMPILE_arm64 = aarch64-unknown-linux-gnu-
CROSS_COMPILE_x86 = x86_64-pc-linux-gnu-
CROSS_COMPILE_riscv = riscv64-unknown-linux-gnu-
#CCACHE_DIR	:= /nv/ccache
#CCACHE_BASEDIR  := $(PWD)
#CCACHE_UMASK    := 002
#CC              := "ccache $(CROSS_COMPILE)gcc"
O               := obj-tmp

CC		?= "$(CROSS_COMPILE)gcc"

#export ARCH CROSS_COMPILE CC O CCACHE_DIR CCACHE_UMASK CCACHE_BASEDIR
export O

INSTALLDIR ?= /install/$(USER)
ALLCONFIGS := $(wildcard arch/$(ARCH)/configs/*config)
ALLTARGETS := $(patsubst arch/$(ARCH)/configs/%,build-$(ARCH)-%,$(ALLCONFIGS))

VERSIONDIR ?= .

%:
	+@$(MAKE) -f Makefile O=$(O) $@

all:
	+@$(MAKE) -f Makefile O=$(O)

.PHONY: buildall

installdir:
	-@mkdir -p $(INSTALLDIR)/$(VERSIONDIR)

buildtargets:
	mkdir -p build
	( echo $(patsubst build-%,%,$(ALLTARGETS))) | ( cd build && xargs mkdir -p ;)

build/%:
	@mkdir -p build/$*

build-x86-%: build/x86-%
	+@$(MAKE) -f Makefile ARCH=x86 O=$< $* > /dev/null
	+$(MAKE) -f Makefile O=$< ARCH=x86 CROSS_COMPILE="$(CROSS_COMPILE_x86)" 2> buildall.x86.$*.log \
		&& mv buildall.x86.$*.log buildall.x86.$*.log.passed \
		|| mv buildall.x86.$*.log buildall.x86.$*.log.failed

build-riscv-%: build/riscv-%
	+@$(MAKE) -f Makefile ARCH=riscv O=$< $* > /dev/null
	+$(MAKE) -f Makefile O=$< ARCH=riscv CROSS_COMPILE="$(CROSS_COMPILE_riscv)" 2> buildall.riscv.$*.log \
		&& mv buildall.riscv.$*.log buildall.riscv.$*.log.passed \
		|| mv buildall.riscv.$*.log buildall.riscv.$*.log.failed

build-arm64-%: build/arm64-%
	+@$(MAKE) -f Makefile ARCH=arm64 O=$< $* > /dev/null
	+$(MAKE) -f Makefile O=$< ARCH=arm64 CROSS_COMPILE="$(CROSS_COMPILE_arm64)" 2> buildall.arm64.$*.log \
		&& mv buildall.arm64.$*.log buildall.arm64.$*.log.passed \
		|| mv buildall.arm64.$*.log buildall.arm64.$*.log.failed

build-arm-%: build/arm-%
	+@$(MAKE) -f Makefile ARCH=arm O=$< $* > /dev/null
	+$(MAKE) -f Makefile O=$< ARCH=arm CROSS_COMPILE="$(CROSS_COMPILE_arm)" 2> buildall.arm.$*.log \
		&& mv buildall.arm.$*.log buildall.arm.$*.log.passed \
		|| mv buildall.arm.$*.log buildall.arm.$*.log.failed

rand-%: build/rand-%
	$(eval SEED := $(patsubst build/rand-%,%,$<))
	+@$(MAKE) -f Makefile O=$< KCONFIG_SEED=$(SEED) randconfig > /dev/null
	echo KCONFIG_SEED=$(SEED) > $</buildlog
	+if $(MAKE) -f Makefile O=$< CROSS_COMPILE="$(CROSS_COMPILE)" 2>> $</buildlog ; then \
		cp $</buildlog randbuild.$(ARCH).$(SEED).log.passed ; \
	else \
		cp $</buildlog randbuild.$(ARCH).$(SEED).log.failed ; \
        fi 

install-%: build-% installdir
	$(eval BD := $(patsubst build-%,%,$<))
	$(eval ID := $(INSTALLDIR)/$(VERSIONDIR))
	-@mkdir -p $(ID)/$(BD)
	-@$(MAKE) -f Makefile O=build/$(BD) INSTALL_PATH=$(ID)/$(BD) INSTALL_MOD_PATH=$(ID)/$(BD)/modules modules_install 2> /dev/null
	-@cp build/$(BD)/arch/$(ARCH)/boot/*Image $(ID)/$(BD)/
	-@cp build/$(BD)/vmlinux $(ID)/$(BD)/
	-@cp build/$(BD)/.config $(ID)/$(BD)/
	-@cp build/$(BD)/System.map $(ID)/$(BD)/
	-@mkdir -p $(ID)/$(BD)/dtbs
	-@rsync -aqP --include='*/' --include='*.dtb' --exclude='*' build/$(BD)/arch/$(ARCH)/boot/dts/ $(ID)/$(BD)/dtbs/ 2> /dev/null

clean-%: build/%
	@echo `date -R` $<
	+@$(MAKE) -f Makefile O=$< clean > /dev/null
	@echo `date -R` $< done

cleanall: $(patsubst install-%,clean-%,$(ALLTARGETS))
	@

buildall: $(ALLTARGETS)
