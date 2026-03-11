; ============================================================
; C64 City Builder - Map Data and Rendering
; Included by main.s.
; ============================================================

; ------------------------------------------------------------
; BSS: 800-byte city map (one byte per tile, row-major order)
; ------------------------------------------------------------
    .segment "BSS"
; Reserve storage for 40 × 20 = 800 bytes.
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
    lda #0 ; load 0 into A for current tile row
    sta tile_row ; store 0 into current tile row
; Continue with the row path.
; Branch target from @rm_col if the test did not match.
@rm_row:
    lda #0 ; load 0 into A for current tile column
    sta tile_col ; store 0 into current tile column
; Continue with the col path.
; Branch target from @rm_col if the test did not match.
@rm_col:
    lda tile_col ; load current tile column into A
    sta tmp1 ; store current tile column into temporary slot 1
    lda tile_row ; load current tile row into A
    sta tmp2 ; store current tile row into temporary slot 2
    jsr render_tile ; redraw this single tile
    inc tile_col ; advance to the next column
    lda tile_col ; load current tile column into A
    cmp #MAP_WIDTH ; check for the end of the row
    bne @rm_col ; if the test did not match, branch to col
    inc tile_row ; advance to the next row
    lda tile_row ; load current tile row into A
    cmp #MAP_HEIGHT ; check for the bottom of the map
    bne @rm_row ; if the test did not match, branch to row
    lda #0 ; prepare to mark the map as clean
    sta dirty_map ; mark the map as clean
    rts ; Return from subroutine

; ------------------------------------------------------------
; render_tile
; Redraw a single tile at (tmp1=col, tmp2=row).
; Trashes A, X, Y, ptr_lo/hi, ptr2_lo/hi.
; ------------------------------------------------------------
render_tile:
    sei ; temporarily disable IRQ handling
    jsr update_cursor_aoe_state ; recompute the cursor area highlight state
    lda cursor_aoe_color ; load cursor highlight color into A
    sta VIC_BKG_CLR1 ; store cursor highlight color into shared multicolor register 1

    ; Compute map byte offset = row*40 + col
    ldy tmp2 ; load temporary slot 2 into Y
    lda mul40_lo,y ; load precomputed row*40 lookup into A
    clc ; clear carry before the next add
    adc tmp1 ; add temporary slot 1 into A
    sta ptr_lo ; store A into primary pointer low byte
    lda mul40_hi,y ; load precomputed row*40 lookup into A
    adc #0 ; fold carry into the high byte
    sta ptr_hi          ; ptr = row*40 + col  (this is just the OFFSET)

    ; Read tile from city_map
    lda ptr_lo ; load primary pointer low byte into A
    clc ; clear carry before the next add
    adc #<city_map ; add city map buffer into A
    sta ptr2_lo ; store A into secondary pointer low byte
    lda ptr_hi ; load primary pointer high byte into A
    adc #>city_map ; add city map buffer into A
    sta ptr2_hi ; store A into secondary pointer high byte
    ldy #0 ; load 0 into Y
    lda (ptr2_lo),y     ; raw tile byte
    sta tmp3 ; store secondary pointer low byte into temporary slot 3
    lda tmp1 ; load temporary slot 1 into A
    sta tile_col ; store temporary slot 1 into current tile column
    lda tmp2 ; load temporary slot 2 into A
    sta tile_row ; store temporary slot 2 into current tile row

    ; Write char to SCREEN_BASE + 40 + offset (map starts on screen row 1)
    lda tmp3 ; load temporary slot 3 into A
    jsr get_tile_screen_char ; convert the tile into its screen glyph
    pha ; save A on the stack
    lda ptr_lo ; load primary pointer low byte into A
    clc ; clear carry before the next add
    adc #<(SCREEN_BASE + SCREEN_COLS) ; add (SCREEN BASE + SCREEN COLS into A
    sta ptr2_lo ; store A into secondary pointer low byte
    lda ptr_hi ; load primary pointer high byte into A
    adc #>(SCREEN_BASE + SCREEN_COLS) ; add (SCREEN BASE + SCREEN COLS into A
    sta ptr2_hi ; store A into secondary pointer high byte
    pla ; restore the saved A value
    sta (ptr2_lo),y     ; Y still 0

    ; Write colour to COLOR_BASE + 40 + offset
    lda tmp3 ; load temporary slot 3 into A
    jsr get_tile_draw_color ; choose the tile draw color
    pha ; save A on the stack
    lda ptr_lo ; load primary pointer low byte into A
    clc ; clear carry before the next add
    adc #<(COLOR_BASE + SCREEN_COLS) ; add (COLOR BASE + SCREEN COLS into A
    sta ptr2_lo ; store A into secondary pointer low byte
    lda ptr_hi ; load primary pointer high byte into A
    adc #>(COLOR_BASE + SCREEN_COLS) ; add (COLOR BASE + SCREEN COLS into A
    sta ptr2_hi ; store A into secondary pointer high byte
    pla ; restore the saved A value
    sta (ptr2_lo),y ; store A into secondary pointer low byte
    cli ; re-enable IRQ handling
    rts ; Return from subroutine

