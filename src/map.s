; ============================================================
; C64 City Builder - Map Data and Rendering
; Included by main.s.
; ============================================================

; ------------------------------------------------------------
; BSS: 800-byte city map (one byte per tile, row-major order)
; ------------------------------------------------------------
    .segment "BSS"
city_map:   .res MAP_SIZE       ; 40 × 20 = 800 bytes

; ============================================================
    .segment "CODE"

; ------------------------------------------------------------
; render_map
; Redraws the entire 40×20 map area (rows 0-19) on screen.
;
; Uses THREE zero-page pointers simultaneously:
;   ptr_lo/hi   → city_map source
;   ptr2_lo/hi  → SCREEN_BASE destination
;   tmp1/tmp2   → COLOR_BASE destination   (tmp2 = tmp1+1 in ZP)
;
; Processes 800 bytes in 3 full 256-byte pages + 32 remainder.
; ------------------------------------------------------------
render_map:
    lda #0
    sta tile_row
@rm_row:
    lda #0
    sta tile_col
@rm_col:
    lda tile_col
    sta tmp1
    lda tile_row
    sta tmp2
    jsr render_tile
    inc tile_col
    lda tile_col
    cmp #MAP_WIDTH
    bne @rm_col
    inc tile_row
    lda tile_row
    cmp #MAP_HEIGHT
    bne @rm_row
    lda #0
    sta dirty_map
    rts

; ------------------------------------------------------------
; render_tile
; Redraw a single tile at (tmp1=col, tmp2=row).
; Trashes A, X, Y, ptr_lo/hi, ptr2_lo/hi.
; ------------------------------------------------------------
render_tile:
    sei
    jsr update_cursor_aoe_state
    lda cursor_aoe_color
    sta VIC_BKG_CLR1

    ; Compute map byte offset = row*40 + col
    ldy tmp2
    lda mul40_lo,y
    clc
    adc tmp1
    sta ptr_lo
    lda mul40_hi,y
    adc #0
    sta ptr_hi          ; ptr = row*40 + col  (this is just the OFFSET)

    ; Read tile from city_map
    lda ptr_lo
    clc
    adc #<city_map
    sta ptr2_lo
    lda ptr_hi
    adc #>city_map
    sta ptr2_hi
    ldy #0
    lda (ptr2_lo),y     ; raw tile byte
    sta tmp3
    lda tmp1
    sta tile_col
    lda tmp2
    sta tile_row

    ; Write char to SCREEN_BASE + offset
    lda tmp3
    jsr get_tile_screen_char
    pha
    lda ptr_lo
    clc
    adc #<SCREEN_BASE
    sta ptr2_lo
    lda ptr_hi
    adc #>SCREEN_BASE
    sta ptr2_hi
    pla
    sta (ptr2_lo),y     ; Y still 0

    ; Write colour to COLOR_BASE + offset
    lda tmp3
    jsr get_tile_draw_color
    pha
    lda ptr_lo
    clc
    adc #<COLOR_BASE
    sta ptr2_lo
    lda ptr_hi
    adc #>COLOR_BASE
    sta ptr2_hi
    pla
    sta (ptr2_lo),y
    cli
    rts

; ------------------------------------------------------------
; render_road_neighborhood
; Redraw the tile at (tmp1,tmp2) and any adjacent road tiles so
; line junctions update immediately after road placement/removal.
; ------------------------------------------------------------
render_road_neighborhood:
    lda tmp1
    pha
    lda tmp2
    pha
    jsr render_tile
    pla
    sta tmp2
    pla
    sta tmp1

    lda tmp2
    beq @rrn_south
    lda tmp1
    pha
    lda tmp2
    pha
    dec tmp2
    lda tmp1
    ldx tmp2
    jsr get_tile
    and #TILE_TYPE_MASK
    cmp #TILE_ROAD
    bne @rrn_restore_north
    jsr render_tile
@rrn_restore_north:
    pla
    sta tmp2
    pla
    sta tmp1

@rrn_south:
    lda tmp2
    cmp #MAP_HEIGHT - 1
    beq @rrn_east
    lda tmp1
    pha
    lda tmp2
    pha
    inc tmp2
    lda tmp1
    ldx tmp2
    jsr get_tile
    and #TILE_TYPE_MASK
    cmp #TILE_ROAD
    bne @rrn_restore_south
    jsr render_tile
@rrn_restore_south:
    pla
    sta tmp2
    pla
    sta tmp1

@rrn_east:
    lda tmp1
    cmp #MAP_WIDTH - 1
    beq @rrn_west
    lda tmp1
    pha
    lda tmp2
    pha
    inc tmp1
    lda tmp1
    ldx tmp2
    jsr get_tile
    and #TILE_TYPE_MASK
    cmp #TILE_ROAD
    bne @rrn_restore_east
    jsr render_tile
@rrn_restore_east:
    pla
    sta tmp2
    pla
    sta tmp1

