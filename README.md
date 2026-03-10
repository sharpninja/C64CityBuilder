# C64 City Builder

A modern city-building game for the **Commodore 64**, written entirely in
**6510 Assembly** using the [CA65 / LD65](https://cc65.github.io/) toolchain.

---

## Gameplay

Build and manage a growing city on the classic Commodore 64 hardware.
Lay roads and utilities, zone housing and industry, and keep your citizens
happy while balancing the city budget. Rebuilding on an existing structure
upgrades that tile through four density levels, with colour indicating how
intensely the tile is developed.

### Controls

| Key | Action |
|-----|--------|
| `W` / `A` / `S` / `D`  or cursor keys | Move cursor |
| `1` | Select **Road** ($10) |
| `2` | Select **House** ($100) |
| `3` | Select **Factory** ($500) |
| `4` | Select **Park** ($200) |
| `5` | Select **Power Plant** ($1 000) |
| `6` | Select **Police Station** ($300) |
| `7` | Select **Fire Station** ($300) |
| `RETURN` or `B` | Build selected building or upgrade the matching tile's density |
| `X` | Reduce density by one level, or demolish when a tile is at base density |
| `Q` | Return to title screen |

### Screen Layout

```
Rows  0-19  │  40×20 city map (cursor shown as a white box sprite)
Row  20     │  PWR / HAP / CRM stats
Row  21     │  Year / Cash / Population
Row  22     │  Building selector menu (selected entry highlighted yellow)
Row  23     │  Mode label + timed messages
Row  24     │  Controls help line
```

### Simulation

Every second (~60 frames) the city simulation runs:

* **Income** – each factory earns $50 / tick
* **Expenses** – every building has upkeep (roads $1, houses $2, factories
  $10, parks $5, power plants $50, police/fire $20 each)
* **Power** – power plants supply 50 units each; houses need 5, factories 20
* **Happiness** – base 50, +10 per park, −10 if power deficit, −½ crime
* **Crime** – base 40, −10 per police station
* **Density** – buildable tiles have four density levels; each level adds one
  more unit of that building type to the simulation and changes the tile colour
* **Population** – grows toward `houses × 10` when happy ≥ 50; shrinks when
  happiness < 30
* **Year** – advances every 12 simulation ticks (~12 seconds real time)

---

## Building

### Requirements

* [cc65](https://cc65.github.io/) suite – provides `ca65` (assembler) and `ld65` (linker)

```
# Ubuntu / Debian
sudo apt-get install cc65

# macOS (Homebrew)
brew install cc65
```

### Compile

```bash
make
```

This produces **`citybuilder.prg`** – a standard C64 PRG file that loads at
address `$0801`.

```bash
make clean   # remove object files and PRG
```

### Running

Load `citybuilder.prg` in any Commodore 64 emulator that accepts PRG files,
for example **VICE**:

```bash
x64sc citybuilder.prg        # VICE C64 emulator
```

Or transfer to real hardware via a SD2IEC, 1541 Ultimate, or similar device.
At the BASIC prompt:

```
LOAD "CITYBUILDER.PRG",8,1
RUN
```

---

## Project Structure

```
C64CityBuilder/
├── Makefile          – build rules (ca65 + ld65)
├── linker.cfg        – LD65 memory map (BASIC stub at $0801, code at $080D)
└── src/
    ├── main.s        – entry point, BASIC SYS stub, main game loop
    ├── constants.s   – VIC-II / CIA registers, game constants
    ├── zeropage.s    – zero-page variable layout ($02-$48)
    ├── init.s        – hardware initialisation, map setup
    ├── title.s       – title / credits screen
    ├── input.s       – KERNAL GETIN keyboard handler
    ├── map.s         – BSS city_map array, tile rendering, sprite cursor
    ├── buildings.s   – build / upgrade / demolish logic, density-aware counts
    ├── simulation.s  – economic & population simulation tick
    ├── ui.s          – status-bar renderer, decimal number printer
    └── data.s        – lookup tables (mul40, tile chars/colours, density ramps, costs, strings)
```

---

## Technical Notes

* **CPU**: MOS 6510 (6502-compatible), all code assembled for `--cpu 6502`
* **Video**: VIC-II text mode, 40×25 characters, direct screen/colour RAM writes
* **Input**: KERNAL `GETIN` ($FFE4) with automatic key-repeat
* **Timing**: KERNAL jiffy counter at `$A2` (~60 Hz) drives the game loop and
  simulation ticks
* **PRG format**: standard 2-byte load-address header; BASIC `SYS 2061`
  stub auto-starts the machine code
* **Memory usage**: zero page `$02–$48`, code + data from `$0801`,
  BSS (city map, 800 bytes) allocated after code
