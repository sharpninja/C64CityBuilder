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
    lda sel_building ; load selected building type into A
    bne @tp_sel_ok ; if the test did not match, branch to sel ok
    rts                     ; 0 = nothing selected
; Handle the ok.
; Branch target from try_place_building if the test did not match.
@tp_sel_ok:
    ; Read the current tile once so we can detect upgrades and density caps.
    lda cursor_x ; load cursor column into A
    ldx cursor_y ; load cursor row into X
    jsr get_tile ; read the tile at the requested map coordinate
    sta tmp4                ; raw tile byte
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    sta tmp3                ; current base tile type
    lda sel_building ; load selected building type into A
    cmp #TILE_ROAD ; check for a road tile
    bne @tp_check_same ; if the test did not match, branch to check same
    lda tmp3 ; load temporary slot 3 into A
    cmp #TILE_BRIDGE ; check for a bridge tile
    beq @tp_upgrade_density ; if the test matched, branch to upgrade density
; Check same.
; Branch target from @tp_sel_ok if the test did not match.
@tp_check_same:
    lda tmp3 ; load temporary slot 3 into A
    cmp sel_building ; selected building type
    beq @tp_upgrade_density ; if the test matched, branch to upgrade density

    ; Water can only hold roads/bridges. Trees remain unbuildable.
    cmp #TILE_WATER ; check for water
    bne @tp_not_water ; if the test did not match, branch to not water
    lda sel_building ; load selected building type into A
    cmp #TILE_ROAD ; check for a road tile
    bne @tp_cant_build ; if the test did not match, branch to cant build
    jmp @tp_check_cost ; continue at check cost
; Continue with the not water path.
; Branch target from @tp_check_same if the test did not match.
@tp_not_water:
    cmp #TILE_BRIDGE ; check for a bridge tile
    bne @tp_not_bridge ; if the test did not match, branch to not bridge
    lda sel_building ; load selected building type into A
    cmp #TILE_ROAD ; check for a road tile
    bne @tp_cant_build ; if the test did not match, branch to cant build
    jmp @tp_check_cost ; continue at check cost
; Continue with the not bridge path.
; Branch target from @tp_not_water if the test did not match.
@tp_not_bridge:
    cmp #TILE_TREE ; check for an unbuildable tree tile
    beq @tp_cant_build ; if the test matched, branch to cant build

; Continue with the upgrade density path.
; Branch target from @tp_sel_ok if the test matched.
; Branch target from @tp_check_same if the test matched.
@tp_upgrade_density:
    lda tmp4 ; load temporary slot 4 into A
    and #TILE_DENSITY_MASK ; keep only the density bits
    cmp #TILE_MAX_DENSITY ; check whether density is already maxed out
    beq @tp_max_density ; if the test matched, branch to max density

; Check cost.
@tp_check_cost:
    ; 16-bit: money - cost; negative result → not enough
    lda sel_building ; load selected building type into A
    cmp #TILE_ROAD ; check for a road tile
    bne @tp_cost_ready ; if the test did not match, branch to cost ready
    lda tmp3 ; load temporary slot 3 into A
    cmp #TILE_WATER ; check for water
    beq @tp_cost_bridge ; if the test matched, branch to cost bridge
    cmp #TILE_BRIDGE ; check for a bridge tile
    bne @tp_cost_ready ; if the test did not match, branch to cost ready
; Handle the bridge.
; Branch target from @tp_check_cost if the test matched.
@tp_cost_bridge:
    lda #TILE_BRIDGE ; load check for a bridge tile into A
; Handle the ready.
; Branch target from @tp_check_cost if the test did not match.
; Branch target from @tp_check_cost if the test did not match.
@tp_cost_ready:
    tax ; move A into X for the upcoming table lookup
    lda bld_cost_lo,x ; load cost lo into A
    sta tmp1 ; store cost lo into temporary slot 1
    lda bld_cost_hi,x ; load cost hi into A
    sta tmp2 ; store cost hi into temporary slot 2

    lda money_lo ; load cash low byte into A
    sec ; set carry before the subtract/compare sequence
    sbc tmp1 ; subtract temporary slot 1 from A
    sta tmp1            ; result lo
    lda money_hi ; load cash high byte into A
    sbc tmp2 ; subtract temporary slot 2 from A
    bpl @tp_afford      ; high byte >= 0 → affordable

    ; Not enough cash
    lda #<str_msg_notenough ; load notenough string into A for primary pointer low byte
    sta ptr_lo ; store notenough string into primary pointer low byte
    lda #>str_msg_notenough ; load notenough string into A for primary pointer high byte
    sta ptr_hi ; store notenough string into primary pointer high byte
    ldx #0 ; load 0 into X
    ldy #UI_ROW_MSG ; load message row into Y
    lda #COLOR_LTRED ; load light red into A
    jsr print_str_col ; draw the prepared string at the requested position
    lda #90 ; load 90 into A for message timer
    sta msg_timer ; store 90 into message timer
    lda #1 ; prepare to mark the UI as needing a redraw
    sta dirty_ui ; mark the UI as needing a redraw
    rts ; Return from subroutine

