# ==============================================================
# C64 City Builder - Makefile
# Requires the cc65 suite: ca65 assembler + ld65 linker
#   Ubuntu/Debian: sudo apt-get install cc65
#   macOS Homebrew: brew install cc65
# ==============================================================

TARGET  = citybuilder.prg

CA65    = ca65
LD65    = ld65
CONFIG  = linker.cfg

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
.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJ) $(CONFIG)
	$(LD65) -C $(CONFIG) -o $@ $(OBJ)
	@echo "Built: $@"

$(OBJ): $(MAIN_SRC) $(DEPS)
	$(CA65) $(CA65FLAGS) -o $@ $<

clean:
	rm -f $(OBJ) $(TARGET)