; ------------------------------------------------------------
    .export render_road_neighborhood
    .export render_road_neighborhood_exit
; render_road_neighborhood
; Redraw the tile at (tmp1,tmp2) and any adjacent road tiles so
; line junctions update immediately after road placement/removal.
; ------------------------------------------------------------
render_road_neighborhood:
    lda tmp1 ; load temporary slot 1 into A
    pha ; save A on the stack
    lda tmp2 ; load temporary slot 2 into A
    pha ; save A on the stack
    jsr render_tile ; redraw this single tile
    pla ; restore the saved A value
    sta tmp2 ; store A into temporary slot 2
    pla ; restore the saved A value
    sta tmp1 ; store A into temporary slot 1

    lda tmp2 ; load temporary slot 2 into A
    beq @rrn_south ; if the test matched, branch to south
    lda tmp1 ; load temporary slot 1 into A
    pha ; save A on the stack
    lda tmp2 ; load temporary slot 2 into A
    pha ; save A on the stack
    dec tmp2 ; step to the row above
    lda tmp1 ; load temporary slot 1 into A
    ldx tmp2 ; load temporary slot 2 into X
    jsr get_tile ; read the tile at the requested map coordinate
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_ROAD ; check for a road tile
    beq @rrn_render_north ; if the test matched, branch to render north
    cmp #TILE_BRIDGE ; check for a bridge tile
    bne @rrn_restore_north ; if the test did not match, branch to restore north
; Render north neighbor.
; Branch target from render_road_neighborhood if the test matched.
@rrn_render_north:
    jsr render_tile ; redraw this single tile
; Restore north neighbor.
; Branch target from render_road_neighborhood if the test did not match.
@rrn_restore_north:
    pla ; restore the saved A value
    sta tmp2 ; store A into temporary slot 2
    pla ; restore the saved A value
    sta tmp1 ; store A into temporary slot 1

; Continue with the south neighbor path.
; Branch target from render_road_neighborhood if the test matched.
@rrn_south:
    lda tmp2 ; load temporary slot 2 into A
    cmp #MAP_HEIGHT - 1 ; check whether we are already on the last row
    beq @rrn_east ; if the test matched, branch to east
    lda tmp1 ; load temporary slot 1 into A
    pha ; save A on the stack
    lda tmp2 ; load temporary slot 2 into A
    pha ; save A on the stack
    inc tmp2 ; increment temporary slot 2
    lda tmp1 ; load temporary slot 1 into A
    ldx tmp2 ; load temporary slot 2 into X
    jsr get_tile ; read the tile at the requested map coordinate
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_ROAD ; check for a road tile
    beq @rrn_render_south ; if the test matched, branch to render south
    cmp #TILE_BRIDGE ; check for a bridge tile
    bne @rrn_restore_south ; if the test did not match, branch to restore south
; Render south neighbor.
; Branch target from @rrn_south if the test matched.
@rrn_render_south:
    jsr render_tile ; redraw this single tile