@rrn_west:
    lda tmp1
    beq @rrn_done
    lda tmp1
    pha
    lda tmp2
    pha
    dec tmp1
    lda tmp1
    ldx tmp2
    jsr get_tile
    and #TILE_TYPE_MASK
    cmp #TILE_ROAD
    bne @rrn_restore_west
    jsr render_tile
@rrn_restore_west:
    pla
    sta tmp2
    pla
    sta tmp1
@rrn_done:
    rts

; ------------------------------------------------------------
; get_tile_screen_char
; A = raw tile byte, returns the character to draw for the
; current tile. Roads are adjacency-aware.
; ------------------------------------------------------------
get_tile_screen_char:
    sta tmp3
    and #TILE_TYPE_MASK
    cmp #TILE_ROAD
    beq @gtsc_road
    tax
    lda tile_char,x
    sta tmp4
    jsr tile_in_cursor_aoe
    beq @gtsc_base
    lda tmp4
    clc
    adc #1
    rts
@gtsc_base:
    lda tmp4
    rts
@gtsc_road:
    jsr get_road_screen_char
    sta tmp4
    jsr tile_in_cursor_aoe
    beq @gtsc_base
    lda tmp4
    clc
    adc #16
    rts

; ------------------------------------------------------------
; get_road_screen_char
; Uses tile_col/tile_row to inspect adjacent road tiles and
; returns the matching PETSCII line-drawing character.
; ------------------------------------------------------------
get_road_screen_char:
    tya
    pha
    lda ptr_lo
    pha
    lda ptr_hi
    pha
    lda tmp3
    pha

    lda #0
    sta road_mask

    lda tile_row
    beq @grsc_south
    lda tile_col
    ldx tile_row
    dex
    jsr get_tile
    and #TILE_TYPE_MASK
    cmp #TILE_ROAD
    bne @grsc_south
    lda road_mask
    ora #$01
    sta road_mask

@grsc_south:
    lda tile_row
    cmp #MAP_HEIGHT - 1
    beq @grsc_east
    lda tile_col
    ldx tile_row
    inx
    jsr get_tile
    and #TILE_TYPE_MASK
    cmp #TILE_ROAD
    bne @grsc_east
    lda road_mask
    ora #$02
    sta road_mask

@grsc_east:
    lda tile_col
    cmp #MAP_WIDTH - 1
    beq @grsc_west
    clc
    adc #1
    ldx tile_row
    jsr get_tile
    and #TILE_TYPE_MASK
    cmp #TILE_ROAD
    bne @grsc_west
    lda road_mask
    ora #$04
    sta road_mask

@grsc_west:
    lda tile_col
    beq @grsc_lookup
    sec
    sbc #1
    ldx tile_row
    jsr get_tile
    and #TILE_TYPE_MASK
    cmp #TILE_ROAD
    bne @grsc_lookup
    lda road_mask
    ora #$08
    sta road_mask

@grsc_lookup:
    ldx road_mask
    lda road_shape_char,x
    tax
    pla
    sta tmp3
    pla
    sta ptr_hi
    pla
    sta ptr_lo
    pla
    tay
    txa
    rts

; ------------------------------------------------------------
; get_tile (col in A, row in X) → tile type in A
; ------------------------------------------------------------
get_tile:
    ; offset = row*40 + col
    sta tmp3            ; save col
    txa                 ; A = row
    tay                 ; Y = row (for table)
    lda mul40_lo,y
    clc
    adc tmp3            ; + col
    sta ptr_lo
    lda mul40_hi,y
    adc #0
    sta ptr_hi
    ; Add city_map base
    lda ptr_lo
    clc
    adc #<city_map
    sta ptr_lo
    lda ptr_hi
    adc #>city_map
    sta ptr_hi
    ldy #0
    lda (ptr_lo),y
    rts

