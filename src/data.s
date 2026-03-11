; ============================================================
; C64 City Builder - Static Data Tables
; Included by main.s (last .include so charmap remapping is safe).
; ============================================================

    .segment "RODATA"

; ------------------------------------------------------------
; Row-to-screen-address lookup  (row * 40, rows 0-24)
; ------------------------------------------------------------
mul40_lo:
    .byte  <( 0*40), <( 1*40), <( 2*40), <( 3*40), <( 4*40)
    .byte  <( 5*40), <( 6*40), <( 7*40), <( 8*40), <( 9*40)
    .byte  <(10*40), <(11*40), <(12*40), <(13*40), <(14*40)
    .byte  <(15*40), <(16*40), <(17*40), <(18*40), <(19*40)
    .byte  <(20*40), <(21*40), <(22*40), <(23*40), <(24*40)

; Enter the mul40 hi routine.
mul40_hi:
    .byte  >(0*40),  >(1*40),  >(2*40),  >(3*40),  >(4*40)
    .byte  >(5*40),  >(6*40),  >(7*40),  >(8*40),  >(9*40)
    .byte  >(10*40), >(11*40), >(12*40), >(13*40), >(14*40)
    .byte  >(15*40), >(16*40), >(17*40), >(18*40), >(19*40)
    .byte  >(20*40), >(21*40), >(22*40), >(23*40), >(24*40)

; ------------------------------------------------------------
; Tile → screen character (C64 screen codes)
;   space = 32  |  A-Z = 1-26  |  '+' = 43  |  '*' = 42
; ------------------------------------------------------------
tile_char:
    .byte MAP_GLYPH_EMPTY    ; TILE_EMPTY
    .byte MAP_GLYPH_ROAD_BASE ; TILE_ROAD fallback horizontal line
    .byte MAP_GLYPH_HOUSE    ; TILE_HOUSE
    .byte MAP_GLYPH_FACTORY  ; TILE_FACTORY
    .byte MAP_GLYPH_PARK     ; TILE_PARK
    .byte MAP_GLYPH_POWER    ; TILE_POWER
    .byte MAP_GLYPH_POLICE   ; TILE_POLICE
    .byte MAP_GLYPH_FIRE     ; TILE_FIRE
    .byte MAP_GLYPH_ROAD_BASE ; TILE_BRIDGE
    .byte MAP_GLYPH_WATER    ; TILE_WATER
    .byte MAP_GLYPH_TREE     ; TILE_TREE

; ------------------------------------------------------------
; Road shape → custom multicolor road character.
; Index bits are NSEW = 1,2,4,8.
; ------------------------------------------------------------
road_shape_char:
    .byte MAP_GLYPH_ROAD_BASE + 0
    .byte MAP_GLYPH_ROAD_BASE + 1
    .byte MAP_GLYPH_ROAD_BASE + 2
    .byte MAP_GLYPH_ROAD_BASE + 3
    .byte MAP_GLYPH_ROAD_BASE + 4
    .byte MAP_GLYPH_ROAD_BASE + 5
    .byte MAP_GLYPH_ROAD_BASE + 6
    .byte MAP_GLYPH_ROAD_BASE + 7
    .byte MAP_GLYPH_ROAD_BASE + 8
    .byte MAP_GLYPH_ROAD_BASE + 9
    .byte MAP_GLYPH_ROAD_BASE + 10
    .byte MAP_GLYPH_ROAD_BASE + 11
    .byte MAP_GLYPH_ROAD_BASE + 12
    .byte MAP_GLYPH_ROAD_BASE + 13
    .byte MAP_GLYPH_ROAD_BASE + 14
    .byte MAP_GLYPH_ROAD_BASE + 15

; ------------------------------------------------------------
; Tile → AoE highlight colour (0-15 palette)
; ------------------------------------------------------------
tile_color:
    .byte COLOR_GREEN       ; TILE_EMPTY
    .byte COLOR_MDGRAY      ; TILE_ROAD
    .byte COLOR_YELLOW      ; TILE_HOUSE
    .byte COLOR_RED         ; TILE_FACTORY
    .byte COLOR_LTGREEN     ; TILE_PARK
    .byte COLOR_WHITE       ; TILE_POWER
    .byte COLOR_BLUE        ; TILE_POLICE
    .byte COLOR_LTRED       ; TILE_FIRE
    .byte COLOR_MDGRAY      ; TILE_BRIDGE
    .byte COLOR_BLUE        ; TILE_WATER
    .byte COLOR_GREEN       ; TILE_TREE

