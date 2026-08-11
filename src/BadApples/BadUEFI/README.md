# Bad UEFI

An **UEFI** application that plays (audio-less) Bad Apple on your screen.

# Instructions

> [!IMPORTANT]
> No pre-built binaries will be provided for now.

## Compile from Source

### Prerequisites

- Linux/UNIX Environment (Windows users are recommended to use WSL)
- [Git LFS](https://git-lfs.com/)
- [mtools](https://www.gnu.org/software/mtools/)
- [Rust Toolchain](https://rust-lang.org/tools/install/)
- [QEMU](https://www.qemu.org/) (Optional, must be x86_64 target)
- [OVMF](https://www.tianocore.org/tianocore-wiki.github.io/development/tutorials-howto/how_to_run_ovmf.html) (Required IF using QEMU)

The repository must be cloned with **Git LFS**. If not, follow the [install instructions](https://git-lfs.com/)
and run this command to pull in actual assets.

```bash
    git lfs pull
```

### Build

To simply JUST build the EFI application (without the image):

```bash
    cargo build --release
```

Makefile is used here as a wrapper to Cargo and other commands for producing the final image.

```bash
    # The building goes roughly like so:
    # Compile EFI App -> Reorder the tarball -> Create FAT image in build/
    make
```

One may choose to test this with QEMU:

```bash
    # The script looks for either both `OVMF_CODE.fd` andd `OVMF_VARS.fd`
    # or simply `OVMF.fd` in following directories:
    # `/usr/share/OVMF/`, `/usr/share/ovmf/`, `/usr/share/ovmf/x64`,
    # `/usr/share/edk2/ovmf`, `/usr/share/edk2-ovmf/`

    # If your OVMF files are not in these directories, you must manually
    # specify them.
    # e.g. `OVMF_SRC=$'/path/to/ovmf/code.fd\n/path/to/ovmf/vars.fd' make qemu`
    # (Each paths must be seperated by a newline)
    make qemu
```

### Booting on real hardware

> [!CAUTION]
> This section assumes your empty/spare USB stick is at `/dev/sdb`.
> Double (Triple even) check that your path to the stick is correct.
> Failure to do so will cause **SEVERE INREVERSIBLE DATA LOSS**.

> [!IMPORTANT]
> Make sure the USB stick (or whatever storage device you have)
> doesn't have any valuable data, backup if present.
> The following operations will wipe **ALL THE DATA** that's originally in there.

> [!NOTE]
> This method has not been tested and may not work in all cases.

While the image file we produced works great for QEMU, thers's however no guarantee that
it would be able to be used to write directly to a device, so the following steps
will have to be done instead.

```bash
    # Change to your actual USB stick.
    export DEVICE=/dev/sdb

    # Wipe and create a new partition (/dev/sdb1)
    sudo parted $DEVICE mklabel gpt
    sudo parted $DEVICE mkpart BOOT fat32 2048s 512M
    sudo parted $DEVICE set 1 esp on

    # Format the partiton
    sudo mkfs.vfat ${DEVICE}1 -F 32

    # Mount and drag files over to the device
    sudo mount ${DEVICE}1 /mnt
    sudo mkdir -p /mnt/EFI/BOOT
    sudo cp target/x86_64-unknown-uefi/release/bad-uefi.efi \
        /mnt/EFI/BOOT/BOOTX64.EFI
    sudo cp build/frames.tar.xz /mnt/

    # Now un-mount
    sudo umount /mnt
```

# Caveats

While this depends on the hardware and environment, the performance may slightly (or largely) differs
between regular QEMU (with TCG), QEMU with KVM and real hardware.

There is a minimum delay of 20ms per each frame so there is less likely of a "going too fast" situation.

# License

This implementation is licensed under **GPL-3.0-or-later** (GNU General Public License v3 or later).

See [COPYING](./COPYING) for full details.
