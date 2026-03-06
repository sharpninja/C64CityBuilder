; ============================================================
; C64 City Builder - Building Placement and Demolition
; Included by main.s.
; ============================================================

    .segment "CODE"

; ------------------------------------------------------------
; try_place_building
; Attempt to place sel_building at (cursor_x, cursor_y).
; ------------------------------------------------------------
try_place_building:
    lda sel_building
    bne @tp_sel_ok
    rts                     ; 0 = nothing selected
@tp_sel_ok:
    cmp #TILE_WATER
    bne @tp_not_water
    rts
@tp_not_water:
    cmp #TILE_TREE
    bne @tp_not_tree
    rts
@tp_not_tree:

    ; Can't build on a water tile in the map
    lda cursor_x
    ldx cursor_y
    jsr get_tile
    cmp #TILE_WATER
    bne @tp_check_cost
    ; Show can't-build message
    lda #<str_msg_cantbuild
    sta ptr_lo
    lda #>str_msg_cantbuild
    sta ptr_hi
    ldx #0
    ldy #UI_ROW_MSG
    lda #COLOR_ORANGE
    jsr print_str_col
    lda #90
    sta msg_timer
    lda #1
    sta dirty_ui
    rts

@tp_check_cost:
    ; 16-bit: money - cost; negative result → not enough
    lda sel_building
    tax
    lda bld_cost_lo,x
    sta tmp3
    lda bld_cost_hi,x
    sta tmp4

    lda money_lo
    sec
    sbc tmp3
    sta tmp1            ; result lo
    lda money_hi
    sbc tmp4
    bpl @tp_afford      ; high byte >= 0 → affordable

    ; Not enough cash
    lda #<str_msg_notenough
    sta ptr_lo
    lda #>str_msg_notenough
    sta ptr_hi
    ldx #0
    ldy #UI_ROW_MSG
    lda #COLOR_LTRED
    jsr print_str_col
    lda #90
    sta msg_timer
    lda #1
    sta dirty_ui
    rts

@tp_afford:
    sta money_hi
    lda tmp1
    sta money_lo

    ; Place the building
    lda cursor_x
    sta tmp1
    lda cursor_y
    sta tmp2
    lda sel_building
    jsr place_tile_at

    lda #<str_msg_placed
    sta ptr_lo
    lda #>str_msg_placed
    sta ptr_hi
    ldx #0
    ldy #UI_ROW_MSG
    lda #COLOR_LTGREEN
    jsr print_str_col
    lda #90
    sta msg_timer
    lda #1
    sta dirty_ui
    rts

; ------------------------------------------------------------
; try_demolish
; Remove the building under the cursor; replace with TILE_EMPTY.
; ------------------------------------------------------------
try_demolish:
    lda cursor_x
    ldx cursor_y
    jsr get_tile
    cmp #TILE_EMPTY
    bne @td_do_it
    rts                     ; already empty
@td_do_it:
    jsr decrement_count     ; remove from count (A = old tile)

    lda cursor_x
    sta tmp1
    lda cursor_y
    sta tmp2
    lda #TILE_EMPTY
    jsr place_tile_at

    lda #<str_msg_demolished
    sta ptr_lo
    lda #>str_msg_demolished
    sta ptr_hi
    ldx #0
    ldy #UI_ROW_MSG
    lda #COLOR_MDGRAY
    jsr print_str_col
    lda #60
    sta msg_timer
    lda #1
    sta dirty_ui
    rts

; ------------------------------------------------------------
; place_tile_at
; Write tile A to map at (tmp1=col, tmp2=row), update counts,
; and redraw the tile on screen.
; Uses tmp4 to save the new tile type across helper calls.
; tmp3 is used internally by get_tile / set_tile.
; ------------------------------------------------------------
place_tile_at:
    sta tmp4                ; save new tile type

    ; Decrement count for the OLD tile at this position
    lda tmp1
    ldx tmp2
    jsr get_tile            ; A = old tile type (uses tmp3 internally)
    jsr decrement_count

    ; Write new tile to map via set_tile(col=A, row=X, tile=Y)
    lda tmp4
    tay                     ; Y = new tile
    lda tmp1                ; A = col
    ldx tmp2                ; X = row
    jsr set_tile

    ; Increment count for the NEW tile
    lda tmp4
    jsr increment_count

    ; Redraw the tile on screen (uses tmp1=col, tmp2=row)
    jsr render_tile

    rts

; ------------------------------------------------------------
; increment_count  (A = tile type)
; Increment the appropriate building-count ZP variable.
; ------------------------------------------------------------
increment_count:
    cmp #TILE_ROAD
    bne @inc1
    inc cnt_roads
    rts
@inc1:
    cmp #TILE_HOUSE
    bne @inc2
    inc cnt_houses
    rts
@inc2:
    cmp #TILE_FACTORY
    bne @inc3
    inc cnt_factories
    rts
@inc3:
    cmp #TILE_PARK
    bne @inc4
    inc cnt_parks
    rts
@inc4:
    cmp #TILE_POWER
    bne @inc5
    inc cnt_power
    rts
@inc5:
    cmp #TILE_POLICE
    bne @inc6
    inc cnt_police
    rts
@inc6:
    cmp #TILE_FIRE
    bne @inc_done
    inc cnt_fire
@inc_done:
    rts

; ------------------------------------------------------------
; decrement_count  (A = tile type)
; Decrement the appropriate building-count ZP variable (floor 0).
; ------------------------------------------------------------
decrement_count:
    cmp #TILE_ROAD
    bne @dec1
    lda cnt_roads
    beq @dec_done
    dec cnt_roads
    rts
@dec1:
    cmp #TILE_HOUSE
    bne @dec2
    lda cnt_houses
    beq @dec_done
    dec cnt_houses
    rts
@dec2:
    cmp #TILE_FACTORY
    bne @dec3
    lda cnt_factories
    beq @dec_done
    dec cnt_factories
    rts
@dec3:
    cmp #TILE_PARK
    bne @dec4
    lda cnt_parks
    beq @dec_done
    dec cnt_parks
    rts
@dec4:
    cmp #TILE_POWER
    bne @dec5
    lda cnt_power
    beq @dec_done
    dec cnt_power
    rts
@dec5:
    cmp #TILE_POLICE
    bne @dec6
    lda cnt_police
    beq @dec_done
    dec cnt_police
    rts
@dec6:
    cmp #TILE_FIRE
    bne @dec_done
    lda cnt_fire
    beq @dec_done
    dec cnt_fire
@dec_done:
    rts

; ------------------------------------------------------------
; show_building_name  (called from input.s)
; Display the name of sel_building as a timed message.
; ------------------------------------------------------------
show_building_name:
    lda sel_building
    beq @sbn_done
    cmp #TILE_WATER         ; valid range is 1-7 (TILE_ROAD..TILE_FIRE)
    bcs @sbn_done
    sec
    sbc #1                  ; 0-6 index into bld_names table
    asl                     ; × 2 for word pointer
    tax
    lda bld_names,x
    sta ptr_lo
    lda bld_names+1,x
    sta ptr_hi
    ldx #0
    ldy #UI_ROW_MSG
    lda #COLOR_LTGREEN
    jsr print_str_col
    lda #60
    sta msg_timer
@sbn_done:
    rts