; ------------------------------------------------------------
; Base offset into density_color for each tile type.
; Buildable tiles use four-entry colour ramps; decorative tiles fall
; back to tile_color above.
; ------------------------------------------------------------
tile_density_base:
    .byte 0                 ; TILE_EMPTY
    .byte 0                 ; TILE_ROAD
    .byte 4                 ; TILE_HOUSE
    .byte 8                 ; TILE_FACTORY
    .byte 12                ; TILE_PARK
    .byte 16                ; TILE_POWER
    .byte 20                ; TILE_POLICE
    .byte 24                ; TILE_FIRE
    .byte 0                 ; TILE_BRIDGE
    .byte 0                 ; TILE_WATER
    .byte 0                 ; TILE_TREE

; ------------------------------------------------------------
; Buildable tile colours by density level 1-4.
; ------------------------------------------------------------
density_color:
    .byte COLOR_DKGRAY, COLOR_MDGRAY, COLOR_LTGRAY,  COLOR_WHITE
    .byte COLOR_LTGREEN, COLOR_LTGREEN, COLOR_LTGREEN, COLOR_LTGREEN
    .byte COLOR_LTGREEN, COLOR_LTGREEN, COLOR_LTGREEN, COLOR_LTGREEN
    .byte COLOR_LTGREEN, COLOR_LTGREEN, COLOR_LTGREEN, COLOR_LTGREEN
    .byte COLOR_LTGREEN, COLOR_LTGREEN, COLOR_LTGREEN, COLOR_LTGREEN
    .byte COLOR_LTGREEN, COLOR_LTGREEN, COLOR_LTGREEN, COLOR_LTGREEN
    .byte COLOR_LTGREEN, COLOR_LTGREEN, COLOR_LTGREEN, COLOR_LTGREEN

; ------------------------------------------------------------
; Tile → multicolor character colour (bit 3 enables multicolor).
; Only colours 0-7 are available per character in C64 multicolor
; text mode, so these ramps intentionally use the base palette.
; ------------------------------------------------------------
tile_mc_color:
    .byte MC_CHAR_FLAG + COLOR_GREEN      ; TILE_EMPTY
    .byte MC_CHAR_FLAG + COLOR_WHITE      ; TILE_ROAD
    .byte MC_CHAR_FLAG + COLOR_YELLOW     ; TILE_HOUSE
    .byte MC_CHAR_FLAG + COLOR_RED        ; TILE_FACTORY
    .byte MC_CHAR_FLAG + COLOR_GREEN      ; TILE_PARK
    .byte MC_CHAR_FLAG + COLOR_CYAN       ; TILE_POWER
    .byte MC_CHAR_FLAG + COLOR_BLUE       ; TILE_POLICE
    .byte MC_CHAR_FLAG + COLOR_RED        ; TILE_FIRE
    .byte MC_CHAR_FLAG + COLOR_WHITE      ; TILE_BRIDGE
    .byte MC_CHAR_FLAG + COLOR_BLUE       ; TILE_WATER
    .byte MC_CHAR_FLAG + COLOR_GREEN      ; TILE_TREE

; Enter the density mc color routine.
density_mc_color:
    .byte MC_CHAR_FLAG + COLOR_WHITE,  MC_CHAR_FLAG + COLOR_CYAN,   MC_CHAR_FLAG + COLOR_YELLOW, MC_CHAR_FLAG + COLOR_WHITE
    .byte MC_CHAR_FLAG + COLOR_YELLOW, MC_CHAR_FLAG + COLOR_RED,    MC_CHAR_FLAG + COLOR_CYAN,   MC_CHAR_FLAG + COLOR_WHITE
    .byte MC_CHAR_FLAG + COLOR_RED,    MC_CHAR_FLAG + COLOR_YELLOW, MC_CHAR_FLAG + COLOR_WHITE,  MC_CHAR_FLAG + COLOR_CYAN
    .byte MC_CHAR_FLAG + COLOR_GREEN,  MC_CHAR_FLAG + COLOR_CYAN,   MC_CHAR_FLAG + COLOR_YELLOW, MC_CHAR_FLAG + COLOR_WHITE
    .byte MC_CHAR_FLAG + COLOR_CYAN,   MC_CHAR_FLAG + COLOR_WHITE,  MC_CHAR_FLAG + COLOR_YELLOW, MC_CHAR_FLAG + COLOR_RED
    .byte MC_CHAR_FLAG + COLOR_BLUE,   MC_CHAR_FLAG + COLOR_CYAN,   MC_CHAR_FLAG + COLOR_WHITE,  MC_CHAR_FLAG + COLOR_YELLOW
    .byte MC_CHAR_FLAG + COLOR_RED,    MC_CHAR_FLAG + COLOR_YELLOW, MC_CHAR_FLAG + COLOR_WHITE,  MC_CHAR_FLAG + COLOR_CYAN