; Continue with the cant build path.
; Branch target from @tp_check_same if the test did not match.
; Branch target from @tp_not_water if the test did not match.
; Branch target from @tp_not_bridge if the test matched.
@tp_cant_build:
    ; Show can't-build message
    lda #<str_msg_cantbuild ; load cantbuild string into A for primary pointer low byte
    sta ptr_lo ; store cantbuild string into primary pointer low byte
    lda #>str_msg_cantbuild ; load cantbuild string into A for primary pointer high byte
    sta ptr_hi ; store cantbuild string into primary pointer high byte
    ldx #0 ; load 0 into X
    ldy #UI_ROW_MSG ; load message row into Y
    lda #COLOR_ORANGE ; load orange into A
    jsr print_str_col ; draw the prepared string at the requested position
    lda #90 ; load 90 into A for message timer
    sta msg_timer ; store 90 into message timer
    lda #1 ; prepare to mark the UI as needing a redraw
    sta dirty_ui ; mark the UI as needing a redraw
    rts ; Return from subroutine

; Continue with the max density path.
; Branch target from @tp_upgrade_density if the test matched.
@tp_max_density:
    lda #<str_msg_maxdense ; load maxdense string into A for primary pointer low byte
    sta ptr_lo ; store maxdense string into primary pointer low byte
    lda #>str_msg_maxdense ; load maxdense string into A for primary pointer high byte
    sta ptr_hi ; store maxdense string into primary pointer high byte
    ldx #0 ; load 0 into X
    ldy #UI_ROW_MSG ; load message row into Y
    lda #COLOR_ORANGE ; load orange into A
    jsr print_str_col ; draw the prepared string at the requested position
    lda #90 ; load 90 into A for message timer
    sta msg_timer ; store 90 into message timer
    lda #1 ; prepare to mark the UI as needing a redraw
    sta dirty_ui ; mark the UI as needing a redraw
    rts ; Return from subroutine

; Continue once the current action is affordable.
; Branch target from @tp_cost_ready when high byte >= 0 → affordable.
@tp_afford:
    sta money_hi ; store A into cash high byte
    lda tmp1 ; load temporary slot 1 into A
    sta money_lo ; store temporary slot 1 into cash low byte

    lda cursor_x ; load cursor column into A
    sta tmp1 ; store cursor column into temporary slot 1
    lda cursor_y ; load cursor row into A
    sta tmp2 ; store cursor row into temporary slot 2

    lda tmp3 ; load temporary slot 3 into A
    cmp sel_building ; selected building type
    beq @tp_make_upgrade ; if the test matched, branch to make upgrade
    lda sel_building ; load selected building type into A
    cmp #TILE_ROAD ; check for a road tile
    bne @tp_new_tile ; if the test did not match, branch to new tile
    lda tmp3 ; load temporary slot 3 into A
    cmp #TILE_WATER ; check for water
    beq @tp_new_bridge ; if the test matched, branch to new bridge
    cmp #TILE_BRIDGE ; check for a bridge tile
    bne @tp_new_tile ; if the test did not match, branch to new tile
; Continue with the new bridge path.
; Branch target from @tp_afford if the test matched.
@tp_new_bridge:
    lda #TILE_BRIDGE ; load check for a bridge tile into A
    bne @tp_place_new ; if the test did not match, branch to place new
; Continue with the new tile path.
; Branch target from @tp_afford if the test did not match.
; Branch target from @tp_afford if the test did not match.
@tp_new_tile:
    lda #0 ; load 0 into A
    pha ; save A on the stack
    lda sel_building ; load selected building type into A