; Restore south neighbor.
; Branch target from @rrn_south if the test did not match.
@rrn_restore_south:
    pla ; restore the saved A value
    sta tmp2 ; store A into temporary slot 2
    pla ; restore the saved A value
    sta tmp1 ; store A into temporary slot 1

; Continue with the east neighbor path.
; Branch target from @rrn_south if the test matched.
@rrn_east:
    lda tmp1 ; load temporary slot 1 into A
    cmp #MAP_WIDTH - 1 ; check whether we are already on the last column
    beq @rrn_west ; if the test matched, branch to west
    lda tmp1 ; load temporary slot 1 into A
    pha ; save A on the stack
    lda tmp2 ; load temporary slot 2 into A
    pha ; save A on the stack
    inc tmp1 ; increment temporary slot 1
    lda tmp1 ; load temporary slot 1 into A
    ldx tmp2 ; load temporary slot 2 into X
    jsr get_tile ; read the tile at the requested map coordinate
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_ROAD ; check for a road tile
    beq @rrn_render_east ; if the test matched, branch to render east
    cmp #TILE_BRIDGE ; check for a bridge tile
    bne @rrn_restore_east ; if the test did not match, branch to restore east
; Render east neighbor.
; Branch target from @rrn_east if the test matched.
@rrn_render_east:
    jsr render_tile ; redraw this single tile
; Restore east neighbor.
; Branch target from @rrn_east if the test did not match.
@rrn_restore_east:
    pla ; restore the saved A value
    sta tmp2 ; store A into temporary slot 2
    pla ; restore the saved A value
    sta tmp1 ; store A into temporary slot 1

; Continue with the west neighbor path.
; Branch target from @rrn_east if the test matched.
@rrn_west:
    lda tmp1 ; load temporary slot 1 into A
    beq @rrn_done ; if the test matched, branch to done
    lda tmp1 ; load temporary slot 1 into A
    pha ; save A on the stack
    lda tmp2 ; load temporary slot 2 into A
    pha ; save A on the stack
    dec tmp1 ; step to the column on the left
    lda tmp1 ; load temporary slot 1 into A
    ldx tmp2 ; load temporary slot 2 into X
    jsr get_tile ; read the tile at the requested map coordinate
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_ROAD ; check for a road tile
    beq @rrn_render_west ; if the test matched, branch to render west
    cmp #TILE_BRIDGE ; check for a bridge tile
    bne @rrn_restore_west ; if the test did not match, branch to restore west
; Render west neighbor.
; Branch target from @rrn_west if the test matched.
@rrn_render_west:
    jsr render_tile ; redraw this single tile
; Restore west neighbor.
; Branch target from @rrn_west if the test did not match.
@rrn_restore_west:
    pla ; restore the saved A value
    sta tmp2 ; store A into temporary slot 2
    pla ; restore the saved A value
    sta tmp1 ; store A into temporary slot 1
; Provide a stable exported label for leaving the road-neighborhood redraw routine.
render_road_neighborhood_exit:
; Finish this local path and fall back to the caller or shared exit.
; Branch target from @rrn_west if the test matched.
@rrn_done:
    rts ; Return from subroutine

; ------------------------------------------------------------
; get_tile_screen_char
; A = raw tile byte, returns the character to draw for the
; current tile. Roads are adjacency-aware.
; ------------------------------------------------------------
get_tile_screen_char:
    sta tmp3 ; store A into temporary slot 3
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_ROAD ; check for a road tile
    beq @gtsc_road ; if the test matched, branch to gtsc road
    cmp #TILE_BRIDGE ; check for a bridge tile
    beq @gtsc_road ; if the test matched, branch to gtsc road
    tax ; move A into X for the upcoming table lookup
    lda tile_char,x ; load tile char into A
    sta tmp4 ; store tile char into temporary slot 4
    jsr tile_in_cursor_aoe ; call tile in cursor aoe
    beq @gtsc_base ; if the test matched, branch to gtsc base
    lda tmp4 ; load temporary slot 4 into A
    clc ; clear carry before the next add
    adc #1 ; add 1 into A
    rts ; Return from subroutine
