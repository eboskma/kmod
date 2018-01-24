export MODULE_NAME := kmod
export BUILD_DIRECTORY := target/kernel
export CFILES := $(wildcard src/*.c)
export RUSTFILES := $(wildcard src/*.rs)

KERNELDIR ?= /lib/modules/$(shell uname -r)/build
ARCH ?= x86_64
CROSS_COMPILE ?= x86_64-linux-gnu-
RUST_TARGET ?= x86_64-unknown-linux-gnu

ifeq "$(ARCH)" "arm"
	EXTRA_RUSTCFLAGS = -C target-feature=+soft-float,-neon,-vfp3,-vfp2
endif

export RUSTCFLAGS := -C opt-level=3 -C code-model=kernel -C relocation-model=static $(EXTRA_RUSTCFLAGS)

ifneq "$(VERBOSE)" "1"
.SILENT:
endif

all default: modules
install: modules_install

modules modules_install help:
	@mkdir -p ${BUILD_DIRECTORY}/src
	cp "Makefile.in" "${BUILD_DIRECTORY}/Makefile"
	@$(MAKE) -C $(KERNELDIR)  M=${PWD}/${BUILD_DIRECTORY} ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) RUST_TARGET=$(RUST_TARGET) $@

clean:
	cargo clean

test: clean all modules
	sudo insmod ${BUILD_DIRECTORY}/${MODULE_NAME}.ko
	sudo rmmod ${MODULE_NAME}
	dmesg -H | tail