; Continue with the place new path.
; Branch target from @tp_new_bridge if the test did not match.
@tp_place_new:
    bne @tp_place_tile ; if the test did not match, branch to place tile
; Continue with the make upgrade path.
; Branch target from @tp_afford if the test matched.
@tp_make_upgrade:
    lda #1 ; load 1 into A
    pha ; save A on the stack
    lda tmp4 ; load temporary slot 4 into A
    clc ; clear carry before the next add
    adc #TILE_DENSITY_STEP ; add one density upgrade step into A
; Continue with the place tile path.
; Branch target from @tp_place_new if the test did not match.
@tp_place_tile:
    jsr place_tile_at ; write the new tile and update redraw bookkeeping
    pla ; restore the saved A value
    bne @tp_msg_upgraded ; if the test did not match, branch to msg upgraded

    lda #<str_msg_placed ; load placed string into A for primary pointer low byte
    sta ptr_lo ; store placed string into primary pointer low byte
    lda #>str_msg_placed ; load placed string into A for primary pointer high byte
    sta ptr_hi ; store placed string into primary pointer high byte
    bne @tp_show_msg ; if the test did not match, branch to show msg
; Prepare the upgraded.
; Branch target from @tp_place_tile if the test did not match.
@tp_msg_upgraded:
    lda #<str_msg_upgraded ; load upgraded string into A for primary pointer low byte
    sta ptr_lo ; store upgraded string into primary pointer low byte
    lda #>str_msg_upgraded ; load upgraded string into A for primary pointer high byte
    sta ptr_hi ; store upgraded string into primary pointer high byte
; Show message.
; Branch target from @tp_place_tile if the test did not match.
@tp_show_msg:
    ldx #0 ; load 0 into X
    ldy #UI_ROW_MSG ; load message row into Y
    lda #COLOR_LTGREEN ; load light green into A
    jsr print_str_col ; draw the prepared string at the requested position
    lda #90 ; load 90 into A for message timer
    sta msg_timer ; store 90 into message timer
    lda #1 ; prepare to mark the UI as needing a redraw
    sta dirty_ui ; mark the UI as needing a redraw
    rts ; Return from subroutine

; ------------------------------------------------------------
; try_demolish
; Remove the building under the cursor; replace with TILE_EMPTY.
; ------------------------------------------------------------
try_demolish:
    lda cursor_x ; load cursor column into A
    ldx cursor_y ; load cursor row into X
    jsr get_tile ; read the tile at the requested map coordinate
    sta tmp4                ; raw tile byte
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_EMPTY ; check for empty land
    bne @td_do_it ; if the test did not match, branch to do it
    rts                     ; already empty
; Continue with the do it path.
; Branch target from try_demolish if the test did not match.
@td_do_it:
    lda tmp4 ; load temporary slot 4 into A
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_ROAD ; check for a road tile
    bcc @td_clear_tile ; if carry stayed clear, branch to clear tile
    cmp #TILE_BRIDGE + 1 ; TILE BRIDGE + 1
    bcs @td_clear_tile ; if carry was set, branch to clear tile
    lda tmp4 ; load temporary slot 4 into A
    and #TILE_DENSITY_MASK ; keep only the density bits
    beq @td_clear_tile ; if the test matched, branch to clear tile
    lda tmp4 ; load temporary slot 4 into A
    sec ; set carry before the subtract/compare sequence
    sbc #TILE_DENSITY_STEP ; subtract one density upgrade step from A
    sta tmp3 ; store A into temporary slot 3
    lda #1 ; load 1 into A
    pha ; save A on the stack
    bne @td_place ; if the test did not match, branch to place
; Continue with the clear tile path.
; Branch target from @td_do_it if carry stayed clear.
; Branch target from @td_do_it if carry was set.
; Branch target from @td_do_it if the test matched.
@td_clear_tile:
    lda tmp4 ; load temporary slot 4 into A
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_BRIDGE ; check for a bridge tile
    bne @td_clear_empty ; if the test did not match, branch to clear empty
    lda #TILE_WATER ; load check for water into A
    bne @td_store_clear ; if the test did not match, branch to store clear
; Continue with the clear empty path.
; Branch target from @td_clear_tile if the test did not match.
@td_clear_empty:
    lda #TILE_EMPTY ; load check for empty land into A for temporary slot 3