; ------------------------------------------------------------
; Level-based AoE radii (index 0 unused, levels 1-4).
; ------------------------------------------------------------
house_aoe_radius:
    .byte 0, 2, 4, 7, 11

; Enter the factory aoe radius routine.
factory_aoe_radius:
    .byte 0, 3, 6, 10, 15

; ------------------------------------------------------------
; Building cost tables (16-bit, lo/hi split)
; Index 0 = TILE_EMPTY (no cost for demolish)
; Index 1-8 = buildable / placeable types
; Index 9-10 = water/tree  (not buildable → cost 0)
; ------------------------------------------------------------
bld_cost_lo:
    .byte 0,  COST_ROAD_LO,  COST_HOUSE_LO,  COST_FACTORY_LO
    .byte COST_PARK_LO, COST_POWER_LO, COST_POLICE_LO, COST_FIRE_LO
    .byte COST_BRIDGE_LO, 0, 0

; Enter the cost hi routine.
bld_cost_hi:
    .byte 0,  COST_ROAD_HI,  COST_HOUSE_HI,  COST_FACTORY_HI
    .byte COST_PARK_HI, COST_POWER_HI, COST_POLICE_HI, COST_FIRE_HI
    .byte COST_BRIDGE_HI, 0, 0

; ------------------------------------------------------------
; Powers of 10 for decimal printing (index 0=10000 … 4=1)
; ------------------------------------------------------------
pow10_lo:
    .byte <10000, <1000, <100, <10, <1

; Enter the pow10 hi routine.
pow10_hi:
    .byte >10000, >1000, >100, >10, >1

; ------------------------------------------------------------
; Sprite 0 data: hollow box centred over one text cell.
; 21 rows * 3 bytes + 1 padding byte = 64-byte sprite block.
; ------------------------------------------------------------
cursor_sprite_data:
    .repeat 6
        .byte $00, $00, $00
    .endrepeat
    .byte $01, $FF, $80
    .repeat 8
        .byte $01, $00, $80
    .endrepeat
    .byte $01, $FF, $80
    .repeat 5
        .byte $00, $00, $00
    .endrepeat
    .byte $00

; ------------------------------------------------------------
; Custom glyphs written into CHARSET_RAM at screen codes
; 96-159: multicolor map tiles (normal + AoE-highlight variants)
; plus the HUD icons for the first two status rows and build menu.
; ------------------------------------------------------------
MC_BG0 = 0
MC_BG1 = 1
MC_ACC = 2
MC_FG  = 3

.macro MCROW P0, P1, P2, P3
    .byte ((P0 << 6) | (P1 << 4) | (P2 << 2) | P3)
.endmacro

.macro GLYPH_EMPTY BG
    .repeat 8
        MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
    .endrepeat
.endmacro

.macro ROAD_HORIZ BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
    MCROW MC_FG, MC_FG, MC_FG, MC_FG ; execute MCROW MC_FG, MC_FG, MC_FG, MC_FG
    MCROW MC_FG, MC_FG, MC_FG, MC_FG ; execute MCROW MC_FG, MC_FG, MC_FG, MC_FG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
.endmacro

.macro ROAD_VERT BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
.endmacro

.macro ROAD_NE BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, MC_FG ; execute MCROW BG, MC_FG, MC_FG, MC_FG
    MCROW BG, MC_FG, MC_FG, MC_FG ; execute MCROW BG, MC_FG, MC_FG, MC_FG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
.endmacro

.macro ROAD_SE BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
    MCROW BG, MC_FG, MC_FG, MC_FG ; execute MCROW BG, MC_FG, MC_FG, MC_FG
    MCROW BG, MC_FG, MC_FG, MC_FG ; execute MCROW BG, MC_FG, MC_FG, MC_FG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
.endmacro

.macro ROAD_NW BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW MC_FG, MC_FG, MC_FG, BG ; execute MCROW MC_FG, MC_FG, MC_FG, BG
    MCROW MC_FG, MC_FG, MC_FG, BG ; execute MCROW MC_FG, MC_FG, MC_FG, BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
.endmacro

.macro ROAD_SW BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
    MCROW MC_FG, MC_FG, MC_FG, BG ; execute MCROW MC_FG, MC_FG, MC_FG, BG
    MCROW MC_FG, MC_FG, MC_FG, BG ; execute MCROW MC_FG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
.endmacro

.macro ROAD_T_E BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, MC_FG ; execute MCROW BG, MC_FG, MC_FG, MC_FG
    MCROW BG, MC_FG, MC_FG, MC_FG ; execute MCROW BG, MC_FG, MC_FG, MC_FG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
