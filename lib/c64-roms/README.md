# C64 ROM files

This directory is the runtime home for the three Commodore 64 system ROM
images required by the VICE x64sc emulator.

| File      | Description                   | Size  |
|-----------|-------------------------------|-------|
| `kernal`  | C64 KERNAL ROM 901227-03      | 8 KiB |
| `basic`   | C64 BASIC ROM  901226-01      | 8 KiB |
| `chargen` | C64 character-generator ROM   | 4 KiB |

## Source

The ROM files are fetched automatically from
[asig/vice-roms](https://github.com/asig/vice-roms) during the CI build and
cached with `actions/cache`.  They are **not** committed to this repository.

The binary files are listed in `.gitignore` so they are never accidentally
committed.

## Local development

To run VICE locally, copy or symlink the three files here:

```sh
# example – adjust the source path to wherever your VICE data lives
cp /usr/share/vice/C64/kernal-901227-03.bin  lib/c64-roms/kernal
cp /usr/share/vice/C64/basic-901226-01.bin   lib/c64-roms/basic
cp /usr/share/vice/C64/chargen-901225-01.bin lib/c64-roms/chargen
```

Then run:

```sh
make screenshot   # builds the PRG and takes a VICE title-screen screenshot
```