; Continue with the store clear path.
; Branch target from @td_clear_tile if the test did not match.
@td_store_clear:
    sta tmp3 ; store check for empty land into temporary slot 3
    lda #0 ; load 0 into A
    pha ; save A on the stack
; Continue with the place path.
; Branch target from @td_do_it if the test did not match.
@td_place:

    lda cursor_x ; load cursor column into A
    sta tmp1 ; store cursor column into temporary slot 1
    lda cursor_y ; load cursor row into A
    sta tmp2 ; store cursor row into temporary slot 2
    lda tmp3 ; load temporary slot 3 into A
    jsr place_tile_at ; write the new tile and update redraw bookkeeping

    pla ; restore the saved A value
    beq @td_msg_demo ; if the test matched, branch to msg demo
    lda #<str_msg_downgraded ; load downgraded string into A for primary pointer low byte
    sta ptr_lo ; store downgraded string into primary pointer low byte
    lda #>str_msg_downgraded ; load downgraded string into A for primary pointer high byte
    sta ptr_hi ; store downgraded string into primary pointer high byte
    bne @td_show_msg ; if the test did not match, branch to show msg
; Prepare the demolition.
; Branch target from @td_place if the test matched.
@td_msg_demo:
    lda #<str_msg_demolished ; load demolished string into A for primary pointer low byte
    sta ptr_lo ; store demolished string into primary pointer low byte
    lda #>str_msg_demolished ; load demolished string into A for primary pointer high byte
    sta ptr_hi ; store demolished string into primary pointer high byte
; Show message.
; Branch target from @td_place if the test did not match.
@td_show_msg:
    ldx #0 ; load 0 into X
    ldy #UI_ROW_MSG ; load message row into Y
    lda #COLOR_MDGRAY ; load COLOR MDGRAY into A
    jsr print_str_col ; draw the prepared string at the requested position
    lda #60 ; load 60 into A for message timer
    sta msg_timer ; store 60 into message timer
    lda #1 ; prepare to mark the UI as needing a redraw
    sta dirty_ui ; mark the UI as needing a redraw
    rts ; Return from subroutine

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
    lda tmp1 ; load temporary slot 1 into A
    ldx tmp2 ; load temporary slot 2 into X
    jsr get_tile            ; A = old tile type (uses tmp3 internally)
    pha ; save A on the stack
    jsr decrement_count ; call decrement count

    pla ; restore the saved A value
    sta tmp3                ; tmp3 = old raw tile
    pla ; restore the saved A value
    sta tmp4                ; tmp4 = new raw tile

    lda #0 ; prepare to mark road topology as up to date
    sta road_topology_dirty ; mark road topology as up to date
    sta road_mask ; store A into road mask

    lda tmp3 ; load temporary slot 3 into A
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_ROAD ; check for a road tile
    beq @pta_old_road ; if the test matched, branch to old road
    cmp #TILE_BRIDGE ; check for a bridge tile
    bne @pta_old_done ; if the test did not match, branch to old done
; Continue with the old road path.
; Branch target from place_tile_at if the test matched.
@pta_old_road:
    lda #1 ; prepare to mark road topology as dirty
    sta road_topology_dirty ; mark road topology as dirty
; Continue with the old completion path.
; Branch target from place_tile_at if the test did not match.
@pta_old_done:
    lda tmp4 ; load temporary slot 4 into A
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_ROAD ; check for a road tile
    beq @pta_new_road ; if the test matched, branch to new road
    cmp #TILE_BRIDGE ; check for a bridge tile
    bne @pta_compare ; if the test did not match, branch to compare
; Continue with the new road path.
; Branch target from @pta_old_done if the test matched.
@pta_new_road:
    lda #1 ; load 1 into A for road mask
    sta road_mask ; store 1 into road mask
; Continue with the compare path.
; Branch target from @pta_old_done if the test did not match.
@pta_compare:
    lda road_topology_dirty ; load road topology dirty flag into A
    cmp road_mask ; road mask
    bne @pta_topology_changed ; if the test did not match, branch to topology changed
    lda #0 ; prepare to mark road topology as up to date
    sta road_topology_dirty ; mark road topology as up to date
    beq @pta_write ; if the test matched, branch to write
; Continue with the topology changed path.
; Branch target from @pta_compare if the test did not match.
@pta_topology_changed:
    lda #1 ; prepare to mark road topology as dirty
    sta road_topology_dirty ; mark road topology as dirty