.endmacro

.macro ROAD_T_W BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW MC_FG, MC_FG, MC_FG, BG ; execute MCROW MC_FG, MC_FG, MC_FG, BG
    MCROW MC_FG, MC_FG, MC_FG, BG ; execute MCROW MC_FG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
.endmacro

.macro ROAD_T_N BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW MC_FG, MC_FG, MC_FG, MC_FG ; execute MCROW MC_FG, MC_FG, MC_FG, MC_FG
    MCROW MC_FG, MC_FG, MC_FG, MC_FG ; execute MCROW MC_FG, MC_FG, MC_FG, MC_FG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
.endmacro

.macro ROAD_T_S BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
    MCROW MC_FG, MC_FG, MC_FG, MC_FG ; execute MCROW MC_FG, MC_FG, MC_FG, MC_FG
    MCROW MC_FG, MC_FG, MC_FG, MC_FG ; execute MCROW MC_FG, MC_FG, MC_FG, MC_FG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
.endmacro

.macro ROAD_CROSS BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW MC_FG, MC_FG, MC_FG, MC_FG ; execute MCROW MC_FG, MC_FG, MC_FG, MC_FG
    MCROW MC_FG, MC_FG, MC_FG, MC_FG ; execute MCROW MC_FG, MC_FG, MC_FG, MC_FG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
.endmacro

.macro GLYPH_HOUSE BG
    MCROW BG, BG, MC_ACC, BG ; execute MCROW BG, BG, MC_ACC, BG
    MCROW BG, MC_ACC, MC_ACC, BG ; execute MCROW BG, MC_ACC, MC_ACC, BG
    MCROW MC_ACC, MC_ACC, MC_ACC, MC_ACC ; execute MCROW MC_ACC, MC_ACC, MC_ACC, MC_ACC
    MCROW MC_FG, MC_FG, MC_FG, MC_FG ; execute MCROW MC_FG, MC_FG, MC_FG, MC_FG
    MCROW MC_FG, MC_ACC, BG, MC_FG ; execute MCROW MC_FG, MC_ACC, BG, MC_FG
    MCROW MC_FG, BG, BG, MC_FG ; execute MCROW MC_FG, BG, BG, MC_FG
    MCROW MC_FG, BG, BG, MC_FG ; execute MCROW MC_FG, BG, BG, MC_FG
    MCROW MC_FG, MC_FG, MC_FG, MC_FG ; execute MCROW MC_FG, MC_FG, MC_FG, MC_FG
.endmacro

.macro GLYPH_FACTORY BG
    MCROW BG, MC_FG, BG, BG ; execute MCROW BG, MC_FG, BG, BG
    MCROW BG, MC_FG, MC_ACC, BG ; execute MCROW BG, MC_FG, MC_ACC, BG
    MCROW MC_FG, MC_FG, MC_FG, BG ; execute MCROW MC_FG, MC_FG, MC_FG, BG
    MCROW MC_FG, MC_ACC, MC_FG, MC_FG ; execute MCROW MC_FG, MC_ACC, MC_FG, MC_FG
    MCROW MC_FG, MC_FG, MC_FG, MC_FG ; execute MCROW MC_FG, MC_FG, MC_FG, MC_FG
    MCROW MC_FG, MC_ACC, MC_ACC, MC_FG ; execute MCROW MC_FG, MC_ACC, MC_ACC, MC_FG
    MCROW MC_FG, MC_ACC, BG, MC_FG ; execute MCROW MC_FG, MC_ACC, BG, MC_FG
    MCROW MC_FG, MC_FG, MC_FG, MC_FG ; execute MCROW MC_FG, MC_FG, MC_FG, MC_FG
.endmacro

.macro GLYPH_PARK BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
    MCROW BG, MC_FG, BG, MC_FG ; execute MCROW BG, MC_FG, BG, MC_FG
    MCROW MC_FG, MC_FG, MC_FG, MC_FG ; execute MCROW MC_FG, MC_FG, MC_FG, MC_FG
    MCROW BG, MC_ACC, MC_FG, BG ; execute MCROW BG, MC_ACC, MC_FG, BG
    MCROW MC_FG, MC_FG, MC_FG, MC_FG ; execute MCROW MC_FG, MC_FG, MC_FG, MC_FG
    MCROW BG, MC_FG, BG, MC_FG ; execute MCROW BG, MC_FG, BG, MC_FG
    MCROW BG, MC_ACC, MC_ACC, BG ; execute MCROW BG, MC_ACC, MC_ACC, BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
.endmacro

