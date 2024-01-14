# makefile for parallel kernel builds, sorry for my primitive
# skills, I'm sure it can be written in a simpler way

CROSS_COMPILE_arm = arm-unknown-linux-gnueabi-
CROSS_COMPILE_arm64 = aarch64-unknown-linux-gnu-
CROSS_COMPILE_x86 = x86_64-pc-linux-gnu-
CROSS_COMPILE_i386 = x86_64-pc-linux-gnu-
CROSS_COMPILE_riscv = riscv64-unknown-linux-gnu-

LOGDIR ?= .

build/%:
	@mkdir -p build/$*

define buildrules
.PRECIOUS: $(LOGDIR)/build.$(1).%.started

$(LOGDIR)/build.$(1).%.started: build/$(1)-% 
	@echo $(shell hostname) >> $(LOGDIR)/build.$(1).$$*.started
	@echo start: $$*
	+@$(MAKE) -f Makefile ARCH=$(1) CROSS_COMPILE="$$(CROSS_COMPILE_$(1))" O=$$< $$* > /dev/null
	+@$(MAKE) -f Makefile ARCH=$(1) CROSS_COMPILE="$$(CROSS_COMPILE_$(1))" O=$$< olddefconfig > /dev/null
	+@$(MAKE) -sk -f Makefile ARCH=$(1) CROSS_COMPILE="$$(CROSS_COMPILE_$(1))" O=$$< 2> buildall.$(1).$$*.log \
		&& mv buildall.$(1).$$*.log $(LOGDIR)/buildall.$(1).$$*.log.passed \
		|| mv buildall.$(1).$$*.log $(LOGDIR)/buildall.$(1).$$*.log.failed
	@echo done: $$*
	-@rm -rf $$<

build-$(1)-%: $(LOGDIR)/build.$(1).%.started
	true

endef

ARCHES:=arm arm64 x86 i386 riscv
$(foreach arch,$(ARCHES),$(eval $(call buildrules,$(arch))))