; Continue with the write path.
; Branch target from @pta_compare if the test matched.
@pta_write:
    tay                     ; Y = new tile
    lda tmp1                ; A = col
    ldx tmp2                ; X = row
    jsr set_tile ; call tile

    ; Increment count for the NEW tile
    lda tmp4 ; load temporary slot 4 into A
    jsr increment_count ; call increment count

    ; Redraw the changed tile and any adjacent roads so road
    ; junction glyphs stay in sync with the map.
    jsr render_road_neighborhood ; refresh the road and its neighbors
    lda road_topology_dirty ; load road topology dirty flag into A
    beq @pta_update_one ; if the test matched, branch to update one
    jsr rebuild_road_segments ; call rebuild road segments
    jmp @pta_done ; continue at done

; Continue with the update one path.
; Branch target from @pta_write if the test matched.
@pta_update_one:
    jsr update_building_segment_at ; call update building segment at
; Finish this local path and fall back to the caller or shared exit.
@pta_done:
    lda #1 ; prepare to mark the map as needing a redraw
    sta dirty_map ; mark the map as needing a redraw

    rts ; Return from subroutine

; ------------------------------------------------------------
; increment_count  (A = tile type)
; Increment the appropriate building-count ZP variable.
; ------------------------------------------------------------
get_tile_density_units:
    and #TILE_DENSITY_MASK ; keep only the density bits
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    clc ; clear carry before the next add
    adc #1 ; add 1 into A
    rts ; Return from subroutine

; Enter the increment count routine.
increment_count:
    sta tmp3 ; store A into temporary slot 3
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    tax ; move A into X for the upcoming table lookup
    lda tmp3 ; load temporary slot 3 into A
    jsr get_tile_density_units ; call tile density units
    sta tmp4 ; store A into temporary slot 4
    txa ; move X back into A
    cmp #TILE_ROAD ; check for a road tile
    beq @inc_road ; if the test matched, branch to road
    cmp #TILE_BRIDGE ; check for a bridge tile
    bne @inc1 ; if the test did not match, branch to inc1
; Continue with the road path.
; Branch target from increment_count if the test matched.
@inc_road:
    lda cnt_roads ; load roads into A
    clc ; clear carry before the next add
    adc tmp4 ; add temporary slot 4 into A
    bcc @inc_store_road ; if carry stayed clear, branch to store road
    lda #$FF ; load $FF into A for roads
; Continue with the store road path.
; Branch target from @inc_road if carry stayed clear.
@inc_store_road:
    sta cnt_roads ; store $FF into roads
    rts ; Return from subroutine
; Continue with the inc1 path.
; Branch target from increment_count if the test did not match.
@inc1:
    cmp #TILE_HOUSE ; house tile type
    bne @inc2 ; if the test did not match, branch to inc2
    lda cnt_houses ; load houses into A
    clc ; clear carry before the next add
    adc tmp4 ; add temporary slot 4 into A
    bcc @inc_store_house ; if carry stayed clear, branch to store house
    lda #$FF ; load $FF into A for houses
; Continue with the store house path.
; Branch target from @inc1 if carry stayed clear.
@inc_store_house:
    sta cnt_houses ; store $FF into houses
    rts ; Return from subroutine
; Continue with the inc2 path.
; Branch target from @inc1 if the test did not match.
@inc2:
    cmp #TILE_FACTORY ; factory tile type
    bne @inc3 ; if the test did not match, branch to inc3
    lda cnt_factories ; load factories into A
    clc ; clear carry before the next add
    adc tmp4 ; add temporary slot 4 into A
    bcc @inc_store_factory ; if carry stayed clear, branch to store factory
    lda #$FF ; load $FF into A for factories
; Continue with the store factory path.
; Branch target from @inc2 if carry stayed clear.
@inc_store_factory:
    sta cnt_factories ; store $FF into factories
    rts ; Return from subroutine
; Continue with the inc3 path.
; Branch target from @inc2 if the test did not match.
@inc3:
    cmp #TILE_PARK ; park tile type
    bne @inc4 ; if the test did not match, branch to inc4
    lda cnt_parks ; load parks into A
    clc ; clear carry before the next add
    adc tmp4 ; add temporary slot 4 into A
    bcc @inc_store_park ; if carry stayed clear, branch to store park
    lda #$FF ; load $FF into A for parks