.macro GLYPH_POWER BG
    MCROW BG, BG, MC_FG, BG ; execute MCROW BG, BG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, BG, BG ; execute MCROW BG, MC_FG, BG, BG
    MCROW MC_FG, MC_FG, MC_FG, BG ; execute MCROW MC_FG, MC_FG, MC_FG, BG
    MCROW BG, BG, MC_FG, BG ; execute MCROW BG, BG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_FG, BG, BG ; execute MCROW BG, MC_FG, BG, BG
    MCROW MC_FG, BG, BG, BG ; execute MCROW MC_FG, BG, BG, BG
.endmacro

.macro GLYPH_POLICE BG
    MCROW BG, MC_ACC, MC_ACC, BG ; execute MCROW BG, MC_ACC, MC_ACC, BG
    MCROW MC_ACC, MC_FG, MC_FG, MC_ACC ; execute MCROW MC_ACC, MC_FG, MC_FG, MC_ACC
    MCROW MC_FG, MC_FG, MC_FG, MC_FG ; execute MCROW MC_FG, MC_FG, MC_FG, MC_FG
    MCROW MC_FG, MC_ACC, MC_ACC, MC_FG ; execute MCROW MC_FG, MC_ACC, MC_ACC, MC_FG
    MCROW MC_FG, MC_ACC, MC_ACC, MC_FG ; execute MCROW MC_FG, MC_ACC, MC_ACC, MC_FG
    MCROW MC_FG, MC_FG, MC_FG, MC_FG ; execute MCROW MC_FG, MC_FG, MC_FG, MC_FG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, BG, MC_FG, BG ; execute MCROW BG, BG, MC_FG, BG
.endmacro

.macro GLYPH_FIRE BG
    MCROW BG, BG, MC_FG, BG ; execute MCROW BG, BG, MC_FG, BG
    MCROW BG, MC_FG, MC_ACC, BG ; execute MCROW BG, MC_FG, MC_ACC, BG
    MCROW BG, MC_ACC, MC_FG, BG ; execute MCROW BG, MC_ACC, MC_FG, BG
    MCROW MC_ACC, MC_FG, MC_FG, MC_ACC ; execute MCROW MC_ACC, MC_FG, MC_FG, MC_ACC
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW BG, MC_ACC, MC_FG, BG ; execute MCROW BG, MC_ACC, MC_FG, BG
    MCROW BG, BG, MC_FG, BG ; execute MCROW BG, BG, MC_FG, BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
.endmacro

.macro GLYPH_WATER BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW MC_FG, BG, BG, MC_FG ; execute MCROW MC_FG, BG, BG, MC_FG
    MCROW MC_FG, MC_FG, BG, BG ; execute MCROW MC_FG, MC_FG, BG, BG
    MCROW BG, BG, MC_FG, MC_FG ; execute MCROW BG, BG, MC_FG, MC_FG
    MCROW BG, MC_FG, MC_FG, BG ; execute MCROW BG, MC_FG, MC_FG, BG
    MCROW MC_FG, BG, BG, MC_FG ; execute MCROW MC_FG, BG, BG, MC_FG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
.endmacro

.macro GLYPH_TREE BG
    MCROW BG, BG, MC_FG, BG ; execute MCROW BG, BG, MC_FG, BG
    MCROW BG, MC_FG, MC_FG, MC_FG ; execute MCROW BG, MC_FG, MC_FG, MC_FG
    MCROW BG, MC_ACC, MC_FG, BG ; execute MCROW BG, MC_ACC, MC_FG, BG
    MCROW MC_FG, MC_FG, MC_FG, MC_FG ; execute MCROW MC_FG, MC_FG, MC_FG, MC_FG
    MCROW BG, BG, MC_FG, BG ; execute MCROW BG, BG, MC_FG, BG
    MCROW BG, BG, MC_FG, BG ; execute MCROW BG, BG, MC_FG, BG
    MCROW BG, MC_ACC, MC_ACC, BG ; execute MCROW BG, MC_ACC, MC_ACC, BG
    MCROW BG, BG, BG, BG ; execute MCROW BG, BG, BG, BG
.endmacro