; ------------------------------------------------------------
; set_tile (col in A, row in X, tile in Y)
; Writes tile Y into city_map at position (col, row).
; ------------------------------------------------------------
set_tile:
    sta tmp3            ; col
    txa                 ; row
    tax                 ; X = row
    tya                 ; A = tile (we'll push it)
    pha
    txa                 ; row back to A
    tay                 ; Y = row
    lda mul40_lo,y
    clc
    adc tmp3            ; + col
    sta ptr_lo
    lda mul40_hi,y
    adc #0
    sta ptr_hi
    lda ptr_lo
    clc
    adc #<city_map
    sta ptr_lo
    lda ptr_hi
    adc #>city_map
    sta ptr_hi
    pla                 ; tile type
    ldy #0
    sta (ptr_lo),y
    rts

; ------------------------------------------------------------
; update_cursor_display
; Move sprite 0 so its hollow box frames the selected map tile.
; ------------------------------------------------------------
update_cursor_display:
    lda #0
    sta tmp1

    lda cursor_x
    asl
    rol tmp1
    asl
    rol tmp1
    asl
    rol tmp1
    clc
    adc #CURSOR_SPR_X_BASE
    sta VIC_SPR0_X

    lda tmp1
    adc #0
    tax
    lda VIC_SPR_X_MSB
    and #$FE
    cpx #0
    beq @ucd_store_x
    ora #$01
@ucd_store_x:
    sta VIC_SPR_X_MSB

    lda cursor_y
    asl
    asl
    asl
    clc
    adc #CURSOR_SPR_Y_BASE
    sta VIC_SPR0_Y
    rts

; ------------------------------------------------------------
; update_cursor_aoe_state
; Cache the current cursor tile's AoE radius and highlight colour.
; Houses / factories use explicit per-level radius tables.
; ------------------------------------------------------------
update_cursor_aoe_state:
    lda #0
    sta cursor_aoe_radius
    sta cursor_aoe_active
    lda #COLOR_GREEN
    sta cursor_aoe_color

    lda cursor_x
    ldx cursor_y
    jsr get_tile
    sta tmp4
    jsr get_tile_highlight_color
    sta cursor_aoe_color

    lda tmp4
    and #TILE_TYPE_MASK
    cmp #TILE_HOUSE
    beq @ucao_house
    cmp #TILE_FACTORY
    beq @ucao_factory
    cmp #TILE_PARK
    beq @ucao_park
    cmp #TILE_POLICE
    beq @ucao_police
    cmp #TILE_FIRE
    beq @ucao_fire
    rts

@ucao_house:
    lda tmp4
    jsr get_tile_density_units
    tax
    lda house_aoe_radius,x
    bne @ucao_enable

@ucao_factory:
    lda tmp4
    jsr get_tile_density_units
    tax
    lda factory_aoe_radius,x
@ucao_enable:
    sta cursor_aoe_radius
    lda #1
    sta cursor_aoe_active
    rts

@ucao_park:
    lda #PARK_RADIUS
    bne @ucao_store
@ucao_police:
    lda #POLICE_RADIUS
    bne @ucao_store
@ucao_fire:
    lda #FIRE_RADIUS
@ucao_store:
    sta cursor_aoe_radius
    lda #1
    sta cursor_aoe_active
    rts

; ------------------------------------------------------------
; tile_in_cursor_aoe
; Returns A=1 when tile_col/tile_row lies inside the current
; cursor tile's highlighted AoE, otherwise A=0.
; ------------------------------------------------------------
tile_in_cursor_aoe:
    lda cursor_aoe_active
    bne @tica_dx
    lda #0
    rts

@tica_dx:
    lda tile_col
    sec
    sbc cursor_x
    bcs @tica_dx_abs
    eor #$FF
    clc
    adc #1
@tica_dx_abs:
    cmp cursor_aoe_radius
    bcc @tica_dy
    beq @tica_dy
    lda #0
    rts

@tica_dy:
    lda tile_row
    sec
    sbc cursor_y
    bcs @tica_dy_abs
    eor #$FF
    clc
    adc #1
@tica_dy_abs:
    cmp cursor_aoe_radius
    bcc @tica_yes
    beq @tica_yes
    lda #0
    rts

@tica_yes:
    lda #1
    rts

; ------------------------------------------------------------
; get_tile_draw_color
; A = raw tile byte, returns the tile's display colour for the
; current density level.
; ------------------------------------------------------------
get_tile_draw_color:
    sta tmp3
    and #TILE_TYPE_MASK
    tax
    cpx #TILE_ROAD
    bcc @gtdc_base
    cpx #TILE_FIRE + 1
    bcs @gtdc_base
    lda tmp3
    and #TILE_DENSITY_MASK
    lsr
    lsr
    lsr
    lsr
    clc
    adc tile_density_base,x
    tax
    lda density_mc_color,x
    rts
@gtdc_base:
    lda tile_mc_color,x
    rts

; ------------------------------------------------------------
; get_tile_highlight_color
; A = raw tile byte, returns the unflagged palette colour used
; for the AoE highlight background.
; ------------------------------------------------------------
get_tile_highlight_color:
    sta tmp3
    and #TILE_TYPE_MASK
    tax
    cpx #TILE_ROAD
    bcc @gthc_base
    cpx #TILE_FIRE + 1
    bcs @gthc_base
    lda tmp3
    and #TILE_DENSITY_MASK
    lsr
    lsr
    lsr
    lsr
    clc
    adc tile_density_base,x
    tax
    lda density_color,x
    rts
@gthc_base:
    lda tile_color,x
    rts

; ------------------------------------------------------------
; restore_cursor_color
; Restore the colour RAM byte under the cursor to the tile's base colour.
; ------------------------------------------------------------
restore_cursor_color:
    lda cursor_x
    ldx cursor_y
    jsr get_tile
    jsr get_tile_draw_color
    sta tmp4

    ldy cursor_y
    lda mul40_lo,y
    clc
    adc #<COLOR_BASE
    sta ptr_lo
    lda mul40_hi,y
    adc #>COLOR_BASE
    sta ptr_hi

    lda cursor_x
    clc
    adc ptr_lo
    sta ptr_lo
    bcc @rcc_no_carry
    inc ptr_hi
@rcc_no_carry:

    ldy #0
    lda tmp4
    sta (ptr_lo),y
    rts