; Continue with the store park path.
; Branch target from @inc3 if carry stayed clear.
@inc_store_park:
    sta cnt_parks ; store $FF into parks
    rts ; Return from subroutine
; Continue with the inc4 path.
; Branch target from @inc3 if the test did not match.
@inc4:
    cmp #TILE_POWER ; power-plant tile type
    bne @inc5 ; if the test did not match, branch to inc5
    lda cnt_power ; load power into A
    clc ; clear carry before the next add
    adc tmp4 ; add temporary slot 4 into A
    bcc @inc_store_power ; if carry stayed clear, branch to store power
    lda #$FF ; load $FF into A for power
; Continue with the store power path.
; Branch target from @inc4 if carry stayed clear.
@inc_store_power:
    sta cnt_power ; store $FF into power
    rts ; Return from subroutine
; Continue with the inc5 path.
; Branch target from @inc4 if the test did not match.
@inc5:
    cmp #TILE_POLICE ; police tile type
    bne @inc6 ; if the test did not match, branch to inc6
    lda cnt_police ; load police into A
    clc ; clear carry before the next add
    adc tmp4 ; add temporary slot 4 into A
    bcc @inc_store_police ; if carry stayed clear, branch to store police
    lda #$FF ; load $FF into A for police
; Continue with the store police path.
; Branch target from @inc5 if carry stayed clear.
@inc_store_police:
    sta cnt_police ; store $FF into police
    rts ; Return from subroutine
; Continue with the inc6 path.
; Branch target from @inc5 if the test did not match.
@inc6:
    cmp #TILE_FIRE ; fire-station tile type
    bne @inc_done ; if the test did not match, branch to done
    lda cnt_fire ; load fire into A
    clc ; clear carry before the next add
    adc tmp4 ; add temporary slot 4 into A
    bcc @inc_store_fire ; if carry stayed clear, branch to store fire
    lda #$FF ; load $FF into A for fire
; Continue with the store fire path.
; Branch target from @inc6 if carry stayed clear.
@inc_store_fire:
    sta cnt_fire ; store $FF into fire
; Finish this local path and fall back to the caller or shared exit.
; Branch target from @inc6 if the test did not match.
@inc_done:
    rts ; Return from subroutine

; ------------------------------------------------------------
; decrement_count  (A = tile type)
; Decrement the appropriate building-count ZP variable (floor 0).
; ------------------------------------------------------------
decrement_count:
    sta tmp3 ; store A into temporary slot 3
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    tax ; move A into X for the upcoming table lookup
    lda tmp3 ; load temporary slot 3 into A
    jsr get_tile_density_units ; call tile density units
    sta tmp4 ; store A into temporary slot 4
    txa ; move X back into A
    cmp #TILE_ROAD ; check for a road tile
    beq @dec_road ; if the test matched, branch to road
    cmp #TILE_BRIDGE ; check for a bridge tile
    bne @dec1 ; if the test did not match, branch to dec1
; Continue with the road path.
; Branch target from decrement_count if the test matched.
@dec_road:
    lda cnt_roads ; load roads into A
    sec ; set carry before the subtract/compare sequence
    sbc tmp4 ; subtract temporary slot 4 from A
    bcs @dec_store_road ; if carry was set, branch to store road
    lda #0 ; load 0 into A for roads
; Continue with the store road path.
; Branch target from @dec_road if carry was set.
@dec_store_road:
    sta cnt_roads ; store 0 into roads
    rts ; Return from subroutine
; Continue with the dec1 path.
; Branch target from decrement_count if the test did not match.
@dec1:
    cmp #TILE_HOUSE ; house tile type
    bne @dec2 ; if the test did not match, branch to dec2
    lda cnt_houses ; load houses into A
    sec ; set carry before the subtract/compare sequence
    sbc tmp4 ; subtract temporary slot 4 from A
    bcs @dec_store_house ; if carry was set, branch to store house
    lda #0 ; load 0 into A for houses
; Continue with the store house path.
; Branch target from @dec1 if carry was set.
@dec_store_house:
    sta cnt_houses ; store 0 into houses
    rts ; Return from subroutine
; Continue with the dec2 path.
; Branch target from @dec1 if the test did not match.
@dec2:
    cmp #TILE_FACTORY ; factory tile type
    bne @dec3 ; if the test did not match, branch to dec3
    lda cnt_factories ; load factories into A
    sec ; set carry before the subtract/compare sequence
    sbc tmp4 ; subtract temporary slot 4 from A
    bcs @dec_store_factory ; if carry was set, branch to store factory
    lda #0 ; load 0 into A for factories