; Enter the custom glyph char glyphs routine.
custom_char_glyphs:
    GLYPH_EMPTY MC_BG0
    GLYPH_EMPTY MC_BG1

    ROAD_HORIZ MC_BG0
    ROAD_VERT  MC_BG0
    ROAD_VERT  MC_BG0
    ROAD_VERT  MC_BG0
    ROAD_HORIZ MC_BG0
    ROAD_NE    MC_BG0
    ROAD_SE    MC_BG0
    ROAD_T_E   MC_BG0
    ROAD_HORIZ MC_BG0
    ROAD_NW    MC_BG0
    ROAD_SW    MC_BG0
    ROAD_T_W   MC_BG0
    ROAD_HORIZ MC_BG0
    ROAD_T_N   MC_BG0
    ROAD_T_S   MC_BG0
    ROAD_CROSS MC_BG0

    ROAD_HORIZ MC_BG1
    ROAD_VERT  MC_BG1
    ROAD_VERT  MC_BG1
    ROAD_VERT  MC_BG1
    ROAD_HORIZ MC_BG1
    ROAD_NE    MC_BG1
    ROAD_SE    MC_BG1
    ROAD_T_E   MC_BG1
    ROAD_HORIZ MC_BG1
    ROAD_NW    MC_BG1
    ROAD_SW    MC_BG1
    ROAD_T_W   MC_BG1
    ROAD_HORIZ MC_BG1
    ROAD_T_N   MC_BG1
    ROAD_T_S   MC_BG1
    ROAD_CROSS MC_BG1

    GLYPH_HOUSE   MC_BG0
    GLYPH_HOUSE   MC_BG1
    GLYPH_FACTORY MC_BG0
    GLYPH_FACTORY MC_BG1
    GLYPH_PARK    MC_BG0
    GLYPH_PARK    MC_BG1
    GLYPH_POWER   MC_BG0
    GLYPH_POWER   MC_BG1
    GLYPH_POLICE  MC_BG0
    GLYPH_POLICE  MC_BG1
    GLYPH_FIRE    MC_BG0
    GLYPH_FIRE    MC_BG1
    GLYPH_WATER   MC_BG0
    GLYPH_WATER   MC_BG1
    GLYPH_TREE    MC_BG0
    GLYPH_TREE    MC_BG1

    .byte %00011000
    .byte %00111100
    .byte %00011000
    .byte %00011000
    .byte %00111100
    .byte %00011000
    .byte %00110000
    .byte %01100000

    .byte %00000000
    .byte %00111100
    .byte %01111110
    .byte %01011010
    .byte %01011010
    .byte %01111110
    .byte %00111100
    .byte %00000000

    .byte %00000000
    .byte %01100110
    .byte %11111111
    .byte %11111111
    .byte %11111111
    .byte %01111110
    .byte %00111100
    .byte %00011000

    .byte %00000000
    .byte %00111100
    .byte %01100110
    .byte %11000011
    .byte %11011011
    .byte %01100110
    .byte %00111100
    .byte %00000000

    .byte %00011000
    .byte %00111100
    .byte %01100110
    .byte %01100110
    .byte %00111100
    .byte %00011000
    .byte %00011000
    .byte %00111100

    .byte %00011000
    .byte %00111100
    .byte %01111110
    .byte %11011011
    .byte %11011011
    .byte %01111110
    .byte %00111100
    .byte %00011000

    .byte %00011000
    .byte %00111100
    .byte %01111110
    .byte %11011011
    .byte %11011011
    .byte %01111110
    .byte %00111100
    .byte %01100110

    .byte %00000000
    .byte %00011000
    .byte %00011000
    .byte %11111111
    .byte %11111111
    .byte %00011000
    .byte %00011000
    .byte %00000000

    .byte %00011000
    .byte %00111100
    .byte %01111110
    .byte %11111111
    .byte %11011011
    .byte %11000011
    .byte %11000011
    .byte %11111111

    .byte %00000110
    .byte %00001110
    .byte %00011110
    .byte %00111110
    .byte %01111110
    .byte %01100110
    .byte %01100110
    .byte %01111110

    .byte %00011000
    .byte %00111100
    .byte %01111110
    .byte %00011000
    .byte %00111100
    .byte %01111110
    .byte %00011000
    .byte %00000000

    .byte %00011000
    .byte %00111100
    .byte %00011000
    .byte %00111100
    .byte %01111110
    .byte %00011000
    .byte %00111100
    .byte %00011000

    .byte %00011000
    .byte %00111100
    .byte %01111110
    .byte %11111111
    .byte %11111111
    .byte %01111110
    .byte %00111100
    .byte %00011000

    .byte %00011000
    .byte %00111100
    .byte %01100110
    .byte %00111100
    .byte %00011000
    .byte %00111100
    .byte %00011000
    .byte %00000000

; ============================================================
; Screen-code strings  (null-terminated, $00 = end-of-string)
;
; C64 screen codes:
;   '@'=0   A-Z=1-26   space=32   '!'-'?'=33-63
;   '0'-'9'=48-57   ':'=58
;
; We remap uppercase A-Z using .charmap so that .byte "TEXT"
; automatically emits screen codes.
; (data.s is the last .include so remapping is isolated here.)
; ============================================================

