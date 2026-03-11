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
    ; Read the current tile once so we can detect upgrades and density caps.
    lda cursor_x
    ldx cursor_y
    jsr get_tile
    sta tmp4                ; raw tile byte
    and #TILE_TYPE_MASK
    sta tmp3                ; current base tile type
    cmp sel_building
    beq @tp_upgrade_density

    ; Can't build on water or tree tiles
    cmp #TILE_WATER
    beq @tp_cant_build
    cmp #TILE_TREE
    beq @tp_cant_build

@tp_upgrade_density:
    lda tmp4
    and #TILE_DENSITY_MASK
    cmp #TILE_MAX_DENSITY
    beq @tp_max_density

@tp_check_cost:
    ; 16-bit: money - cost; negative result → not enough
    lda sel_building
    tax
    lda bld_cost_lo,x
    sta tmp1
    lda bld_cost_hi,x
    sta tmp2

    lda money_lo
    sec
    sbc tmp1
    sta tmp1            ; result lo
    lda money_hi
    sbc tmp2
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

@tp_cant_build:
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

@tp_max_density:
    lda #<str_msg_maxdense
    sta ptr_lo
    lda #>str_msg_maxdense
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

@tp_afford:
    sta money_hi
    lda tmp1
    sta money_lo

    lda cursor_x
    sta tmp1
    lda cursor_y
    sta tmp2

    lda tmp3
    cmp sel_building

    beq @tp_make_upgrade
    lda #0
    pha
    lda sel_building
    bne @tp_place_tile
@tp_make_upgrade:
    lda #1
    pha
    lda tmp4
    clc
    adc #TILE_DENSITY_STEP
@tp_place_tile:
    jsr place_tile_at
    pla
    bne @tp_msg_upgraded

    lda #<str_msg_placed
    sta ptr_lo
    lda #>str_msg_placed
    sta ptr_hi
    bne @tp_show_msg
@tp_msg_upgraded:
    lda #<str_msg_upgraded
    sta ptr_lo
    lda #>str_msg_upgraded
    sta ptr_hi
@tp_show_msg:
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
    sta tmp4                ; raw tile byte
    and #TILE_TYPE_MASK
    cmp #TILE_EMPTY
    bne @td_do_it
    rts                     ; already empty
@td_do_it:
    lda tmp4
    and #TILE_TYPE_MASK
    cmp #TILE_ROAD
    bcc @td_clear_tile
    cmp #TILE_FIRE + 1
    bcs @td_clear_tile
    lda tmp4
    and #TILE_DENSITY_MASK
    beq @td_clear_tile
    lda tmp4
    sec
    sbc #TILE_DENSITY_STEP
    sta tmp3
    lda #1
    pha
    bne @td_place
@td_clear_tile:
    lda #TILE_EMPTY
    sta tmp3
    lda #0
    pha
@td_place:

    lda cursor_x
    sta tmp1
    lda cursor_y
    sta tmp2
    lda tmp3
    jsr place_tile_at

    pla
    beq @td_msg_demo
    lda #<str_msg_downgraded
    sta ptr_lo
    lda #>str_msg_downgraded
    sta ptr_hi
    bne @td_show_msg
@td_msg_demo:
    lda #<str_msg_demolished
    sta ptr_lo
    lda #>str_msg_demolished
    sta ptr_hi
@td_show_msg:
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
    pha                     ; save new tile type on the stack

    ; Decrement count for the OLD tile at this position
    lda tmp1
    ldx tmp2
    jsr get_tile            ; A = old tile type (uses tmp3 internally)
    jsr decrement_count

    ; Write new tile to map via set_tile(col=A, row=X, tile=Y)
    pla
    sta tmp4
    tay                     ; Y = new tile
    lda tmp1                ; A = col
    ldx tmp2                ; X = row
    jsr set_tile

    ; Increment count for the NEW tile
    lda tmp4
    jsr increment_count

    ; Redraw the changed tile and any adjacent roads so road
    ; junction glyphs stay in sync with the map.
    jsr render_road_neighborhood
    lda #1
    sta dirty_map

    rts

