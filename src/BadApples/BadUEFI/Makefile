# Copyright (c) 2026
# Horst's Public Assets Clusters (Horstaufmental)
# SPDX-License-Identifier: GPL-3.0-or-later

TARGET := x86_64-unknown-uefi
APP := target/$(TARGET)/release/bad-uefi.efi
FRAMES := assets/frames.tar.xz
SORTED_FRAMES := build/frames.tar.xz
STAGE := build/root
IMG := build/bad-uefi.img
SIZE := 512
KVM := $(shell test -e /dev/kvm && echo "-enable-kvm")
OVMF_DIR := build/ovmf
OVMF_SRC ?= $(shell python scripts/find-ovmf.py)
OVMF := $(addprefix $(OVMF_DIR)/,$(notdir $(OVMF_SRC)))

.PHONY: all clean FORCE

all: $(IMG)

$(IMG): $(APP) $(SORTED_FRAMES)
	rm -f $@
	fallocate -l$(SIZE)M $@
	mkfs.vfat -F 32 -n EFI $@
	mmd -i $@ ::/EFI
	mmd -i $@ ::/EFI/BOOT
	mcopy -i $@ $(SORTED_FRAMES) ::/frames.tar.xz
	mcopy -i $@ $(APP) ::/EFI/BOOT/BOOTX64.EFI
	@echo "Built $@"

# The source tarball is not in frame order, and the player streams the tar
# one entry at a time, so it must be re-ordered. The zero-padded frame names
# sort numerically under a plain glob.
$(SORTED_FRAMES): $(FRAMES)
	rm -rf $(STAGE)
	mkdir -p $(STAGE)
	tar -xJf $< -C $(STAGE)
	(cd $(STAGE) && tar -cJf $(CURDIR)/$@ frame_*.png)
	rm -rf $(STAGE)

$(OVMF): $(OVMF_SRC)
	@mkdir -p $(OVMF_DIR)
	cp $(filter %$(notdir $@),$^) $@

$(APP): FORCE
	cargo build --release

clean:
	cargo clean
	rm -rf build

qemu: $(IMG) $(OVMF)
	qemu-system-x86_64 $(KVM) -drive file=$(IMG),format=raw $(foreach f,$(OVMF),-drive if=pflash,file=$(f),format=raw)

FORCE:
