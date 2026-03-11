; ============================================================
; C64 City Builder - Hardware Constants and Game Definitions
; Included by main.s (single-unit build via .include)
; ============================================================

; ------------------------------------------------------------
; Commodore 64  VIC-II registers ($D000-$D3FF)
; ------------------------------------------------------------
VIC_SPR0_X      = $D000     ; Sprite 0 X position (low 8 bits)
VIC_SPR0_Y      = $D001     ; Sprite 0 Y position
VIC_SPR_X_MSB   = $D010     ; Sprite X high-bit register
VIC_SPRITE_EN   = $D015     ; Sprite enable
VIC_SPR_EXP_Y   = $D017     ; Sprite Y expansion
VIC_CTRL1       = $D011     ; Control register 1 (screen on/off, raster)
VIC_RASTER      = $D012     ; Raster compare
VIC_CTRL2       = $D016     ; Control register 2 (multicolor etc.)
VIC_VMEM_CTRL   = $D018     ; Video memory control (screen/char base)
VIC_IRQ_STATUS  = $D019     ; Interrupt status
VIC_IRQ_CTRL    = $D01A     ; Interrupt control
VIC_SPR_BG_PRIO = $D01B     ; Sprite priority against background
VIC_SPR_MC      = $D01C     ; Sprite multicolor enable
VIC_SPR_EXP_X   = $D01D     ; Sprite X expansion
VIC_BORDER_CLR  = $D020     ; Border color
VIC_BKG_CLR0    = $D021     ; Background color 0
VIC_BKG_CLR1    = $D022     ; Background color 1
VIC_BKG_CLR2    = $D023     ; Background color 2 / shared multicolor 2
VIC_SPR0_COLOR  = $D027     ; Sprite 0 color

; ------------------------------------------------------------
; CIA #1 registers - keyboard & joystick ($DC00-$DCFF)
; ------------------------------------------------------------
CIA1_PRA        = $DC00     ; Port A: keyboard column select
CIA1_PRB        = $DC01     ; Port B: keyboard row read
CIA1_DDRA       = $DC02     ; Port A direction register
CIA1_DDRB       = $DC03     ; Port B direction register
CIA2_PRA        = $DD00     ; Port A: VIC bank select (bits 0-1)

; ------------------------------------------------------------
; 6510 processor port
; ------------------------------------------------------------
CPU_PORT        = $01       ; Memory configuration / CHAREN control
IRQ_VECTOR_LO   = $0314     ; IRQ vector low byte
IRQ_VECTOR_HI   = $0315     ; IRQ vector high byte

; ------------------------------------------------------------
; C64 Memory map
; ------------------------------------------------------------
COLOR_BASE      = $D800     ; Color RAM (mirrors screen layout)
SCREEN_SIZE     = 1000      ; 40×25 characters
VIC_BANK_BASE   = $4000     ; VIC bank 1 keeps display assets away from program/BSS
SCREEN_BASE     = $6800     ; Screen RAM inside VIC bank 1, above program/BSS
CHARSET_RAM     = $7000     ; RAM copy of the lowercase/uppercase charset
CHARSET_ROM     = $D800     ; Lowercase/uppercase character ROM page
SPRITE0_DATA    = $6C00     ; Sprite data inside VIC bank 1, above screen RAM
SPRITE0_PTR     = (SPRITE0_DATA - VIC_BANK_BASE) / 64
SPRITE0_PTR_LOC = SCREEN_BASE + $03F8
MAP_GLYPH_EMPTY   = 96
MAP_GLYPH_EMPTY_HL = 97
MAP_GLYPH_ROAD_BASE = 98
MAP_GLYPH_ROAD_HL_BASE = 114
MAP_GLYPH_HOUSE   = 130
MAP_GLYPH_HOUSE_HL = 131
MAP_GLYPH_FACTORY = 132
MAP_GLYPH_FACTORY_HL = 133
MAP_GLYPH_PARK    = 134
MAP_GLYPH_PARK_HL = 135
MAP_GLYPH_POWER   = 136
MAP_GLYPH_POWER_HL = 137
MAP_GLYPH_POLICE  = 138
MAP_GLYPH_POLICE_HL = 139
MAP_GLYPH_FIRE    = 140
MAP_GLYPH_FIRE_HL = 141
MAP_GLYPH_WATER   = 142
MAP_GLYPH_WATER_HL = 143
MAP_GLYPH_TREE    = 144
MAP_GLYPH_TREE_HL = 145
HUD_GLYPH_POWER   = 146
HUD_GLYPH_JOBS    = 147
HUD_GLYPH_HAPPY   = 148
HUD_GLYPH_CRIME   = 149
HUD_GLYPH_YEAR    = 150
HUD_GLYPH_CASH    = 151
HUD_GLYPH_POP     = 152
MENU_GLYPH_ROAD   = 153
MENU_GLYPH_HOUSE  = 154
MENU_GLYPH_FACTORY = 155
MENU_GLYPH_PARK   = 156
MENU_GLYPH_POWER  = 157
MENU_GLYPH_POLICE = 158
MENU_GLYPH_FIRE   = 159
MC_CHAR_FLAG      = $08