; Continue with the gtsc base path.
; Branch target from get_tile_screen_char if the test matched.
; Branch target from @gtsc_road if the test matched.
@gtsc_base:
    lda tmp4 ; load temporary slot 4 into A
    rts ; Return from subroutine
; Continue with the gtsc road path.
; Branch target from get_tile_screen_char if the test matched.
; Branch target from get_tile_screen_char if the test matched.
@gtsc_road:
    jsr get_road_screen_char ; call road screen char
    sta tmp4 ; store A into temporary slot 4
    jsr tile_in_cursor_aoe ; call tile in cursor aoe
    beq @gtsc_base ; if the test matched, branch to gtsc base
    lda tmp4 ; load temporary slot 4 into A
    clc ; clear carry before the next add
    adc #16 ; add 16 into A
    rts ; Return from subroutine

; ------------------------------------------------------------
; get_road_screen_char
; Uses tile_col/tile_row to inspect adjacent road tiles and
; returns the matching PETSCII line-drawing character.
; ------------------------------------------------------------
get_road_screen_char:
    tya ; move Y back into A
    pha ; save A on the stack
    lda ptr_lo ; load primary pointer low byte into A
    pha ; save A on the stack
    lda ptr_hi ; load primary pointer high byte into A
    pha ; save A on the stack
    lda tmp3 ; load temporary slot 3 into A
    pha ; save A on the stack

    lda #0 ; load 0 into A for road mask
    sta road_mask ; store 0 into road mask

    lda tile_row ; load current tile row into A
    beq @grsc_south ; if the test matched, branch to grsc south
    lda tile_col ; load current tile column into A
    ldx tile_row ; load current tile row into X
    dex ; step X back one slot
    jsr get_tile ; read the tile at the requested map coordinate
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_ROAD ; check for a road tile
    beq @grsc_north_yes ; if the test matched, branch to grsc north yes
    cmp #TILE_BRIDGE ; check for a bridge tile
    bne @grsc_south ; if the test did not match, branch to grsc south
; Continue with the grsc north neighbor yes path.
; Branch target from get_road_screen_char if the test matched.
@grsc_north_yes:
    lda road_mask ; load road mask into A
    ora #$01 ; set the bits from $01
    sta road_mask ; store A into road mask

; Continue with the grsc south neighbor path.
; Branch target from get_road_screen_char if the test matched.
; Branch target from get_road_screen_char if the test did not match.
@grsc_south:
    lda tile_row ; load current tile row into A
    cmp #MAP_HEIGHT - 1 ; check whether we are already on the last row
    beq @grsc_east ; if the test matched, branch to grsc east
    lda tile_col ; load current tile column into A
    ldx tile_row ; load current tile row into X
    inx ; advance X to the next index
    jsr get_tile ; read the tile at the requested map coordinate
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_ROAD ; check for a road tile
    beq @grsc_south_yes ; if the test matched, branch to grsc south yes
    cmp #TILE_BRIDGE ; check for a bridge tile
    bne @grsc_east ; if the test did not match, branch to grsc east
; Continue with the grsc south neighbor yes path.
; Branch target from @grsc_south if the test matched.
@grsc_south_yes:
    lda road_mask ; load road mask into A
    ora #$02 ; set the bits from $02
    sta road_mask ; store A into road mask

; Continue with the grsc east neighbor path.
; Branch target from @grsc_south if the test matched.
; Branch target from @grsc_south if the test did not match.
@grsc_east:
    lda tile_col ; load current tile column into A
    cmp #MAP_WIDTH - 1 ; check whether we are already on the last column
    beq @grsc_west ; if the test matched, branch to grsc west
    clc ; clear carry before the next add
    adc #1 ; add 1 into A
    ldx tile_row ; load current tile row into X
    jsr get_tile ; read the tile at the requested map coordinate
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_ROAD ; check for a road tile
    beq @grsc_east_yes ; if the test matched, branch to grsc east yes
    cmp #TILE_BRIDGE ; check for a bridge tile
    bne @grsc_west ; if the test did not match, branch to grsc west
; Continue with the grsc east neighbor yes path.
; Branch target from @grsc_east if the test matched.
@grsc_east_yes:
    lda road_mask ; load road mask into A
    ora #$04 ; set the bits from $04
    sta road_mask ; store A into road mask