; Remap A-Z to screen codes 1-26
.repeat 26, I
    .charmap 'A' + I, I + 1
.endrepeat

; ---- Title screen strings ----------------------------------
str_title1:     .byte "C64 CITY BUILDER", $00
; Store the title2 UI string.
str_title2:     .byte "A MODERN CITY BUILDER", $00
; Store the title3 UI string.
str_title3:     .byte "FOR THE COMMODORE 64", $00
; Store the title4 UI string.
str_title4:     .byte "PRESS ANY KEY TO START", $00
; Store the title key UI string.
str_title_key:  .byte "CONTROLS:", $00
; Store the title c1 UI string.
str_title_c1:   .byte "W/A/S/D OR ARROWS - MOVE", $00
; Store the title c2 UI string.
str_title_c2:   .byte "1-7  - SELECT BUILDING", $00
; Store the title c3 UI string.
str_title_c3:   .byte "RETURN/B  - BUILD OR UPGRADE", $00
; Store the title c4 UI string.
str_title_c4:   .byte "X  - REDUCE OR DEMOLISH", $00
; Store the title c5 UI string.
str_title_c5:   .byte "Q  - RETURN TO TITLE", $00

; ---- Stats row label prefixes (screen codes) ---------------
str_yr:         .byte HUD_GLYPH_YEAR, $00
; Store the cash UI string.
str_cash:       .byte HUD_GLYPH_CASH, $00
; Store the pop UI string.
str_pop:        .byte HUD_GLYPH_POP, $00
; Store the pwr UI string.
str_pwr:        .byte HUD_GLYPH_POWER, $00
; Store the job UI string.
str_job:        .byte HUD_GLYPH_JOBS, $00
; Store the hap UI string.
str_hap:        .byte HUD_GLYPH_HAPPY, $00
; Store the crm UI string.
str_crm:        .byte HUD_GLYPH_CRIME, $00

; ---- Building menu (exactly 39 chars, fits 40-col screen) --
; Layout: 1:RD 2:HSE 3:FAC 4:PRK 5:PWR 6:POL 7:FIR
str_menu:
    .byte "1:", MAP_GLYPH_ROAD_BASE, "  2:", MAP_GLYPH_HOUSE, "   3:", MAP_GLYPH_FACTORY, "   4:", MAP_GLYPH_PARK, "   5:", MAP_GLYPH_POWER, "   6:", MAP_GLYPH_POLICE, "   7:", MAP_GLYPH_FIRE, "  ", $00

; ---- Mode labels -------------------------------------------
str_mode_build: .byte "MODE:BUILD ", $00
; Store the mode demolition UI string.
str_mode_demo:  .byte "MODE:DEMO  ", $00
; Store the needs hdr UI string.
str_needs_hdr:  .byte "NEEDS:", $00
; Store the need ok UI string.
str_need_ok:    .byte "OK", $00
; Store the need pwr UI string.
str_need_pwr:   .byte "PWR", $00
; Store the need job UI string.
str_need_job:   .byte "JOB", $00
; Store the need hse UI string.
str_need_hse:   .byte "HSE", $00
; Store the need prk UI string.
str_need_prk:   .byte "PRK", $00
; Store the need saf UI string.
str_need_saf:   .byte "SAF", $00
; Store the na UI string.
str_lvl_na:     .byte "L-", $00
; Store the 1 UI string.
str_lvl_1:      .byte "L1", $00
; Store the 2 UI string.
str_lvl_2:      .byte "L2", $00
; Store the 3 UI string.
str_lvl_3:      .byte "L3", $00
; Store the 4 UI string.
str_lvl_4:      .byte "L4", $00

; ---- Message strings ---------------------------------------
str_msg_placed:     .byte "BUILDING PLACED!         ", $00
; Store the upgraded UI string.
str_msg_upgraded:   .byte "DENSITY UPGRADED.        ", $00
; Store the maxdense UI string.
str_msg_maxdense:   .byte "ALREADY MAX DENSITY.     ", $00
; Store the notenough UI string.
str_msg_notenough:  .byte "NOT ENOUGH CASH!         ", $00
; Store the demolished UI string.
str_msg_demolished: .byte "DEMOLISHED.              ", $00
; Store the downgraded UI string.
str_msg_downgraded: .byte "DENSITY REDUCED.         ", $00
; Store the cantbuild UI string.
str_msg_cantbuild:  .byte "CANNOT BUILD THERE.      ", $00
; Store the bankrupt UI string.
str_msg_bankrupt:   .byte "*** CITY IS BANKRUPT ***!", $00
; Enter the message empty routine.
str_msg_empty:
    .repeat 29
        .byte 32
    .endrepeat
    .byte $00