; ------------------------------------------------------------
; KERNAL system variables (zero page / RAM)
; ------------------------------------------------------------
JIFFY_HI        = $A0       ; 24-bit jiffy counter high byte
JIFFY_MID       = $A1       ;                       mid byte
JIFFY_LO        = $A2       ;                       low byte  (60 Hz tick)
LAST_KEY        = $C5       ; Last key matrix position ($40 = none)
KEY_BUF_CNT     = $C6       ; Number of chars in keyboard buffer

; ------------------------------------------------------------
; KERNAL ROM entry points
; ------------------------------------------------------------
KERNAL_GETIN    = $FFE4     ; Get next character from keyboard buffer (A=0 if empty)
KERNAL_CHROUT   = $FFD2     ; Output character in A to current device
KERNAL_SETMSG   = $FF90     ; Set KERNAL messages on/off
KERNAL_IOINIT   = $FDA3     ; Init I/O devices
KERNAL_CINT     = $FF81     ; Init CIA and screen
KERNAL_IRQ      = $EA31     ; Standard IRQ handler entry

; ------------------------------------------------------------
; C64 hardware colors (0-15)
; ------------------------------------------------------------
COLOR_BLACK     = 0
COLOR_WHITE     = 1
COLOR_RED       = 2
COLOR_CYAN      = 3
COLOR_PURPLE    = 4
COLOR_GREEN     = 5
COLOR_BLUE      = 6
COLOR_YELLOW    = 7
COLOR_ORANGE    = 8
COLOR_BROWN     = 9
COLOR_LTRED     = 10
COLOR_DKGRAY    = 11
COLOR_MDGRAY    = 12
COLOR_LTGREEN   = 13
COLOR_LTBLUE    = 14
COLOR_LTGRAY    = 15

; ------------------------------------------------------------
; Screen layout
; ------------------------------------------------------------
SCREEN_COLS     = 40
SCREEN_ROWS     = 25
MAP_WIDTH       = 40        ; Visible map columns (full width)
MAP_HEIGHT      = 20        ; Visible map rows
UI_ROW_SEP      = 21        ; Separator / top-of-UI bar
UI_ROW_STATS    = 22        ; Year / cash / pop stats
UI_ROW_MENU     = 0         ; Building-selector menu (top row)
UI_ROW_MSG      = 23        ; Message / mode indicator
UI_ROW_HELP     = 24        ; Key-bindings help line
RASTER_SPLIT_TOP    = 48    ; Restore top playfield background near frame start
RASTER_SPLIT_LOWER  = 218   ; Switch lower 4 text rows to black

; ------------------------------------------------------------
; Tile types  (one byte per tile in map array)
; ------------------------------------------------------------
TILE_EMPTY      = 0         ; Open land (grass)
TILE_ROAD       = 1         ; Road
TILE_HOUSE      = 2         ; Residential zone
TILE_FACTORY    = 3         ; Industrial factory
TILE_PARK       = 4         ; City park
TILE_POWER      = 5         ; Power plant
TILE_POLICE     = 6         ; Police station
TILE_FIRE       = 7         ; Fire station
TILE_BRIDGE     = 8         ; Bridge / road over water
TILE_WATER      = 9         ; Water / river (decorative)
TILE_TREE       = 10        ; Forest (decorative)
TILE_COUNT      = 11        ; Total tile-type count
TILE_TYPE_MASK      = $0F   ; Low nibble stores the base tile type
TILE_DENSITY_MASK   = $30   ; Bits 4-5 store density level (0-3 => 1-4)
TILE_DENSITY_STEP   = $10   ; One density level in the encoded tile byte
TILE_MAX_DENSITY    = $30   ; Highest encoded density (level 4)

; ------------------------------------------------------------
; Building costs (low byte / high byte split for 16-bit math)
; ------------------------------------------------------------
COST_ROAD_LO    = <10
COST_ROAD_HI    = >10
COST_HOUSE_LO   = <100
COST_HOUSE_HI   = >100
COST_FACTORY_LO = <500
COST_FACTORY_HI = >500
COST_PARK_LO    = <200
COST_PARK_HI    = >200
COST_POWER_LO   = <1000
COST_POWER_HI   = >1000
COST_POLICE_LO  = <300
COST_POLICE_HI  = >300
COST_FIRE_LO    = <300
COST_FIRE_HI    = >300
COST_BRIDGE_LO  = <100
COST_BRIDGE_HI  = >100

; ------------------------------------------------------------
; PETSCII key codes  (returned by GETIN)
; ------------------------------------------------------------
KEY_NONE        = $00       ; Empty buffer
KEY_CRSR_UP     = $91       ; Cursor up   (Shift + Crsr Down)
KEY_CRSR_DOWN   = $11       ; Cursor down
KEY_CRSR_LEFT   = $9D       ; Cursor left (Shift + Crsr Right)
KEY_CRSR_RIGHT  = $1D       ; Cursor right
KEY_RETURN      = $0D       ; Return / Enter
KEY_DEL         = $14       ; Delete
KEY_STOP        = $03       ; Run/Stop
KEY_SPACE       = $20       ; Space bar
KEY_F1          = $85       ; F1  (select Road)
KEY_F3          = $86       ; F3  (select House)
KEY_F5          = $87       ; F5  (select Factory)
KEY_F7          = $88       ; F7  (select Park)

