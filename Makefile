# ==============================================================
# C64 City Builder - Makefile
# Requires the cc65 suite: ca65 assembler + ld65 linker
#   Ubuntu/Debian: sudo apt-get install cc65
#   macOS Homebrew: brew install cc65
# ==============================================================

TARGET  = citybuilder.prg
D64     = citybuilder.d64

CA65    = ca65
LD65    = ld65
CONFIG  = linker.cfg
C1541   = c1541
X64SC   = x64sc

# All source files (main.s .includes the rest)
MAIN_SRC = src/main.s
DEPS     = src/constants.s  \
           src/zeropage.s   \
           src/init.s       \
           src/title.s      \
           src/input.s      \
           src/map.s        \
           src/buildings.s  \
           src/simulation.s \
           src/ui.s         \
           src/data.s

OBJ = src/main.o

CA65FLAGS = --cpu 6502 -I src

# ---------------------------------------------------------------
.PHONY: all d64 run-d64 reload-d64 clean

all: $(TARGET)
	@echo "Built: $<"

$(TARGET): $(OBJ) $(CONFIG)
	$(LD65) -C $(CONFIG) -o $@ $(OBJ)
	@echo "Built: $@"

d64: $(D64)
	@echo "Built: $@"

$(D64): $(TARGET)
	$(C1541) -format C64BUILDER,01 d64 $@ \
		-write $(TARGET) CITYBUILDER

$(OBJ): $(MAIN_SRC) $(DEPS)
	$(CA65) $(CA65FLAGS) -o $@ $<

run-d64: $(D64)
	$(X64SC) -autostart $<

reload-d64: $(D64)
	pwsh -NoProfile -File scripts/vice-monitor-run-d64.ps1 -ImagePath $<

clean:
	rm -f $(OBJ) $(TARGET) $(D64)
