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
    .byte 32        ; TILE_EMPTY    space
    .byte 64        ; TILE_ROAD     fallback horizontal line
    .byte  8        ; TILE_HOUSE    'H'
    .byte  6        ; TILE_FACTORY  'F'
    .byte 16        ; TILE_PARK     'P'
    .byte  5        ; TILE_POWER    'E' (Electricity)
    .byte 12        ; TILE_POLICE   'L' (Law)
    .byte 19        ; TILE_FIRE     'S' (Station)
    .byte 42        ; TILE_WATER    '*'
    .byte 20        ; TILE_TREE     'T'

; ------------------------------------------------------------
; Road shape → screen character (C64 screen codes).
; Index bits are NSEW = 1,2,4,8 and the glyphs come from the
; PETSCII line-drawing set:
;   64='-'  91='+'  93='|'  107='├'  109='└'  110='┐'
;   112='┌' 113='┴' 114='┬' 115='┤' 125='┘'
; ------------------------------------------------------------
road_shape_char:
    .byte 64        ; 0000 isolated road -> horizontal stub
    .byte 93        ; 0001 N
    .byte 93        ; 0010 S
    .byte 93        ; 0011 N+S
    .byte 64        ; 0100 E
    .byte 109       ; 0101 N+E -> └
    .byte 112       ; 0110 S+E -> ┌
    .byte 107       ; 0111 N+S+E -> ├
    .byte 64        ; 1000 W
    .byte 125       ; 1001 N+W -> ┘
    .byte 110       ; 1010 S+W -> ┐
    .byte 115       ; 1011 N+S+W -> ┤
    .byte 64        ; 1100 E+W
    .byte 113       ; 1101 N+E+W -> ┴
    .byte 114       ; 1110 S+E+W -> ┬
    .byte 91        ; 1111 N+S+E+W -> ┼

; ------------------------------------------------------------
; Tile → foreground colour (0-15 palette)
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
    .byte COLOR_LTBLUE      ; TILE_WATER
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
    .byte 0                 ; TILE_WATER
    .byte 0                 ; TILE_TREE

; ------------------------------------------------------------
; Buildable tile colours by density level 1-4.
; ------------------------------------------------------------
density_color:
    .byte COLOR_DKGRAY, COLOR_MDGRAY, COLOR_LTGRAY,  COLOR_WHITE
    .byte COLOR_YELLOW, COLOR_ORANGE, COLOR_LTRED,   COLOR_WHITE
    .byte COLOR_BROWN,  COLOR_RED,    COLOR_LTRED,   COLOR_ORANGE
    .byte COLOR_LTGREEN, COLOR_CYAN,  COLOR_YELLOW,  COLOR_WHITE
    .byte COLOR_LTGRAY, COLOR_LTBLUE, COLOR_YELLOW,  COLOR_WHITE
    .byte COLOR_BLUE,   COLOR_LTBLUE, COLOR_CYAN,    COLOR_WHITE
    .byte COLOR_RED,    COLOR_LTRED,  COLOR_ORANGE,  COLOR_YELLOW

; ------------------------------------------------------------
; Building cost tables (16-bit, lo/hi split)
; Index 0 = TILE_EMPTY (no cost for demolish)
; Index 1-7 = buildable types
; Index 8-9 = water/tree  (not buildable → cost 0)
; ------------------------------------------------------------
bld_cost_lo:
    .byte 0,  COST_ROAD_LO,  COST_HOUSE_LO,  COST_FACTORY_LO
    .byte COST_PARK_LO, COST_POWER_LO, COST_POLICE_LO, COST_FIRE_LO
    .byte 0, 0

bld_cost_hi:
    .byte 0,  COST_ROAD_HI,  COST_HOUSE_HI,  COST_FACTORY_HI
    .byte COST_PARK_HI, COST_POWER_HI, COST_POLICE_HI, COST_FIRE_HI
    .byte 0, 0

; ------------------------------------------------------------
; Powers of 10 for decimal printing (index 0=10000 … 4=1)
; ------------------------------------------------------------
pow10_lo:
    .byte <10000, <1000, <100, <10, <1

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
str_title2:     .byte "A MODERN CITY BUILDER", $00
str_title3:     .byte "FOR THE COMMODORE 64", $00
str_title4:     .byte "PRESS ANY KEY TO START", $00
str_title_key:  .byte "CONTROLS:", $00
str_title_c1:   .byte "W/A/S/D OR ARROWS - MOVE", $00
str_title_c2:   .byte "1-7  - SELECT BUILDING", $00
str_title_c3:   .byte "RETURN/B  - BUILD OR UPGRADE", $00
str_title_c4:   .byte "X  - REDUCE OR DEMOLISH", $00
str_title_c5:   .byte "Q  - RETURN TO TITLE", $00

; ---- Stats row label prefixes (screen codes) ---------------
str_yr:         .byte "YR:", $00
str_cash:       .byte " $:", $00
str_pop:        .byte " POP:", $00
str_pwr:        .byte "PWR:", $00
str_hap:        .byte " HAP:", $00
str_crm:        .byte " CRM:", $00

; ---- Building menu (exactly 39 chars, fits 40-col screen) --
; Layout: 1:RD 2:HSE 3:FAC 4:PRK 5:PWR 6:POL 7:FIR
str_menu:
    .byte "1:RD 2:HSE 3:FAC 4:PRK 5:PWR 6:POL 7:FIR", $00

; ---- Mode labels -------------------------------------------
str_mode_build: .byte "MODE:BUILD ", $00
str_mode_demo:  .byte "MODE:DEMO  ", $00

; ---- Message strings ---------------------------------------
str_msg_placed:     .byte "BUILDING PLACED!         ", $00
str_msg_upgraded:   .byte "DENSITY UPGRADED.        ", $00
str_msg_maxdense:   .byte "ALREADY MAX DENSITY.     ", $00
str_msg_notenough:  .byte "NOT ENOUGH CASH!         ", $00
str_msg_demolished: .byte "DEMOLISHED.              ", $00
str_msg_downgraded: .byte "DENSITY REDUCED.         ", $00
str_msg_cantbuild:  .byte "CANNOT BUILD THERE.      ", $00
str_msg_bankrupt:   .byte "*** CITY IS BANKRUPT ***!", $00
str_msg_empty:      .byte "                         ", $00

; ---- Help row (up to 40 chars) -----------------------------
str_help:
    .byte "W/A/S/D:MOVE 1-7:SEL B/RET:+DEN X:-DEN", $00

; ============================================================
; Building name strings (for selection feedback in msg row)
; Pointed to by bld_names table below.
; ============================================================
bld_name_road:    .byte "ROAD       ($10)         ", $00
bld_name_house:   .byte "HOUSE      ($100)        ", $00
bld_name_factory: .byte "FACTORY    ($500)        ", $00
bld_name_park:    .byte "PARK       ($200)        ", $00
bld_name_power:   .byte "POWER PLT  ($1000)       ", $00
bld_name_police:  .byte "POLICE STN ($300)        ", $00
bld_name_fire:    .byte "FIRE STN   ($300)        ", $00

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
