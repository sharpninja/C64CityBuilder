; ============================================================
; C64 City Builder - Zero Page Variable Layout
; Keep only the two indirect pointer pairs in true zero page.
; The C64 KERNAL/BASIC/IRQ paths reuse much of low ZP, so the rest
; of the game state lives in normal BSS instead of contested ZP.
; ============================================================

    .segment "ZEROPAGE"

; --- General-purpose indirect pointers ------------------
ptr_lo:         .res 1      ; Pointer low  byte
; Reserve storage for pointer high byte.
ptr_hi:         .res 1      ; Pointer high byte
; Reserve storage for second pointer low.
ptr2_lo:        .res 1      ; Second pointer low
; Reserve storage for second pointer high.
ptr2_hi:        .res 1      ; Second pointer high

    .segment "BSS"

; --- Cursor ------------------------------------------------
cursor_x:       .res 1      ; Cursor X position (0-39)
; Reserve storage for cursor y position (0-19).
cursor_y:       .res 1      ; Cursor Y position (0-19)

; --- Game state -----------------------------------------
game_mode:      .res 1      ; MODE_BUILD / MODE_DEMO
; Reserve storage for currently selected building type (1-7, matches tile_road..tile_fire).
sel_building:   .res 1      ; Currently selected building type (1-7, matches TILE_ROAD..TILE_FIRE)
; Reserve storage for non-zero = map needs full redraw.
dirty_map:      .res 1      ; Non-zero = map needs full redraw
; Reserve storage for non-zero = ui bar needs redraw.
dirty_ui:       .res 1      ; Non-zero = UI bar needs redraw

; --- Resources (16-bit money + 8-bit counters) ----------
money_lo:       .res 1      ; Cash (low byte)
; Reserve storage for cash (high byte).
money_hi:       .res 1      ; Cash (high byte)
; Reserve storage for city population (0-255 ×10).
population:     .res 1      ; City population (0-255 ×10)
; Reserve storage for happiness 0-100.
happiness:      .res 1      ; Happiness 0-100
; Reserve storage for crime level 0-100.
crime:          .res 1      ; Crime level 0-100
; Reserve storage for power units available.
power_avail:    .res 1      ; Power units available
; Reserve storage for power units needed.
power_needed:   .res 1      ; Power units needed

; --- Time -----------------------------------------------
year_lo:        .res 1      ; Game year low byte
; Reserve storage for game year high byte.
year_hi:        .res 1      ; Game year high byte
; Reserve storage for ticks since last year advance.
tick_count:     .res 1      ; Ticks since last year advance

; --- Building counts (updated each sim tick) -------------
cnt_roads:      .res 1
; Reserve storage for houses.
cnt_houses:     .res 1
; Reserve storage for factories.
cnt_factories:  .res 1
; Reserve storage for parks.
cnt_parks:      .res 1
; Reserve storage for power.
cnt_power:      .res 1
; Reserve storage for police.
cnt_police:     .res 1
; Reserve storage for fire.
cnt_fire:       .res 1
; Reserve storage for jobs total.
jobs_total:     .res 1
; Reserve storage for employed pop.
employed_pop:   .res 1
; Store low-byte values for rev.
rev_lo:         .res 1
; Store high-byte values for rev.
rev_hi:         .res 1
; Store low-byte values for cost.
cost_lo:        .res 1
; Store high-byte values for cost.
cost_hi:        .res 1
; Reserve storage for park coverage.
park_coverage:  .res 1
; Reserve storage for police coverage.
police_coverage:.res 1
; Reserve storage for fire coverage.
fire_coverage:  .res 1
; Store low-byte values for land value.
land_value_lo:  .res 1
; Store high-byte values for land value.
land_value_hi:  .res 1

; --- Timing --------------------------------------------
sim_counter:    .res 1      ; Countdown to next simulation tick
; Reserve storage for last value of jiffy_lo (for frame sync).
last_jiffy:     .res 1      ; Last value of JIFFY_LO (for frame sync)
; Reserve storage for countdown for cursor blink.
blink_timer:    .res 1      ; Countdown for cursor blink

; --- Input ---------------------------------------------
key_last:       .res 1      ; Previous raw key (for held-key detection)

; --- Scratch / temporaries ------------------------------
tmp1:           .res 1
; Reserve storage for tmp2.
tmp2:           .res 1
; Reserve storage for tmp3.
tmp3:           .res 1
; Reserve storage for tmp4.
tmp4:           .res 1

; --- Number-printing workspace -------------------------
np_val_lo:      .res 1      ; Value to print (low)
; Reserve storage for value to print (high).
np_val_hi:      .res 1      ; Value to print (high)
; Reserve storage for divisor (low).
np_div_lo:      .res 1      ; Divisor (low)
; Reserve storage for divisor (high).
np_div_hi:      .res 1      ; Divisor (high)

; --- Message display -----------------------------------
msg_timer:      .res 1      ; Frames left to show current message

; --- Cursor-save (colour under cursor) -----------------
cur_save_col:   .res 1      ; Original colour byte at cursor tile

; --- Blink state ---------------------------------------
blink_state:    .res 1      ; 0 = cursor highlight off, 1 = on
; Reserve storage for background colour used above the raster split.
split_top_bg:   .res 1      ; Background colour used above the raster split
; Reserve storage for 0 = top-half irq next, 1 = lower-ui irq next.
raster_phase:   .res 1      ; 0 = top-half IRQ next, 1 = lower-UI IRQ next
; Reserve storage for current tile column for adjacency-aware rendering.
tile_col:       .res 1      ; Current tile column for adjacency-aware rendering
; Reserve storage for current tile row for adjacency-aware rendering.
tile_row:       .res 1      ; Current tile row for adjacency-aware rendering
; Reserve storage for nsew neighbor mask for dynamic road glyph lookup.
road_mask:      .res 1      ; NSEW neighbor mask for dynamic road glyph lookup
; Reserve storage for highlight radius for the tile under the cursor.
cursor_aoe_radius: .res 1   ; Highlight radius for the tile under the cursor
; Reserve storage for non-zero when the cursor tile has an aoe.
cursor_aoe_active: .res 1   ; Non-zero when the cursor tile has an AoE
; Reserve storage for shared multicolor background used for aoe tint.
cursor_aoe_color:  .res 1   ; Shared multicolor background used for AoE tint