; Continue with the store factory path.
; Branch target from @dec2 if carry was set.
@dec_store_factory:
    sta cnt_factories ; store 0 into factories
    rts ; Return from subroutine
; Continue with the dec3 path.
; Branch target from @dec2 if the test did not match.
@dec3:
    cmp #TILE_PARK ; park tile type
    bne @dec4 ; if the test did not match, branch to dec4
    lda cnt_parks ; load parks into A
    sec ; set carry before the subtract/compare sequence
    sbc tmp4 ; subtract temporary slot 4 from A
    bcs @dec_store_park ; if carry was set, branch to store park
    lda #0 ; load 0 into A for parks
; Continue with the store park path.
; Branch target from @dec3 if carry was set.
@dec_store_park:
    sta cnt_parks ; store 0 into parks
    rts ; Return from subroutine
; Continue with the dec4 path.
; Branch target from @dec3 if the test did not match.
@dec4:
    cmp #TILE_POWER ; power-plant tile type
    bne @dec5 ; if the test did not match, branch to dec5
    lda cnt_power ; load power into A
    sec ; set carry before the subtract/compare sequence
    sbc tmp4 ; subtract temporary slot 4 from A
    bcs @dec_store_power ; if carry was set, branch to store power
    lda #0 ; load 0 into A for power
; Continue with the store power path.
; Branch target from @dec4 if carry was set.
@dec_store_power:
    sta cnt_power ; store 0 into power
    rts ; Return from subroutine
; Continue with the dec5 path.
; Branch target from @dec4 if the test did not match.
@dec5:
    cmp #TILE_POLICE ; police tile type
    bne @dec6 ; if the test did not match, branch to dec6
    lda cnt_police ; load police into A
    sec ; set carry before the subtract/compare sequence
    sbc tmp4 ; subtract temporary slot 4 from A
    bcs @dec_store_police ; if carry was set, branch to store police
    lda #0 ; load 0 into A for police
; Continue with the store police path.
; Branch target from @dec5 if carry was set.
@dec_store_police:
    sta cnt_police ; store 0 into police
    rts ; Return from subroutine
; Continue with the dec6 path.
; Branch target from @dec5 if the test did not match.
@dec6:
    cmp #TILE_FIRE ; fire-station tile type
    bne @dec_done ; if the test did not match, branch to done
    lda cnt_fire ; load fire into A
    sec ; set carry before the subtract/compare sequence
    sbc tmp4 ; subtract temporary slot 4 from A
    bcs @dec_store_fire ; if carry was set, branch to store fire
    lda #0 ; load 0 into A for fire
; Continue with the store fire path.
; Branch target from @dec6 if carry was set.
@dec_store_fire:
    sta cnt_fire ; store 0 into fire
; Finish this local path and fall back to the caller or shared exit.
; Branch target from @dec6 if the test did not match.
@dec_done:
    rts ; Return from subroutine

; ------------------------------------------------------------
; show_building_name  (called from input.s)
; Display the name of sel_building as a timed message.
; ------------------------------------------------------------
show_building_name:
    lda sel_building ; load selected building type into A
    beq @sbn_done ; if the test matched, branch to done
    cmp #TILE_WATER         ; valid range is 1-7 (TILE_ROAD..TILE_FIRE)
    bcs @sbn_done ; if carry was set, branch to done
    sec ; set carry before the subtract/compare sequence
    sbc #1                  ; 0-6 index into bld_names table
    asl                     ; × 2 for word pointer
    tax ; move A into X for the upcoming table lookup
    lda bld_names,x ; load names into A
    sta ptr_lo ; store names into primary pointer low byte
    lda bld_names+1,x ; load names+1 into A
    sta ptr_hi ; store names+1 into primary pointer high byte
    ldx #0 ; load 0 into X
    ldy #UI_ROW_MSG ; load message row into Y
    lda #COLOR_LTGREEN ; load light green into A
    jsr print_str_col ; draw the prepared string at the requested position
    lda #60 ; load 60 into A for message timer
    sta msg_timer ; store 60 into message timer
; Finish this local path and fall back to the caller or shared exit.
; Branch target from show_building_name if the test matched.
; Branch target from show_building_name if carry was set.
@sbn_done:
    rts ; Return from subroutine
