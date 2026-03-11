; ============================================================
; C64 City Builder
; A modern city-building game for the Commodore 64
; Written in 6510 Assembly using CA65 / LD65
;
; Build:  make
; Output: citybuilder.prg  (standard C64 PRG, loads at $0801)
;
; Controls:
;   W/A/S/D or cursor keys  - Move cursor
;   1-7                     - Select building type
;   RETURN or B             - Build selected building
;   X                       - Demolish building at cursor
;   Q                       - Return to title screen
;
; Building types:
;   1 Road  ($10)    2 House ($100)    3 Factory ($500)
;   4 Park  ($200)   5 Power ($1000)   6 Police  ($300)
;   7 Fire  ($300)
; ============================================================

; --- Include all definitions (no code, no segments) ---------
    .include "constants.s"

; --- Zero-page variable layout ------------------------------
    .include "zeropage.s"

; ============================================================
; PRG file header: 2-byte load address ($0801)
; ============================================================
    .segment "LOADADDR"
    .word $0801             ; Little-endian load address → $01, $08

; ============================================================
; BASIC stub: SYS 2061  (2061 = $080D, start of CODE segment)
;
; $0801: 0B 08       next-line pointer → $080B
; $0803: 0A 00       line number 10
; $0805: 9E          SYS token
; $0806: 32 30 36 31 ASCII "2061"
; $080A: 00          end-of-line
; $080B: 00 00       end-of-BASIC
;                    (12 bytes total, CODE starts at $080D)
; ============================================================
    .segment "HEADER"
    .word $080B             ; pointer to next BASIC line
    .word 10                ; line number 10
    .byte $9E               ; SYS token
    .byte "2061"            ; ASCII decimal address
    .byte 0                 ; end of BASIC line
    .word 0                 ; end of BASIC program

; ============================================================
; CODE segment begins at $080D  (= decimal 2061)
; ============================================================
    .segment "CODE"

; ============================================================
; game_start
; Entry point jumped to by the BASIC SYS stub.
; Initialises hardware, shows title, enters main loop.
; ============================================================
game_start:
    jsr init_system         ; hardware + zero-page setup
    jsr show_title          ; title screen + keypress wait

    ; ---- Full first-frame render --------------------------
    jsr clear_screen ; clear the whole visible screen
    jsr render_map ; redraw the full city map
    jsr draw_status_bar ; redraw the status bar
    jsr enable_cursor_sprite ; show the cursor sprite

; ============================================================
; game_loop
; Main game loop – runs forever.
; One iteration per jiffy (~60 Hz via KERNAL timer at $A2).
; ============================================================
game_loop:
    ; --- Wait for the next jiffy tick ---------------------
; Branch target from @wait_jiffy if the test matched.
@wait_jiffy:
    lda JIFFY_LO ; load JIFFY LO into A
    cmp last_jiffy ; last jiffy snapshot
    beq @wait_jiffy ; if the test matched, branch to wait jiffy
    sta last_jiffy ; store A into last jiffy snapshot

    ; --- Read keyboard input ------------------------------
    jsr read_input ; process one keyboard input event

    ; --- Simulation tick ---------------------------------
    dec sim_counter ; count down toward the next simulation tick
    bne @no_sim ; if the test did not match, branch to sim
    jsr run_simulation ; advance the city simulation
; Continue with the sim path.
; Branch target from @wait_jiffy if the test did not match.
@no_sim:

    ; --- Redraw map if dirty ----------------------------
    lda dirty_map ; load map redraw flag into A
    beq @no_map_redraw ; if the test matched, branch to map redraw
    jsr render_map ; redraw the full city map
; Continue with the map redraw path.
; Branch target from @no_sim if the test matched.
@no_map_redraw:

    ; --- Update cursor highlight (blink) ----------------
    jsr update_cursor_display ; refresh cursor visibility and blink state

    ; --- Redraw UI bar if dirty -------------------------
    lda dirty_ui ; load UI redraw flag into A
    beq @no_ui_redraw ; if the test matched, branch to ui redraw
    jsr draw_status_bar ; redraw the status bar
; Continue with the ui redraw path.
; Branch target from @no_map_redraw if the test matched.
@no_ui_redraw:

    jmp game_loop ; continue at game loop

; ============================================================
; Include all game modules (single compilation unit)
; ============================================================
    .include "init.s"
    .include "title.s"
    .include "input.s"
    .include "map.s"
    .include "buildings.s"
    .include "simulation.s"
    .include "ui.s"
    .include "data.s"
