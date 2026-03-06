; ============================================================
; C64 City Builder - Hardware Constants and Game Definitions
; Included by main.s (single-unit build via .include)
; ============================================================

; ------------------------------------------------------------
; Commodore 64  VIC-II registers ($D000-$D3FF)
; ------------------------------------------------------------
VIC_SPRITE_EN   = $D015     ; Sprite enable
VIC_CTRL1       = $D011     ; Control register 1 (screen on/off, raster)
VIC_RASTER      = $D012     ; Raster compare
VIC_CTRL2       = $D016     ; Control register 2 (multicolor etc.)
VIC_VMEM_CTRL   = $D018     ; Video memory control (screen/char base)
VIC_IRQ_STATUS  = $D019     ; Interrupt status
VIC_IRQ_CTRL    = $D01A     ; Interrupt control
VIC_BORDER_CLR  = $D020     ; Border color
VIC_BKG_CLR0    = $D021     ; Background color 0
VIC_BKG_CLR1    = $D022     ; Background color 1

; ------------------------------------------------------------
; CIA #1 registers - keyboard & joystick ($DC00-$DCFF)
; ------------------------------------------------------------
CIA1_PRA        = $DC00     ; Port A: keyboard column select
CIA1_PRB        = $DC01     ; Port B: keyboard row read
CIA1_DDRA       = $DC02     ; Port A direction register
CIA1_DDRB       = $DC03     ; Port B direction register

; ------------------------------------------------------------
; C64 Memory map
; ------------------------------------------------------------
SCREEN_BASE     = $0400     ; Default screen RAM (40×25)
COLOR_BASE      = $D800     ; Color RAM (mirrors screen layout)
SCREEN_SIZE     = 1000      ; 40×25 characters

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
UI_ROW_SEP      = 20        ; Separator / top-of-UI bar
UI_ROW_STATS    = 21        ; Year / cash / pop stats
UI_ROW_MENU     = 22        ; Building-selector menu
UI_ROW_MSG      = 23        ; Message / mode indicator
UI_ROW_HELP     = 24        ; Key-bindings help line

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
TILE_WATER      = 8         ; Water / river (decorative)
TILE_TREE       = 9         ; Forest (decorative)
TILE_COUNT      = 10        ; Total tile-type count

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

INCOME_FACTORY      = 50    ; Income per factory per tick
MAINT_ROAD          = 1     ; Upkeep per road
MAINT_HOUSE         = 2     ; Upkeep per house
MAINT_FACTORY       = 10    ; Upkeep per factory
MAINT_PARK          = 5     ; Upkeep per park
MAINT_POWER         = 50    ; Upkeep per power plant
MAINT_POLICE        = 20    ; Upkeep per police station
MAINT_FIRE          = 20    ; Upkeep per fire station

POWER_PER_PLANT     = 50    ; Power produced per plant
POWER_PER_HOUSE     = 5     ; Power consumed per house
POWER_PER_FACTORY   = 20    ; Power consumed per factory

HAPPINESS_BASE      = 50
HAPPINESS_PER_PARK  = 10
CRIME_BASE          = 40
CRIME_PER_POLICE    = 10

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

; ------------------------------------------------------------
; Map total size
; ------------------------------------------------------------
MAP_SIZE            = MAP_WIDTH * MAP_HEIGHT    ; 800 tiles