; Continue with the grsc west neighbor path.
; Branch target from @grsc_east if the test matched.
; Branch target from @grsc_east if the test did not match.
@grsc_west:
    lda tile_col ; load current tile column into A
    beq @grsc_lookup ; if the test matched, branch to grsc lookup
    sec ; set carry before the subtract/compare sequence
    sbc #1 ; subtract 1 from A
    ldx tile_row ; load current tile row into X
    jsr get_tile ; read the tile at the requested map coordinate
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_ROAD ; check for a road tile
    beq @grsc_west_yes ; if the test matched, branch to grsc west yes
    cmp #TILE_BRIDGE ; check for a bridge tile
    bne @grsc_lookup ; if the test did not match, branch to grsc lookup
; Continue with the grsc west neighbor yes path.
; Branch target from @grsc_west if the test matched.
@grsc_west_yes:
    lda road_mask ; load road mask into A
    ora #$08 ; set the bits from $08
    sta road_mask ; store A into road mask

; Continue with the grsc lookup path.
; Branch target from @grsc_west if the test matched.
; Branch target from @grsc_west if the test did not match.
@grsc_lookup:
    ldx road_mask ; load road mask into X
    lda road_shape_char,x ; load road shape char into A
    tax ; move A into X for the upcoming table lookup
    pla ; restore the saved A value
    sta tmp3 ; store A into temporary slot 3
    pla ; restore the saved A value
    sta ptr_hi ; store A into primary pointer high byte
    pla ; restore the saved A value
    sta ptr_lo ; store A into primary pointer low byte
    pla ; restore the saved A value
    tay ; move A into Y for the upcoming indexed access
    txa ; move X back into A
    rts ; Return from subroutine

; ------------------------------------------------------------
; get_tile (col in A, row in X) → tile type in A
; ------------------------------------------------------------
get_tile:
    ; offset = row*40 + col
    sta tmp3            ; save col
    txa                 ; A = row
    tay                 ; Y = row (for table)
    lda mul40_lo,y ; load precomputed row*40 lookup into A
    clc ; clear carry before the next add
    adc tmp3            ; + col
    sta ptr_lo ; store A into primary pointer low byte
    lda mul40_hi,y ; load precomputed row*40 lookup into A
    adc #0 ; fold carry into the high byte
    sta ptr_hi ; store A into primary pointer high byte
    ; Add city_map base
    lda ptr_lo ; load primary pointer low byte into A
    clc ; clear carry before the next add
    adc #<city_map ; add city map buffer into A
    sta ptr_lo ; store A into primary pointer low byte
    lda ptr_hi ; load primary pointer high byte into A
    adc #>city_map ; add city map buffer into A
    sta ptr_hi ; store A into primary pointer high byte
    ldy #0 ; load 0 into Y
    lda (ptr_lo),y ; load primary pointer low byte into A
    rts ; Return from subroutine

