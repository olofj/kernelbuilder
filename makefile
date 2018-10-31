# makefile for parallel kernel builds, sorry for my primitive
# skills, I'm sure it can be written in a simpler way

CROSS_COMPILE_arm = arm-unknown-linux-gnueabi-
CROSS_COMPILE_arm64 = aarch64-unknown-linux-gnu-
CROSS_COMPILE_x86 = x86_64-pc-linux-gnu-
CROSS_COMPILE_i386 = x86_64-pc-linux-gnu-
CROSS_COMPILE_riscv = riscv64-unknown-linux-gnu-
#CCACHE_DIR	:= /nv/ccache
#CCACHE_BASEDIR  := $(PWD)
#CCACHE_UMASK    := 002
#CC              := "ccache $(CROSS_COMPILE)gcc"
O               := obj-tmp

CC		?= "$(CROSS_COMPILE)gcc"

#export ARCH CROSS_COMPILE CC O CCACHE_DIR CCACHE_UMASK CCACHE_BASEDIR
export O

ALLCONFIGS := $(wildcard arch/$(ARCH)/configs/*config)
ALLTARGETS := $(patsubst arch/$(ARCH)/configs/%,build-$(ARCH)-%,$(ALLCONFIGS))

LOGDIR ?= .

%:
	+@$(MAKE) -f Makefile O=$(O) $@

all:
	+@$(MAKE) -f Makefile O=$(O)

.PHONY: buildall

build/%:
	@mkdir -p build/$*

define buildrules
build-$(1)-%: build/$(1)-%
	+@$(MAKE) -f Makefile ARCH=$(1) CROSS_COMPILE="$$(CROSS_COMPILE_$(1))" O=$$< $$* > /dev/null
	+@$(MAKE) -f Makefile ARCH=$(1) CROSS_COMPILE="$$(CROSS_COMPILE_$(1))" O=$$< olddefconfig > /dev/null
	+@$(MAKE) -sk -f Makefile ARCH=$(1) CROSS_COMPILE="$$(CROSS_COMPILE_$(1))" O=$$< 2> buildall.$(1).$$*.log \
		&& mv buildall.$(1).$$*.log $(LOGDIR)/buildall.$(1).$$*.log.passed \
		|| mv buildall.$(1).$$*.log $(LOGDIR)/buildall.$(1).$$*.log.failed
	rm -rf $$<
endef

ARCHES:=arm arm64 x86 i386 riscv
$(foreach arch,$(ARCHES),$(eval $(call buildrules,$(arch))))

tcinfo-%:
	@$(CROSS_COMPILE_$*)gcc -v 2>&1 | tail -1 > $(LOGDIR)/tc.$*

tcinfo: $(foreach arch,$(ARCHES),t-$(arch))

buildall: tcinfo $(ALLTARGETS)