; ------------------------------------------------------------
; increment_count  (A = tile type)
; Increment the appropriate building-count ZP variable.
; ------------------------------------------------------------
get_tile_density_units:
    and #TILE_DENSITY_MASK
    lsr
    lsr
    lsr
    lsr
    clc
    adc #1
    rts

increment_count:
    sta tmp3
    and #TILE_TYPE_MASK
    tax
    lda tmp3
    jsr get_tile_density_units
    sta tmp4
    txa
    cmp #TILE_ROAD
    bne @inc1
    lda cnt_roads
    clc
    adc tmp4
    bcc @inc_store_road
    lda #$FF
@inc_store_road:
    sta cnt_roads
    rts
@inc1:
    cmp #TILE_HOUSE
    bne @inc2
    lda cnt_houses
    clc
    adc tmp4
    bcc @inc_store_house
    lda #$FF
@inc_store_house:
    sta cnt_houses
    rts
@inc2:
    cmp #TILE_FACTORY
    bne @inc3
    lda cnt_factories
    clc
    adc tmp4
    bcc @inc_store_factory
    lda #$FF
@inc_store_factory:
    sta cnt_factories
    rts
@inc3:
    cmp #TILE_PARK
    bne @inc4
    lda cnt_parks
    clc
    adc tmp4
    bcc @inc_store_park
    lda #$FF
@inc_store_park:
    sta cnt_parks
    rts
@inc4:
    cmp #TILE_POWER
    bne @inc5
    lda cnt_power
    clc
    adc tmp4
    bcc @inc_store_power
    lda #$FF
@inc_store_power:
    sta cnt_power
    rts
@inc5:
    cmp #TILE_POLICE
    bne @inc6
    lda cnt_police
    clc
    adc tmp4
    bcc @inc_store_police
    lda #$FF
@inc_store_police:
    sta cnt_police
    rts
@inc6:
    cmp #TILE_FIRE
    bne @inc_done
    lda cnt_fire
    clc
    adc tmp4
    bcc @inc_store_fire
    lda #$FF
@inc_store_fire:
    sta cnt_fire
@inc_done:
    rts

; ------------------------------------------------------------
; decrement_count  (A = tile type)
; Decrement the appropriate building-count ZP variable (floor 0).
; ------------------------------------------------------------
decrement_count:
    sta tmp3
    and #TILE_TYPE_MASK
    tax
    lda tmp3
    jsr get_tile_density_units
    sta tmp4
    txa
    cmp #TILE_ROAD
    bne @dec1
    lda cnt_roads
    sec
    sbc tmp4
    bcs @dec_store_road
    lda #0
@dec_store_road:
    sta cnt_roads
    rts
@dec1:
    cmp #TILE_HOUSE
    bne @dec2
    lda cnt_houses
    sec
    sbc tmp4
    bcs @dec_store_house
    lda #0
@dec_store_house:
    sta cnt_houses
    rts
@dec2:
    cmp #TILE_FACTORY
    bne @dec3
    lda cnt_factories
    sec
    sbc tmp4
    bcs @dec_store_factory
    lda #0
@dec_store_factory:
    sta cnt_factories
    rts
@dec3:
    cmp #TILE_PARK
    bne @dec4
    lda cnt_parks
    sec
    sbc tmp4
    bcs @dec_store_park
    lda #0
@dec_store_park:
    sta cnt_parks
    rts
@dec4:
    cmp #TILE_POWER
    bne @dec5
    lda cnt_power
    sec
    sbc tmp4
    bcs @dec_store_power
    lda #0
@dec_store_power:
    sta cnt_power
    rts
@dec5:
    cmp #TILE_POLICE
    bne @dec6
    lda cnt_police
    sec
    sbc tmp4
    bcs @dec_store_police
    lda #0
@dec_store_police:
    sta cnt_police
    rts
@dec6:
    cmp #TILE_FIRE
    bne @dec_done
    lda cnt_fire
    sec
    sbc tmp4
    bcs @dec_store_fire
    lda #0
@dec_store_fire:
    sta cnt_fire
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