; ------------------------------------------------------------
; set_tile (col in A, row in X, tile in Y)
; Writes tile Y into city_map at position (col, row).
; ------------------------------------------------------------
set_tile:
    sta tmp3            ; col
    txa                 ; row
    tax                 ; X = row
    tya                 ; A = tile (we'll push it)
    pha ; save A on the stack
    txa                 ; row back to A
    tay                 ; Y = row
    lda mul40_lo,y ; load precomputed row*40 lookup into A
    clc ; clear carry before the next add
    adc tmp3            ; + col
    sta ptr_lo ; store A into primary pointer low byte
    lda mul40_hi,y ; load precomputed row*40 lookup into A
    adc #0 ; fold carry into the high byte
    sta ptr_hi ; store A into primary pointer high byte
    lda ptr_lo ; load primary pointer low byte into A
    clc ; clear carry before the next add
    adc #<city_map ; add city map buffer into A
    sta ptr_lo ; store A into primary pointer low byte
    lda ptr_hi ; load primary pointer high byte into A
    adc #>city_map ; add city map buffer into A
    sta ptr_hi ; store A into primary pointer high byte
    pla                 ; tile type
    ldy #0 ; load 0 into Y for primary pointer low byte
    sta (ptr_lo),y ; store 0 into primary pointer low byte
    rts ; Return from subroutine

; ------------------------------------------------------------
; update_cursor_display
; Move sprite 0 so its hollow box frames the selected map tile.
; ------------------------------------------------------------
update_cursor_display:
    lda #0 ; load 0 into A for temporary slot 1
    sta tmp1 ; store 0 into temporary slot 1

    lda cursor_x ; load cursor column into A
    asl ; shift A left to multiply by two
    rol tmp1 ; rotate A left through carry
    asl ; shift A left to multiply by two
    rol tmp1 ; rotate A left through carry
    asl ; shift A left to multiply by two
    rol tmp1 ; rotate A left through carry
    clc ; clear carry before the next add
    adc #CURSOR_SPR_X_BASE ; add CURSOR SPR X BASE into A
    sta VIC_SPR0_X ; store A into VIC SPR0 X

    lda tmp1 ; load temporary slot 1 into A
    adc #0 ; fold carry into the high byte
    tax ; move A into X for the upcoming table lookup
    lda VIC_SPR_X_MSB ; load sprite X high-bit register into A
    and #$FE ; mask A with $FE
    cpx #0 ; 0
    beq @ucd_store_x ; if the test matched, branch to store x
    ora #$01 ; set the bits from $01
; Continue with the store x path.
; Branch target from update_cursor_display if the test matched.
@ucd_store_x:
    sta VIC_SPR_X_MSB ; store A into sprite X high-bit register

    lda cursor_y ; load cursor row into A
    asl ; shift A left to multiply by two
    asl ; shift A left to multiply by two
    asl ; shift A left to multiply by two
    clc ; clear carry before the next add
    adc #(CURSOR_SPR_Y_BASE + 8) ; add (CURSOR SPR Y BASE + 8 into A
    sta VIC_SPR0_Y ; store A into VIC SPR0 Y
    rts ; Return from subroutine

; ------------------------------------------------------------
; update_cursor_aoe_state
; Cache the current cursor tile's AoE radius and highlight colour.
; Houses / factories use explicit per-level radius tables.
; ------------------------------------------------------------
update_cursor_aoe_state:
    lda #0 ; load 0 into A for cursor area radius
    sta cursor_aoe_radius ; store 0 into cursor area radius
    sta cursor_aoe_active ; store A into cursor area flag
    lda #COLOR_GREEN ; load green into A for cursor highlight color
    sta cursor_aoe_color ; store green into cursor highlight color

    lda cursor_x ; load cursor column into A
    ldx cursor_y ; load cursor row into X
    jsr get_tile ; read the tile at the requested map coordinate
    sta tmp4 ; store A into temporary slot 4
    jsr get_tile_highlight_color ; call tile highlight color
    sta cursor_aoe_color ; store A into cursor highlight color

    lda tmp4 ; load temporary slot 4 into A
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_HOUSE ; house tile type
    beq @ucao_house ; if the test matched, branch to ucao house
    cmp #TILE_FACTORY ; factory tile type
    beq @ucao_factory ; if the test matched, branch to ucao factory
    cmp #TILE_PARK ; park tile type
    beq @ucao_park ; if the test matched, branch to ucao park
    cmp #TILE_POLICE ; police tile type
    beq @ucao_police ; if the test matched, branch to ucao police
    cmp #TILE_FIRE ; fire-station tile type
    beq @ucao_fire ; if the test matched, branch to ucao fire
    rts ; Return from subroutine

; Continue with the ucao house path.
; Branch target from update_cursor_aoe_state if the test matched.
@ucao_house:
    lda tmp4 ; load temporary slot 4 into A
    jsr get_tile_density_units ; call tile density units
    tax ; move A into X for the upcoming table lookup
    lda house_aoe_radius,x ; load house aoe radius into A
    bne @ucao_enable ; if the test did not match, branch to ucao enable

; Continue with the ucao factory path.
; Branch target from update_cursor_aoe_state if the test matched.
@ucao_factory:
    lda tmp4 ; load temporary slot 4 into A
    jsr get_tile_density_units ; call tile density units
    tax ; move A into X for the upcoming table lookup
    lda factory_aoe_radius,x ; load factory aoe radius into A
; Continue with the ucao enable path.
; Branch target from @ucao_house if the test did not match.
@ucao_enable:
    sta cursor_aoe_radius ; store factory aoe radius into cursor area radius
    lda #1 ; enable the cursor area-highlight flag
    sta cursor_aoe_active ; enable the cursor area-highlight flag
    rts ; Return from subroutine

; Continue with the ucao park path.
; Branch target from update_cursor_aoe_state if the test matched.
@ucao_park:
    lda #PARK_RADIUS ; load PARK RADIUS into A
    bne @ucao_store ; if the test did not match, branch to ucao store
; Continue with the ucao police path.
; Branch target from update_cursor_aoe_state if the test matched.
@ucao_police:
    lda #POLICE_RADIUS ; load POLICE RADIUS into A
    bne @ucao_store ; if the test did not match, branch to ucao store
; Continue with the ucao fire path.
; Branch target from update_cursor_aoe_state if the test matched.
@ucao_fire:
    lda #FIRE_RADIUS ; load FIRE RADIUS into A for cursor area radius
; Continue with the ucao store path.
; Branch target from @ucao_park if the test did not match.
; Branch target from @ucao_police if the test did not match.
@ucao_store:
    sta cursor_aoe_radius ; store FIRE RADIUS into cursor area radius
    lda #1 ; enable the cursor area-highlight flag
    sta cursor_aoe_active ; enable the cursor area-highlight flag
    rts ; Return from subroutine

; ------------------------------------------------------------
; tile_in_cursor_aoe
; Returns A=1 when tile_col/tile_row lies inside the current
; cursor tile's highlighted AoE, otherwise A=0.
; ------------------------------------------------------------
tile_in_cursor_aoe:
    lda cursor_aoe_active ; load cursor area flag into A
    bne @tica_dx ; if the test did not match, branch to tica dx
    lda #0 ; load 0 into A
    rts ; Return from subroutine

; Continue with the tica dx path.
; Branch target from tile_in_cursor_aoe if the test did not match.
@tica_dx:
    lda tile_col ; load current tile column into A
    sec ; set carry before the subtract/compare sequence
    sbc cursor_x ; subtract cursor column from A
    bcs @tica_dx_abs ; if carry was set, branch to tica dx abs
    eor #$FF ; Exclusive-OR A with operand; immediate mode #$FF
    clc ; clear carry before the next add
    adc #1 ; add 1 into A
; Continue with the tica dx abs path.
; Branch target from @tica_dx if carry was set.
@tica_dx_abs:
    cmp cursor_aoe_radius ; cursor area radius
    bcc @tica_dy ; if carry stayed clear, branch to tica dy
    beq @tica_dy ; if the test matched, branch to tica dy
    lda #0 ; load 0 into A
    rts ; Return from subroutine

; Continue with the tica dy path.
; Branch target from @tica_dx_abs if carry stayed clear.
; Branch target from @tica_dx_abs if the test matched.
@tica_dy:
    lda tile_row ; load current tile row into A
    sec ; set carry before the subtract/compare sequence
    sbc cursor_y ; subtract cursor row from A
    bcs @tica_dy_abs ; if carry was set, branch to tica dy abs
    eor #$FF ; Exclusive-OR A with operand; immediate mode #$FF
    clc ; clear carry before the next add
    adc #1 ; add 1 into A
; Continue with the tica dy abs path.
; Branch target from @tica_dy if carry was set.
@tica_dy_abs:
    cmp cursor_aoe_radius ; cursor area radius
    bcc @tica_yes ; if carry stayed clear, branch to tica yes
    beq @tica_yes ; if the test matched, branch to tica yes
    lda #0 ; load 0 into A
    rts ; Return from subroutine

; Continue with the tica yes path.
; Branch target from @tica_dy_abs if carry stayed clear.
; Branch target from @tica_dy_abs if the test matched.
@tica_yes:
    lda #1 ; load 1 into A
    rts ; Return from subroutine

; ------------------------------------------------------------
; get_tile_draw_color
; A = raw tile byte, returns the tile's display colour for the
; current density level.
; ------------------------------------------------------------
get_tile_draw_color:
    sta tmp3 ; store A into temporary slot 3
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    tax ; move A into X for the upcoming table lookup
    cpx #TILE_ROAD ; check for a road tile
    bcc @gtdc_base ; if carry stayed clear, branch to gtdc base
    cpx #TILE_BRIDGE + 1 ; TILE BRIDGE + 1
    bcs @gtdc_base ; if carry was set, branch to gtdc base
    lda tmp3 ; load temporary slot 3 into A
    and #TILE_DENSITY_MASK ; keep only the density bits
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    clc ; clear carry before the next add
    adc tile_density_base,x ; add tile density base into A
    tax ; move A into X for the upcoming table lookup
    lda density_mc_color,x ; load density mc color into A
    rts ; Return from subroutine
; Continue with the gtdc base path.
; Branch target from get_tile_draw_color if carry stayed clear.
; Branch target from get_tile_draw_color if carry was set.
@gtdc_base:
    lda tile_mc_color,x ; load tile mc color into A
    rts ; Return from subroutine

; ------------------------------------------------------------
; get_tile_highlight_color
; A = raw tile byte, returns the unflagged palette colour used
; for the AoE highlight background.
; ------------------------------------------------------------
get_tile_highlight_color:
    sta tmp3 ; store A into temporary slot 3
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    tax ; move A into X for the upcoming table lookup
    cpx #TILE_ROAD ; check for a road tile
    bcc @gthc_base ; if carry stayed clear, branch to gthc base
    cpx #TILE_BRIDGE + 1 ; TILE BRIDGE + 1
    bcs @gthc_base ; if carry was set, branch to gthc base
    lda tmp3 ; load temporary slot 3 into A
    and #TILE_DENSITY_MASK ; keep only the density bits
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    clc ; clear carry before the next add
    adc tile_density_base,x ; add tile density base into A
    tax ; move A into X for the upcoming table lookup
    lda density_color,x ; load density color into A
    rts ; Return from subroutine
; Continue with the gthc base path.
; Branch target from get_tile_highlight_color if carry stayed clear.
; Branch target from get_tile_highlight_color if carry was set.
@gthc_base:
    lda tile_color,x ; load tile color into A
    rts ; Return from subroutine

; ------------------------------------------------------------
; restore_cursor_color
; Restore the colour RAM byte under the cursor to the tile's base colour.
; ------------------------------------------------------------
restore_cursor_color:
    lda cursor_x ; load cursor column into A
    ldx cursor_y ; load cursor row into X
    jsr get_tile ; read the tile at the requested map coordinate
    jsr get_tile_draw_color ; choose the tile draw color
    sta tmp4 ; store A into temporary slot 4

    ldy cursor_y ; load cursor row into Y
    lda mul40_lo,y ; load precomputed row*40 lookup into A
    clc ; clear carry before the next add
    adc #<(COLOR_BASE + SCREEN_COLS) ; add (COLOR BASE + SCREEN COLS into A
    sta ptr_lo ; store A into primary pointer low byte
    lda mul40_hi,y ; load precomputed row*40 lookup into A
    adc #>(COLOR_BASE + SCREEN_COLS) ; add (COLOR BASE + SCREEN COLS into A
    sta ptr_hi ; store A into primary pointer high byte

    lda cursor_x ; load cursor column into A
    clc ; clear carry before the next add
    adc ptr_lo ; add primary pointer low byte into A
    sta ptr_lo ; store A into primary pointer low byte
    bcc @rcc_no_carry ; if carry stayed clear, branch to no carry
    inc ptr_hi ; advance the primary pointer to the next page
; Continue with the no carry path.
; Branch target from restore_cursor_color if carry stayed clear.
@rcc_no_carry:

    ldy #0 ; load 0 into Y
    lda tmp4 ; load temporary slot 4 into A
    sta (ptr_lo),y ; store temporary slot 4 into primary pointer low byte
    rts ; Return from subroutine