; Letter keys (uppercase PETSCII; we mask lowercase in input.s)
KEY_CHR_1       = $31       ; '1' Road
KEY_CHR_2       = $32       ; '2' House
KEY_CHR_3       = $33       ; '3' Factory
KEY_CHR_4       = $34       ; '4' Park
KEY_CHR_5       = $35       ; '5' Power plant
KEY_CHR_6       = $36       ; '6' Police
KEY_CHR_7       = $37       ; '7' Fire station
KEY_CHR_W       = $57       ; 'W' / move up
KEY_CHR_A       = $41       ; 'A' / move left
KEY_CHR_S       = $53       ; 'S' / move down
KEY_CHR_D       = $44       ; 'D' / move right (also Demolish held via mode)
KEY_CHR_B       = $42       ; 'B' Build (same as RETURN)
KEY_CHR_X       = $58       ; 'X' demolish
KEY_CHR_Q       = $51       ; 'Q' quit to title

; ------------------------------------------------------------
; Game mode
; ------------------------------------------------------------
MODE_BUILD      = 0         ; Normal / build mode
MODE_DEMO       = 1         ; Demolish mode

; ------------------------------------------------------------
; Simulation parameters
; ------------------------------------------------------------
SIM_INTERVAL        = 60    ; Frames (~1 real second) between sim ticks
YEAR_TICKS          = 12    ; Sim ticks per game year

TAX_PER_RESIDENT    = 2     ; Property / local taxes per resident
TAX_PER_EMPLOYED    = 2     ; Payroll / commerce taxes per employed resident
TAX_PER_HOUSE       = 2     ; Housing tax base per zoned house unit
TAX_PER_FACTORY     = 20    ; Industrial tax base per factory unit
MAINT_ROAD          = 1     ; Upkeep per road
MAINT_HOUSE         = 1     ; Upkeep per house
MAINT_FACTORY       = 5     ; Upkeep per factory
MAINT_PARK          = 5     ; Upkeep per park
MAINT_POWER         = 20    ; Upkeep per power plant
MAINT_POLICE        = 10    ; Upkeep per police station
MAINT_FIRE          = 10    ; Upkeep per fire station

POWER_PER_PLANT     = 50    ; Power produced per plant
POWER_PER_HOUSE     = 5     ; Power consumed per house
POWER_PER_FACTORY   = 20    ; Power consumed per factory
POWER_PER_SERVICE   = 2     ; Power consumed per police/fire service unit

HAPPINESS_BASE      = 35
HAPPINESS_PER_PARK  = 10
CRIME_BASE          = 25
CRIME_PER_POLICE    = 10
JOBS_PER_FACTORY    = 10    ; Jobs created per factory unit
JOBS_PER_SERVICE    = 2     ; Public-sector jobs created per service unit
POP_JOB_BUFFER      = 5     ; Residents tolerated above the raw jobs count
BLACKOUT_PENALTY    = 20    ; Treasury hit when the city is underpowered
PARK_RADIUS         = 3
POLICE_RADIUS       = 4
FIRE_RADIUS         = 4
PARK_EFFECT_STEP    = 3
POLICE_EFFECT_STEP  = 2
FIRE_EFFECT_STEP    = 2
VALUE_CAP           = 99
VALUE_BASE_ROAD     = 8
VALUE_BASE_HOUSE    = 20
VALUE_BASE_FACTORY  = 16
VALUE_BASE_PARK     = 18
VALUE_BASE_POWER    = 12
VALUE_BASE_POLICE   = 18
VALUE_BASE_FIRE     = 18
VALUE_PER_DENSITY   = 4
VALUE_BONUS_ROAD    = 4
VALUE_BONUS_HOUSE   = 2
VALUE_BONUS_PARK    = 3
VALUE_BONUS_SERVICE = 2
VALUE_PENALTY_FACTORY = 6
VALUE_PENALTY_POWER   = 4
VALUE_PENALTY_NO_ROAD = 8

; ------------------------------------------------------------
; Starting values
; ------------------------------------------------------------
INITIAL_MONEY_LO    = <5000
INITIAL_MONEY_HI    = >5000
INITIAL_YEAR_LO     = <1900
INITIAL_YEAR_HI     = >1900
INITIAL_HAPPINESS   = 50
INITIAL_CRIME       = 40

; ------------------------------------------------------------
; Cursor display
; ------------------------------------------------------------
CURSOR_COLOR        = COLOR_WHITE
CURSOR_BLINK_RATE   = 25    ; Frames between blink state changes
CURSOR_SPR_X_BASE   = 17    ; 24-pixel text origin minus 7-pixel box inset
CURSOR_SPR_Y_BASE   = 44    ; 50-pixel text origin minus 6-pixel box inset

; ------------------------------------------------------------
; Map total size
; ------------------------------------------------------------
MAP_SIZE            = MAP_WIDTH * MAP_HEIGHT    ; 800 tiles
