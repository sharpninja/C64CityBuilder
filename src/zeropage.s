; ============================================================
; C64 City Builder - Zero Page Variable Layout
; All variables here are accessed with fast zero-page addressing.
; Starts at $0002 (KERNAL uses $90-$FF; we stay well below that).
; ============================================================

    .segment "ZEROPAGE"

; --- Cursor ------------------------------------------------
cursor_x:       .res 1      ; Cursor X position (0-39)
cursor_y:       .res 1      ; Cursor Y position (0-19)

; --- General-purpose indirect pointers ------------------
ptr_lo:         .res 1      ; Pointer low  byte
ptr_hi:         .res 1      ; Pointer high byte
ptr2_lo:        .res 1      ; Second pointer low
ptr2_hi:        .res 1      ; Second pointer high

; --- Game state -----------------------------------------
game_mode:      .res 1      ; MODE_BUILD / MODE_DEMO
sel_building:   .res 1      ; Currently selected building type (1-7, matches TILE_ROAD..TILE_FIRE)
dirty_map:      .res 1      ; Non-zero = map needs full redraw
dirty_ui:       .res 1      ; Non-zero = UI bar needs redraw

; --- Resources (16-bit money + 8-bit counters) ----------
money_lo:       .res 1      ; Cash (low byte)
money_hi:       .res 1      ; Cash (high byte)
population:     .res 1      ; City population (0-255 ×10)
happiness:      .res 1      ; Happiness 0-100
crime:          .res 1      ; Crime level 0-100
power_avail:    .res 1      ; Power units available
power_needed:   .res 1      ; Power units needed

; --- Time -----------------------------------------------
year_lo:        .res 1      ; Game year low byte
year_hi:        .res 1      ; Game year high byte
tick_count:     .res 1      ; Ticks since last year advance

; --- Building counts (updated each sim tick) -------------
cnt_roads:      .res 1
cnt_houses:     .res 1
cnt_factories:  .res 1
cnt_parks:      .res 1
cnt_power:      .res 1
cnt_police:     .res 1
cnt_fire:       .res 1

; --- Timing --------------------------------------------
sim_counter:    .res 1      ; Countdown to next simulation tick
last_jiffy:     .res 1      ; Last value of JIFFY_LO (for frame sync)
blink_timer:    .res 1      ; Countdown for cursor blink

; --- Input ---------------------------------------------
key_last:       .res 1      ; Previous raw key (for held-key detection)

; --- Scratch / temporaries ------------------------------
tmp1:           .res 1
tmp2:           .res 1
tmp3:           .res 1
tmp4:           .res 1

; --- Number-printing workspace -------------------------
np_val_lo:      .res 1      ; Value to print (low)
np_val_hi:      .res 1      ; Value to print (high)
np_div_lo:      .res 1      ; Divisor (low)
np_div_hi:      .res 1      ; Divisor (high)

; --- Message display -----------------------------------
msg_timer:      .res 1      ; Frames left to show current message

; --- Cursor-save (colour under cursor) -----------------
cur_save_col:   .res 1      ; Original colour byte at cursor tile

; --- Blink state ---------------------------------------
blink_state:    .res 1      ; 0 = cursor highlight off, 1 = on
split_top_bg:   .res 1      ; Background colour used above the raster split
raster_phase:   .res 1      ; 0 = top-half IRQ next, 1 = lower-UI IRQ next
tile_col:       .res 1      ; Current tile column for adjacency-aware rendering
tile_row:       .res 1      ; Current tile row for adjacency-aware rendering
road_mask:      .res 1      ; NSEW neighbor mask for dynamic road glyph lookup