; ---- Help row (up to 40 chars) -----------------------------
str_help:
    .byte "W/A/S/D:MOVE 1-7:SEL B/RET:+DEN X:-DEN", $00

; ============================================================
; Building name strings (for selection feedback in msg row)
; Pointed to by bld_names table below.
; ============================================================
bld_name_road:    .byte "ROAD       ($10)         ", $00
; Store table data for name house.
bld_name_house:   .byte "HOUSE      ($100)        ", $00
; Store table data for name factory.
bld_name_factory: .byte "FACTORY    ($500)        ", $00
; Store table data for name park.
bld_name_park:    .byte "PARK       ($200)        ", $00
; Store table data for name power.
bld_name_power:   .byte "POWER PLT  ($1000)       ", $00
; Store table data for name police.
bld_name_police:  .byte "POLICE STN ($300)        ", $00
; Store table data for name fire.
bld_name_fire:    .byte "FIRE STN   ($300)        ", $00

; Store table data for tile land.
hud_tile_land:    .byte "LAND", $00
; Store table data for tile road.
hud_tile_road:    .byte "ROAD", $00
; Store table data for tile home.
hud_tile_home:    .byte "HOME", $00
; Store table data for tile fact.
hud_tile_fact:    .byte "FACT", $00
; Store table data for tile park.
hud_tile_park:    .byte "PARK", $00
; Store table data for tile pwr.
hud_tile_pwr:     .byte "POWR", $00
; Store table data for tile pol.
hud_tile_pol:     .byte "POLC", $00
; Store table data for tile fire.
hud_tile_fire:    .byte "FIRE", $00
; Store table data for tile brdg.
hud_tile_brdg:    .byte "BRDG", $00
; Store table data for tile watr.
hud_tile_watr:    .byte "WATR", $00
; Store table data for tile tree.
hud_tile_tree:    .byte "TREE", $00

; Store the 0 UI string.
str_seg_0:        .byte "S0", $00
; Store the 1 UI string.
str_seg_1:        .byte "S1", $00
; Store the 2 UI string.
str_seg_2:        .byte "S2", $00
; Store the 3 UI string.
str_seg_3:        .byte "S3", $00
; Store the 4 UI string.
str_seg_4:        .byte "S4", $00
; Store the 5 UI string.
str_seg_5:        .byte "S5", $00
; Store the 6 UI string.
str_seg_6:        .byte "S6", $00
; Store the 7 UI string.
str_seg_7:        .byte "S7", $00
; Store the 8 UI string.
str_seg_8:        .byte "S8", $00
; Store the 9 UI string.
str_seg_9:        .byte "S9", $00
; Store the a UI string.
str_seg_a:        .byte "SA", $00
; Store the b UI string.
str_seg_b:        .byte "SB", $00
; Store the c UI string.
str_seg_c:        .byte "SC", $00
; Store the d UI string.
str_seg_d:        .byte "SD", $00
; Store the e UI string.
str_seg_e:        .byte "SE", $00
; Store the f UI string.
str_seg_f:        .byte "SF", $00

; ---- Reset A-Z back to ASCII (65-90) for safety ------------
.repeat 26, I
    .charmap 'A' + I, 'A' + I
.endrepeat

; ============================================================
; bld_names: table of word-pointers to building name strings
; Index 0 = entry for building type 1 (Road), etc.
; ============================================================
bld_names:
    .word bld_name_road
    .word bld_name_house
    .word bld_name_factory
    .word bld_name_park
    .word bld_name_power
    .word bld_name_police
    .word bld_name_fire

; Enter the tile names routine.
hud_tile_names:
    .word hud_tile_land
    .word hud_tile_road
    .word hud_tile_home
    .word hud_tile_fact
    .word hud_tile_park
    .word hud_tile_pwr
    .word hud_tile_pol
    .word hud_tile_fire
    .word hud_tile_brdg
    .word hud_tile_watr
    .word hud_tile_tree

; Enter the segment names routine.
hud_segment_names:
    .word str_seg_0
    .word str_seg_1
    .word str_seg_2
    .word str_seg_3
    .word str_seg_4
    .word str_seg_5
    .word str_seg_6
    .word str_seg_7
    .word str_seg_8
    .word str_seg_9
    .word str_seg_a
    .word str_seg_b
    .word str_seg_c
    .word str_seg_d
    .word str_seg_e
    .word str_seg_f

; Enter the level names routine.
hud_level_names:
    .word str_lvl_1
    .word str_lvl_2
    .word str_lvl_3
    .word str_lvl_4
