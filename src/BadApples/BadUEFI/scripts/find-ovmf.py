# Copyright (c) 2026
# Horst's Public Assets Clusters (Horstaufmental)
# SPDX-License-Identifier: GPL-3.0-or-later

from pathlib import Path

paths = [
    # On Fedora, this directory contains symlinks
    # to `/usr/share/edk2/ovmf` 
    "/usr/share/OVMF/",
    # Found in Ubuntu systems, also includes `OVMF.fd`
    "/usr/share/ovmf/",
    "/usr/share/ovmf/x64",
    "/usr/share/edk2/ovmf/",
    # Found in Gentoo systems
    "/usr/share/edk2-ovmf/",
]

def main():
    for p in paths:
        path = Path(p)
        try:
            names = {f.name for f in path.iterdir()}
        except:
            continue
        if "OVMF.fd" in names:
            # manual override: combined firmware image
            print(path / "OVMF.fd")
            return
        if "OVMF_CODE.fd" in names and "OVMF_VARS.fd" in names:
            print(path / "OVMF_CODE.fd")
            print(path / "OVMF_VARS.fd")
            return

if __name__ == "__main__":
    main()
