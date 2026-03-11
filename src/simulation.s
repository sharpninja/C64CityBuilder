; ============================================================
; C64 City Builder - Economic / Population Simulation
; Included by main.s.  Runs once per SIM_INTERVAL frames.
; ============================================================

    .segment "BSS"
; Reserve storage for park effect map.
park_effect_map:    .res MAP_SIZE
; Reserve storage for police effect map.
police_effect_map:  .res MAP_SIZE
; Reserve storage for fire effect map.
fire_effect_map:    .res MAP_SIZE
; Reserve storage for house zone map.
house_zone_map:     .res MAP_SIZE
; Reserve storage for factory zone map.
factory_zone_map:   .res MAP_SIZE
; Reserve storage for tile value map.
tile_value_map:     .res MAP_SIZE
; Reserve storage for road component map.
road_component_map: .res MAP_SIZE
; Reserve storage for road component map.
old_road_component_map: .res MAP_SIZE
; Reserve storage for building segment map.
building_segment_map:   .res MAP_SIZE
; Reserve storage for segment jobs.
segment_jobs:      .res 16
; Reserve storage for segment workers.
segment_workers:   .res 16
; Reserve storage for segment used.
segment_used:      .res 16
; Reserve storage for road topology dirty.
road_topology_dirty: .res 1
; Reserve storage for current segment id.
current_segment_id:  .res 1
; Reserve storage for current segment min old.
current_segment_min_old: .res 1
; Reserve storage for component jobs.
component_jobs:     .res 1
; Reserve storage for component workers.
component_workers:  .res 1
; Reserve storage for component changed.
component_changed:  .res 1

    .segment "CODE"

; ============================================================
; Multiply helpers: A × constant → A  (caps at 255)
; These preserve X and Y.
; ============================================================

; --- A * 5 -------------------------------------------------
mul_by_5:
    sta tmp4 ; store A into temporary slot 4
    beq @m5_done ; if the test matched, branch to m5 done
    lda #0 ; load 0 into A
    ldx tmp4 ; load temporary slot 4 into X
; Repeat the current loop.
; Branch target from @m5_loop if the test did not match.
@m5_loop:
    clc ; clear carry before the next add
    adc #5 ; add 5 into A
    bcs @m5_cap ; if carry was set, branch to m5 cap
    dex ; step X back one slot
    bne @m5_loop ; if the test did not match, branch to m5 loop
; Finish this local path and fall back to the caller or shared exit.
; Branch target from mul_by_5 if the test matched.
@m5_done:
    rts ; Return from subroutine
; Continue with the cap path.
; Branch target from @m5_loop if carry was set.
@m5_cap:
    lda #$FF ; load $FF into A
    rts ; Return from subroutine

; --- A * 10 ------------------------------------------------
mul_by_10:
    sta tmp4 ; store A into temporary slot 4
    beq @m10_done ; if the test matched, branch to m10 done
    lda #0 ; load 0 into A
    ldx tmp4 ; load temporary slot 4 into X
; Repeat the current loop.
; Branch target from @m10_loop if the test did not match.
@m10_loop:
    clc ; clear carry before the next add
    adc #10 ; add 10 into A
    bcs @m10_cap ; if carry was set, branch to m10 cap
    dex ; step X back one slot
    bne @m10_loop ; if the test did not match, branch to m10 loop
; Finish this local path and fall back to the caller or shared exit.
; Branch target from mul_by_10 if the test matched.
@m10_done:
    rts ; Return from subroutine
; Continue with the cap path.
; Branch target from @m10_loop if carry was set.
@m10_cap:
    lda #$FF ; load $FF into A
    rts ; Return from subroutine

; --- A * 20 ------------------------------------------------
mul_by_20:
    sta tmp4 ; store A into temporary slot 4
    beq @m20_done ; if the test matched, branch to m20 done
    lda #0 ; load 0 into A
    ldx tmp4 ; load temporary slot 4 into X
; Repeat the current loop.
; Branch target from @m20_loop if the test did not match.
@m20_loop:
    clc ; clear carry before the next add
    adc #20 ; add 20 into A
    bcs @m20_cap ; if carry was set, branch to m20 cap
    dex ; step X back one slot
    bne @m20_loop ; if the test did not match, branch to m20 loop
; Finish this local path and fall back to the caller or shared exit.
; Branch target from mul_by_20 if the test matched.
@m20_done:
    rts ; Return from subroutine
; Continue with the cap path.
; Branch target from @m20_loop if carry was set.
@m20_cap:
    lda #$FF ; load $FF into A
    rts ; Return from subroutine

; --- A * 50 ------------------------------------------------
mul_by_50:
    sta tmp4 ; store A into temporary slot 4
    beq @m50_done ; if the test matched, branch to m50 done
    lda #0 ; load 0 into A
    ldx tmp4 ; load temporary slot 4 into X
; Repeat the current loop.
; Branch target from @m50_loop if the test did not match.
@m50_loop:
    clc ; clear carry before the next add
    adc #50 ; add 50 into A
    bcs @m50_cap ; if carry was set, branch to m50 cap
    dex ; step X back one slot
    bne @m50_loop ; if the test did not match, branch to m50 loop
; Finish this local path and fall back to the caller or shared exit.
; Branch target from mul_by_50 if the test matched.
@m50_done:
    rts ; Return from subroutine
; Continue with the cap path.
; Branch target from @m50_loop if carry was set.
@m50_cap:
    lda #$FF ; load $FF into A
    rts ; Return from subroutine

; --- A * 2  (simple left shift) ----------------------------
mul_by_2:
    asl ; shift A left to multiply by two
    bcs @m2_cap ; if carry was set, branch to m2 cap
    rts ; Return from subroutine
; Continue with the cap path.
; Branch target from mul_by_2 if carry was set.
@m2_cap:
    lda #$FF ; load $FF into A
    rts ; Return from subroutine

; --- A * 3 -------------------------------------------------
mul_by_3:
    sta tmp4 ; store A into temporary slot 4
    asl ; shift A left to multiply by two
    bcs @m3_cap ; if carry was set, branch to m3 cap
    clc ; clear carry before the next add
    adc tmp4 ; add temporary slot 4 into A
    bcs @m3_cap ; if carry was set, branch to m3 cap
    rts ; Return from subroutine
; Continue with the cap path.
; Branch target from mul_by_3 if carry was set.
; Branch target from mul_by_3 if carry was set.
@m3_cap:
    lda #$FF ; load $FF into A
    rts ; Return from subroutine

; ============================================================
; 8-bit accumulator helpers for the city economy
; ============================================================
add_to_jobs:
    clc ; clear carry before the next add
    adc jobs_total ; add jobs total into A
    bcc @atj_store ; if carry stayed clear, branch to store
    lda #$FF ; load $FF into A for jobs total
; Continue with the store path.
; Branch target from add_to_jobs if carry stayed clear.
@atj_store:
    sta jobs_total ; store $FF into jobs total
    rts ; Return from subroutine

; Enter the to revenue routine.
add_to_revenue:
    clc ; clear carry before the next add
    adc rev_lo ; add revenue low byte into A
    sta rev_lo ; store A into revenue low byte
    bcc @atr_done ; if carry stayed clear, branch to done
    inc rev_hi ; increment revenue high byte
; Finish this local path and fall back to the caller or shared exit.
; Branch target from add_to_revenue if carry stayed clear.
@atr_done:
    rts ; Return from subroutine

; Enter the to cost routine.
add_to_cost:
    clc ; clear carry before the next add
    adc cost_lo ; add cost low byte into A
    sta cost_lo ; store A into cost low byte
    bcc @atc_done ; if carry stayed clear, branch to done
    inc cost_hi ; increment cost high byte
; Finish this local path and fall back to the caller or shared exit.
; Branch target from add_to_cost if carry stayed clear.
@atc_done:
    rts ; Return from subroutine

; Enter the to land value routine.
add_to_land_value:
    clc ; clear carry before the next add
    adc land_value_lo ; add land value low byte into A
    sta land_value_lo ; store A into land value low byte
    bcc @atl_done ; if carry stayed clear, branch to done
    inc land_value_hi ; increment land value high byte
    bne @atl_done ; if the test did not match, branch to done
    lda #$FF ; load $FF into A for land value low byte
    sta land_value_lo ; store $FF into land value low byte
    sta land_value_hi ; store A into land value high byte
; Finish this local path and fall back to the caller or shared exit.
; Branch target from add_to_land_value if carry stayed clear.
; Branch target from add_to_land_value if the test did not match.
@atl_done:
    rts ; Return from subroutine

; Enter the to worker supply routine.
add_to_worker_supply:
    clc ; clear carry before the next add
    adc employed_pop ; add worker supply total into A
    bcc @atw_store ; if carry stayed clear, branch to store
    lda #$FF ; load $FF into A for worker supply total
; Continue with the store path.
; Branch target from add_to_worker_supply if carry stayed clear.
@atw_store:
    sta employed_pop ; store $FF into worker supply total
    rts ; Return from subroutine

; Enter the a to tmp3 routine.
add_a_to_tmp3:
    clc ; clear carry before the next add
    adc tmp3 ; add temporary slot 3 into A
    bcc @a3_store ; if carry stayed clear, branch to a3 store
    lda #$FF ; load $FF into A for temporary slot 3
; Continue with the store path.
; Branch target from add_a_to_tmp3 if carry stayed clear.
@a3_store:
    sta tmp3 ; store $FF into temporary slot 3
    rts ; Return from subroutine

; Enter the clear map buffer routine.
clear_map_buffer:
    lda ptr2_lo ; load secondary pointer low byte into A
    sta ptr_lo ; store secondary pointer low byte into primary pointer low byte
    lda ptr2_hi ; load secondary pointer high byte into A
    sta ptr_hi ; store secondary pointer high byte into primary pointer high byte
    lda #0 ; load 0 into A
    ldx #3 ; load 3 into X
; Process the next page chunk.
; Branch target from @cmb_loop if the test did not match.
@cmb_page:
    ldy #0 ; load 0 into Y for primary pointer low byte
; Repeat the current loop.
; Branch target from @cmb_loop if the test did not match.
@cmb_loop:
    sta (ptr_lo),y ; store 0 into primary pointer low byte
    iny ; advance Y to the next offset
    bne @cmb_loop ; if the test did not match, branch to loop
    inc ptr_hi ; advance the primary pointer to the next page
    dex ; step X back one slot
    bne @cmb_page ; if the test did not match, branch to page
    ldy #0 ; load 0 into Y for primary pointer low byte
; Continue with the remainder bytes path.
; Branch target from @cmb_rem if the test did not match.
@cmb_rem:
    sta (ptr_lo),y ; store 0 into primary pointer low byte
    iny ; advance Y to the next offset
    cpy #(MAP_SIZE - 768) ; (MAP SIZE - 768
    bne @cmb_rem ; if the test did not match, branch to rem
    rts ; Return from subroutine

; Enter the clear sim maps routine.
clear_sim_maps:
    lda #<park_effect_map ; load park effect map into A for secondary pointer low byte
    sta ptr2_lo ; store park effect map into secondary pointer low byte
    lda #>park_effect_map ; load park effect map into A for secondary pointer high byte
    sta ptr2_hi ; store park effect map into secondary pointer high byte
    jsr clear_map_buffer ; clear the target map-sized buffer

    lda #<police_effect_map ; load police coverage map into A for secondary pointer low byte
    sta ptr2_lo ; store police coverage map into secondary pointer low byte
    lda #>police_effect_map ; load police coverage map into A for secondary pointer high byte
    sta ptr2_hi ; store police coverage map into secondary pointer high byte
    jsr clear_map_buffer ; clear the target map-sized buffer

    lda #<fire_effect_map ; load fire coverage map into A for secondary pointer low byte
    sta ptr2_lo ; store fire coverage map into secondary pointer low byte
    lda #>fire_effect_map ; load fire coverage map into A for secondary pointer high byte
    sta ptr2_hi ; store fire coverage map into secondary pointer high byte
    jsr clear_map_buffer ; clear the target map-sized buffer

    lda #<house_zone_map ; load house zone map into A for secondary pointer low byte
    sta ptr2_lo ; store house zone map into secondary pointer low byte
    lda #>house_zone_map ; load house zone map into A for secondary pointer high byte
    sta ptr2_hi ; store house zone map into secondary pointer high byte
    jsr clear_map_buffer ; clear the target map-sized buffer

    lda #<factory_zone_map ; load factory zone map into A for secondary pointer low byte
    sta ptr2_lo ; store factory zone map into secondary pointer low byte
    lda #>factory_zone_map ; load factory zone map into A for secondary pointer high byte
    sta ptr2_hi ; store factory zone map into secondary pointer high byte
    jsr clear_map_buffer ; clear the target map-sized buffer

    lda #<tile_value_map ; load tile value map into A for secondary pointer low byte
    sta ptr2_lo ; store tile value map into secondary pointer low byte
    lda #>tile_value_map ; load tile value map into A for secondary pointer high byte
    sta ptr2_hi ; store tile value map into secondary pointer high byte
    jsr clear_map_buffer ; clear the target map-sized buffer
    rts ; Return from subroutine

; Enter the copy map buffer routine.
copy_map_buffer:
    ldx #3 ; load 3 into X
; Process the next page chunk.
; Branch target from @cpb_loop if the test did not match.
@cpb_page:
    ldy #0 ; load 0 into Y
; Repeat the current loop.
; Branch target from @cpb_loop if the test did not match.
@cpb_loop:
    lda (ptr_lo),y ; load primary pointer low byte into A
    sta (ptr2_lo),y ; store primary pointer low byte into secondary pointer low byte
    iny ; advance Y to the next offset
    bne @cpb_loop ; if the test did not match, branch to loop
    inc ptr_hi ; advance the primary pointer to the next page
    inc ptr2_hi ; advance the secondary pointer to the next page
    dex ; step X back one slot
    bne @cpb_page ; if the test did not match, branch to page
    ldy #0 ; load 0 into Y
; Continue with the remainder bytes path.
; Branch target from @cpb_rem if the test did not match.
@cpb_rem:
    lda (ptr_lo),y ; load primary pointer low byte into A
    sta (ptr2_lo),y ; store primary pointer low byte into secondary pointer low byte
    iny ; advance Y to the next offset
    cpy #(MAP_SIZE - 768) ; (MAP SIZE - 768
    bne @cpb_rem ; if the test did not match, branch to rem
    rts ; Return from subroutine

; Enter the clear segment totals routine.
clear_segment_totals:
    lda #0 ; load 0 into A
    ldx #15 ; load 15 into X for jobs per road segment
; Repeat the current loop.
; Branch target from @cst_loop if the result is non-negative.
@cst_loop:
    sta segment_jobs,x ; store 15 into jobs per road segment
    sta segment_workers,x ; store A into workers per road segment
    dex ; step X back one slot
    bpl @cst_loop ; if the result is non-negative, branch to loop
    rts ; Return from subroutine

; Enter the clear segment used routine.
clear_segment_used:
    lda #0 ; load 0 into A
    ldx #15 ; load 15 into X for road segment usage flags
; Repeat the current loop.
; Branch target from @csu_loop if the result is non-negative.
@csu_loop:
    sta segment_used,x ; store 15 into road segment usage flags
    dex ; step X back one slot
    bpl @csu_loop ; if the result is non-negative, branch to loop
    rts ; Return from subroutine

; Enter the clear road segment state routine.
clear_road_segment_state:
    lda #<road_component_map ; load road segment map into A for secondary pointer low byte
    sta ptr2_lo ; store road segment map into secondary pointer low byte
    lda #>road_component_map ; load road segment map into A for secondary pointer high byte
    sta ptr2_hi ; store road segment map into secondary pointer high byte
    jsr clear_map_buffer ; clear the target map-sized buffer

    lda #<old_road_component_map ; load previous road segment map into A for secondary pointer low byte
    sta ptr2_lo ; store previous road segment map into secondary pointer low byte
    lda #>old_road_component_map ; load previous road segment map into A for secondary pointer high byte
    sta ptr2_hi ; store previous road segment map into secondary pointer high byte
    jsr clear_map_buffer ; clear the target map-sized buffer

    lda #<building_segment_map ; load building-to-road segment map into A for secondary pointer low byte
    sta ptr2_lo ; store building-to-road segment map into secondary pointer low byte
    lda #>building_segment_map ; load building-to-road segment map into A for secondary pointer high byte
    sta ptr2_hi ; store building-to-road segment map into secondary pointer high byte
    jsr clear_map_buffer ; clear the target map-sized buffer

    lda #0 ; prepare to mark road topology as up to date
    sta road_topology_dirty ; mark road topology as up to date
    sta current_segment_id ; store A into active road segment id
    sta current_segment_min_old ; store A into current segment min old
    jsr clear_segment_totals ; call clear segment totals
    jsr clear_segment_used ; call clear segment used
    rts ; Return from subroutine

; Enter the segment to pack routine.
add_segment_to_pack:
    cmp #16 ; 16
    bcs @astp_done ; if carry was set, branch to astp done
    sta tmp4 ; store A into temporary slot 4
    beq @astp_done ; if the test matched, branch to astp done

    lda tmp3 ; load temporary slot 3 into A
    and #$0F ; mask A with $0F
    beq @astp_store_low ; if the test matched, branch to astp store low
    cmp tmp4 ; temporary slot 4
    beq @astp_done ; if the test matched, branch to astp done
    tax ; move A into X for the upcoming table lookup

    lda tmp3 ; load temporary slot 3 into A
    and #$F0 ; mask A with $F0
    beq @astp_store_high ; if the test matched, branch to astp store high
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    sta road_mask ; store A into road mask
    cmp tmp4 ; temporary slot 4
    beq @astp_done ; if the test matched, branch to astp done

    txa ; move X back into A
    cmp tmp4 ; temporary slot 4
    bcc @astp_check_high ; if carry stayed clear, branch to astp check high
    asl ; shift A left to multiply by two
    asl ; shift A left to multiply by two
    asl ; shift A left to multiply by two
    asl ; shift A left to multiply by two
    ora tmp4 ; set the bits from temporary slot 4
    sta tmp3 ; store A into temporary slot 3
    rts ; Return from subroutine

; Continue with the astp check high path.
; Branch target from add_segment_to_pack if carry stayed clear.
@astp_check_high:
    lda road_mask ; load road mask into A
    cmp tmp4 ; temporary slot 4
    bcc @astp_done ; if carry stayed clear, branch to astp done
    beq @astp_done ; if the test matched, branch to astp done
    lda tmp4 ; load temporary slot 4 into A
    asl ; shift A left to multiply by two
    asl ; shift A left to multiply by two
    asl ; shift A left to multiply by two
    asl ; shift A left to multiply by two
    sta tmp4 ; store A into temporary slot 4
    txa ; move X back into A
    ora tmp4 ; set the bits from temporary slot 4
    sta tmp3 ; store A into temporary slot 3
    rts ; Return from subroutine

; Continue with the astp store low path.
; Branch target from add_segment_to_pack if the test matched.
@astp_store_low:
    lda tmp4 ; load temporary slot 4 into A
    sta tmp3 ; store temporary slot 4 into temporary slot 3
    rts ; Return from subroutine

; Continue with the astp store high path.
; Branch target from add_segment_to_pack if the test matched.
@astp_store_high:
    lda tmp4 ; load temporary slot 4 into A
    asl ; shift A left to multiply by two
    asl ; shift A left to multiply by two
    asl ; shift A left to multiply by two
    asl ; shift A left to multiply by two
    ora tmp3 ; set the bits from temporary slot 3
    sta tmp3 ; store A into temporary slot 3

; Continue with the astp completion path.
; Branch target from add_segment_to_pack if carry was set.
; Branch target from add_segment_to_pack if the test matched.
; Branch target from add_segment_to_pack if the test matched.
; Branch target from add_segment_to_pack if the test matched.
; Branch target from @astp_check_high if carry stayed clear.
; Branch target from @astp_check_high if the test matched.
@astp_done:
    rts ; Return from subroutine

; Enter the collect adjacent segments routine.
collect_adjacent_segments:
    lda tmp1 ; load temporary slot 1 into A
    sta np_val_lo ; store temporary slot 1 into number-print value low byte
    lda tmp2 ; load temporary slot 2 into A
    sta np_val_hi ; store temporary slot 2 into number-print value high byte
    lda #<road_component_map ; load road segment map into A for secondary pointer low byte
    sta ptr2_lo ; store road segment map into secondary pointer low byte
    lda #>road_component_map ; load road segment map into A for secondary pointer high byte
    sta ptr2_hi ; store road segment map into secondary pointer high byte
    lda #0 ; load 0 into A for temporary slot 3
    sta tmp3 ; store 0 into temporary slot 3

    lda np_val_hi ; load number-print value high byte into A
    beq @cas_south ; if the test matched, branch to south
    dec tmp2 ; step to the row above
    jsr load_metric_at ; call load metric at
    jsr add_segment_to_pack ; call segment to pack
    inc tmp2 ; increment temporary slot 2

; Continue with the south neighbor path.
; Branch target from collect_adjacent_segments if the test matched.
@cas_south:
    lda np_val_hi ; load number-print value high byte into A
    cmp #(MAP_HEIGHT - 1) ; (MAP HEIGHT - 1
    bcs @cas_east ; if carry was set, branch to east
    inc tmp2 ; increment temporary slot 2
    jsr load_metric_at ; call load metric at
    jsr add_segment_to_pack ; call segment to pack
    dec tmp2 ; step to the row above

; Continue with the east neighbor path.
; Branch target from @cas_south if carry was set.
@cas_east:
    lda np_val_lo ; load number-print value low byte into A
    cmp #(MAP_WIDTH - 1) ; (MAP WIDTH - 1
    bcs @cas_west ; if carry was set, branch to west
    inc tmp1 ; increment temporary slot 1
    jsr load_metric_at ; call load metric at
    jsr add_segment_to_pack ; call segment to pack
    dec tmp1 ; step to the column on the left

; Continue with the west neighbor path.
; Branch target from @cas_east if carry was set.
@cas_west:
    lda np_val_lo ; load number-print value low byte into A
    beq @cas_done ; if the test matched, branch to done
    dec tmp1 ; step to the column on the left
    jsr load_metric_at ; call load metric at
    jsr add_segment_to_pack ; call segment to pack
    inc tmp1 ; increment temporary slot 1

; Finish this local path and fall back to the caller or shared exit.
; Branch target from @cas_west if the test matched.
@cas_done:
    lda np_val_lo ; load number-print value low byte into A
    sta tmp1 ; store number-print value low byte into temporary slot 1
    lda np_val_hi ; load number-print value high byte into A
    sta tmp2 ; store number-print value high byte into temporary slot 2
    lda tmp3 ; load temporary slot 3 into A
    rts ; Return from subroutine

; Enter the update building segment at routine.
update_building_segment_at:
    lda #<building_segment_map ; load building-to-road segment map into A for secondary pointer low byte
    sta ptr2_lo ; store building-to-road segment map into secondary pointer low byte
    lda #>building_segment_map ; load building-to-road segment map into A for secondary pointer high byte
    sta ptr2_hi ; store building-to-road segment map into secondary pointer high byte

    lda tmp1 ; load temporary slot 1 into A
    ldx tmp2 ; load temporary slot 2 into X
    jsr get_tile ; read the tile at the requested map coordinate
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_HOUSE ; house tile type
    bcc @ubsa_clear ; if carry stayed clear, branch to ubsa clear
    cmp #(TILE_FIRE + 1) ; (TILE FIRE + 1
    bcs @ubsa_clear ; if carry was set, branch to ubsa clear
    jsr collect_adjacent_segments ; call collect adjacent segments
    jmp store_metric_at ; continue at store metric at

; Continue with the ubsa clear path.
; Branch target from update_building_segment_at if carry stayed clear.
; Branch target from update_building_segment_at if carry was set.
@ubsa_clear:
    lda #0 ; load 0 into A
    jmp store_metric_at ; continue at store metric at

; Enter the rebuild building segments routine.
rebuild_building_segments:
    lda #0 ; load 0 into A for temporary slot 2
    sta tmp2 ; store 0 into temporary slot 2
; Continue with the row path.
@rbs_row:
    lda #0 ; load 0 into A for temporary slot 1
    sta tmp1 ; store 0 into temporary slot 1
; Continue with the col path.
@rbs_col:
    jsr update_building_segment_at ; call update building segment at
    inc tmp1 ; increment temporary slot 1
    lda tmp1 ; load temporary slot 1 into A
    cmp #MAP_WIDTH ; check for the end of the row
    beq @rbs_next_row ; if the test matched, branch to next row
    jmp @rbs_col ; continue at col
; Continue with the next row path.
; Branch target from @rbs_col if the test matched.
@rbs_next_row:
    inc tmp2 ; increment temporary slot 2
    lda tmp2 ; load temporary slot 2 into A
    cmp #MAP_HEIGHT ; check for the bottom of the map
    beq @rbs_done ; if the test matched, branch to done
    jmp @rbs_row ; continue at row
; Finish this local path and fall back to the caller or shared exit.
; Branch target from @rbs_next_row if the test matched.
@rbs_done:
    rts ; Return from subroutine

; Enter the touches current segment routine.
touches_current_segment:
    lda tmp1 ; load temporary slot 1 into A
    sta np_val_lo ; store temporary slot 1 into number-print value low byte
    lda tmp2 ; load temporary slot 2 into A
    sta np_val_hi ; store temporary slot 2 into number-print value high byte

    lda #<road_component_map ; load road segment map into A for secondary pointer low byte
    sta ptr2_lo ; store road segment map into secondary pointer low byte
    lda #>road_component_map ; load road segment map into A for secondary pointer high byte
    sta ptr2_hi ; store road segment map into secondary pointer high byte

    lda np_val_hi ; load number-print value high byte into A
    beq @tcs_south ; if the test matched, branch to south
    lda np_val_lo ; load number-print value low byte into A
    sta tmp1 ; store number-print value low byte into temporary slot 1
    lda np_val_hi ; load number-print value high byte into A
    sec ; set carry before the subtract/compare sequence
    sbc #1 ; subtract 1 from A
    sta tmp2 ; store A into temporary slot 2
    jsr load_metric_at ; call load metric at
    cmp current_segment_id ; active road segment id
    beq @tcs_yes ; if the test matched, branch to yes

; Continue with the south neighbor path.
; Branch target from touches_current_segment if the test matched.
@tcs_south:
    lda np_val_hi ; load number-print value high byte into A
    cmp #(MAP_HEIGHT - 1) ; (MAP HEIGHT - 1
    bcs @tcs_east ; if carry was set, branch to east
    lda np_val_lo ; load number-print value low byte into A
    sta tmp1 ; store number-print value low byte into temporary slot 1
    lda np_val_hi ; load number-print value high byte into A
    clc ; clear carry before the next add
    adc #1 ; add 1 into A
    sta tmp2 ; store A into temporary slot 2
    jsr load_metric_at ; call load metric at
    cmp current_segment_id ; active road segment id
    beq @tcs_yes ; if the test matched, branch to yes

; Continue with the east neighbor path.
; Branch target from @tcs_south if carry was set.
@tcs_east:
    lda np_val_lo ; load number-print value low byte into A
    cmp #(MAP_WIDTH - 1) ; (MAP WIDTH - 1
    bcs @tcs_west ; if carry was set, branch to west
    clc ; clear carry before the next add
    adc #1 ; add 1 into A
    sta tmp1 ; store A into temporary slot 1
    lda np_val_hi ; load number-print value high byte into A
    sta tmp2 ; store number-print value high byte into temporary slot 2
    jsr load_metric_at ; call load metric at
    cmp current_segment_id ; active road segment id
    beq @tcs_yes ; if the test matched, branch to yes

; Continue with the west neighbor path.
; Branch target from @tcs_east if carry was set.
@tcs_west:
    lda np_val_lo ; load number-print value low byte into A
    beq @tcs_no ; if the test matched, branch to no
    sec ; set carry before the subtract/compare sequence
    sbc #1 ; subtract 1 from A
    sta tmp1 ; store A into temporary slot 1
    lda np_val_hi ; load number-print value high byte into A
    sta tmp2 ; store number-print value high byte into temporary slot 2
    jsr load_metric_at ; call load metric at
    cmp current_segment_id ; active road segment id
    beq @tcs_yes ; if the test matched, branch to yes

; Continue with the no path.
; Branch target from @tcs_west if the test matched.
@tcs_no:
    lda np_val_lo ; load number-print value low byte into A
    sta tmp1 ; store number-print value low byte into temporary slot 1
    lda np_val_hi ; load number-print value high byte into A
    sta tmp2 ; store number-print value high byte into temporary slot 2
    lda #0 ; load 0 into A
    rts ; Return from subroutine

; Continue with the yes path.
; Branch target from touches_current_segment if the test matched.
; Branch target from @tcs_south if the test matched.
; Branch target from @tcs_east if the test matched.
; Branch target from @tcs_west if the test matched.
@tcs_yes:
    lda np_val_lo ; load number-print value low byte into A
    sta tmp1 ; store number-print value low byte into temporary slot 1
    lda np_val_hi ; load number-print value high byte into A
    sta tmp2 ; store number-print value high byte into temporary slot 2
    lda #1 ; load 1 into A
    rts ; Return from subroutine

; Enter the expand temp segment routine.
expand_temp_segment:
    lda #16 ; load 16 into A for active road segment id
    sta current_segment_id ; store 16 into active road segment id
; Continue with the pass path.
; Branch target from @ets_pass_done if the test did not match.
@ets_pass:
    lda #0 ; clear the component-changed flag
    sta component_changed ; clear the component-changed flag
    sta tmp2 ; store A into temporary slot 2
; Continue with the row path.
@ets_row:
    lda #0 ; load 0 into A for temporary slot 1
    sta tmp1 ; store 0 into temporary slot 1
; Continue with the col path.
@ets_col:
    lda tmp1 ; load temporary slot 1 into A
    ldx tmp2 ; load temporary slot 2 into X
    jsr get_tile ; read the tile at the requested map coordinate
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_ROAD ; check for a road tile
    beq @ets_roadlike ; if the test matched, branch to roadlike
    cmp #TILE_BRIDGE ; check for a bridge tile
    bne @ets_next ; if the test did not match, branch to next
; Continue with the roadlike path.
; Branch target from @ets_col if the test matched.
@ets_roadlike:
    lda #<road_component_map ; load road segment map into A for secondary pointer low byte
    sta ptr2_lo ; store road segment map into secondary pointer low byte
    lda #>road_component_map ; load road segment map into A for secondary pointer high byte
    sta ptr2_hi ; store road segment map into secondary pointer high byte
    jsr load_metric_at ; call load metric at
    bne @ets_next ; if the test did not match, branch to next
    jsr touches_current_segment ; call touches current segment
    beq @ets_next ; if the test matched, branch to next
    lda #<road_component_map ; load road segment map into A for secondary pointer low byte
    sta ptr2_lo ; store road segment map into secondary pointer low byte
    lda #>road_component_map ; load road segment map into A for secondary pointer high byte
    sta ptr2_hi ; store road segment map into secondary pointer high byte
    lda #16 ; load 16 into A
    jsr store_metric_at ; call store metric at
    lda #1 ; set the component-changed flag
    sta component_changed ; set the component-changed flag
; Continue with the next path.
; Branch target from @ets_col if the test did not match.
; Branch target from @ets_roadlike if the test did not match.
; Branch target from @ets_roadlike if the test matched.
@ets_next:
    inc tmp1 ; increment temporary slot 1
    lda tmp1 ; load temporary slot 1 into A
    cmp #MAP_WIDTH ; check for the end of the row
    beq @ets_next_row ; if the test matched, branch to next row
    jmp @ets_col ; continue at col
; Continue with the next row path.
; Branch target from @ets_next if the test matched.
@ets_next_row:
    inc tmp2 ; increment temporary slot 2
    lda tmp2 ; load temporary slot 2 into A
    cmp #MAP_HEIGHT ; check for the bottom of the map
    beq @ets_pass_done ; if the test matched, branch to pass done
    jmp @ets_row ; continue at row
; Continue with the pass completion path.
; Branch target from @ets_next_row if the test matched.
@ets_pass_done:
    lda component_changed ; load component change flag into A
    bne @ets_pass ; if the test did not match, branch to pass
    rts ; Return from subroutine

; Enter the choose segment id for temp routine.
choose_segment_id_for_temp:
    lda #0 ; load 0 into A for current segment min old
    sta current_segment_min_old ; store 0 into current segment min old
    sta tmp2 ; store A into temporary slot 2
; Continue with the csit row path.
@csit_row:
    lda #0 ; load 0 into A for temporary slot 1
    sta tmp1 ; store 0 into temporary slot 1
; Continue with the csit col path.
@csit_col:
    lda #<road_component_map ; load road segment map into A for secondary pointer low byte
    sta ptr2_lo ; store road segment map into secondary pointer low byte
    lda #>road_component_map ; load road segment map into A for secondary pointer high byte
    sta ptr2_hi ; store road segment map into secondary pointer high byte
    jsr load_metric_at ; call load metric at
    cmp #16 ; 16
    bne @csit_next ; if the test did not match, branch to csit next

    lda #<old_road_component_map ; load previous road segment map into A for secondary pointer low byte
    sta ptr2_lo ; store previous road segment map into secondary pointer low byte
    lda #>old_road_component_map ; load previous road segment map into A for secondary pointer high byte
    sta ptr2_hi ; store previous road segment map into secondary pointer high byte
    jsr load_metric_at ; call load metric at
    beq @csit_next ; if the test matched, branch to csit next
    cmp #16 ; 16
    bcs @csit_next ; if carry was set, branch to csit next
    ldx current_segment_min_old ; load current segment min old into X
    beq @csit_store_old ; if the test matched, branch to csit store old
    cpx #16 ; 16
    bcs @csit_store_old ; if carry was set, branch to csit store old
    cpx #$FF ; $FF
    beq @csit_store_old ; if the test matched, branch to csit store old
    cmp current_segment_min_old ; current segment min old
    bcs @csit_next ; if carry was set, branch to csit next
; Continue with the csit store old path.
; Branch target from @csit_col if the test matched.
; Branch target from @csit_col if carry was set.
; Branch target from @csit_col if the test matched.
@csit_store_old:
    sta current_segment_min_old ; store A into current segment min old

; Continue with the csit next path.
; Branch target from @csit_col if the test did not match.
; Branch target from @csit_col if the test matched.
; Branch target from @csit_col if carry was set.
; Branch target from @csit_col if carry was set.
@csit_next:
    inc tmp1 ; increment temporary slot 1
    lda tmp1 ; load temporary slot 1 into A
    cmp #MAP_WIDTH ; check for the end of the row
    beq @csit_next_row ; if the test matched, branch to csit next row
    jmp @csit_col ; continue at csit col
; Continue with the csit next row path.
; Branch target from @csit_next if the test matched.
@csit_next_row:
    inc tmp2 ; increment temporary slot 2
    lda tmp2 ; load temporary slot 2 into A
    cmp #MAP_HEIGHT ; check for the bottom of the map
    beq @csit_choose ; if the test matched, branch to csit choose
    jmp @csit_row ; continue at csit row

; Continue with the csit choose path.
; Branch target from @csit_next_row if the test matched.
@csit_choose:
    lda current_segment_min_old ; load current segment min old into A
    beq @csit_find_free ; if the test matched, branch to csit find free
    tax ; move A into X for the upcoming table lookup
    lda segment_used,x ; load road segment usage flags into A
    bne @csit_find_free ; if the test did not match, branch to csit find free
    txa ; move X back into A
    bne @csit_use ; if the test did not match, branch to csit use

; Continue with the csit find free path.
; Branch target from @csit_choose if the test matched.
; Branch target from @csit_choose if the test did not match.
@csit_find_free:
    ldx #1 ; load 1 into X
; Continue with the csit find loop path.
; Branch target from @csit_find_loop if the test did not match.
@csit_find_loop:
    lda segment_used,x ; load road segment usage flags into A
    beq @csit_use_x ; if the test matched, branch to csit use x
    inx ; advance X to the next index
    cpx #16 ; 16
    bne @csit_find_loop ; if the test did not match, branch to csit find loop
    lda #$FF ; load $FF into A for active road segment id
    sta current_segment_id ; store $FF into active road segment id
    rts ; Return from subroutine
; Continue with the csit use x path.
; Branch target from @csit_find_loop if the test matched.
@csit_use_x:
    txa ; move X back into A

; Continue with the csit use path.
; Branch target from @csit_choose if the test did not match.
@csit_use:
    sta current_segment_id ; store A into active road segment id
    tax ; move A into X for the upcoming table lookup
    lda #1 ; load 1 into A for road segment usage flags
    sta segment_used,x ; store 1 into road segment usage flags
    rts ; Return from subroutine

; Enter the relabel temp segment routine.
relabel_temp_segment:
    lda #0 ; load 0 into A for temporary slot 2
    sta tmp2 ; store 0 into temporary slot 2
; Continue with the row path.
@rts_row:
    lda #0 ; load 0 into A for temporary slot 1
    sta tmp1 ; store 0 into temporary slot 1
; Continue with the col path.
@rts_col:
    lda #<road_component_map ; load road segment map into A for secondary pointer low byte
    sta ptr2_lo ; store road segment map into secondary pointer low byte
    lda #>road_component_map ; load road segment map into A for secondary pointer high byte
    sta ptr2_hi ; store road segment map into secondary pointer high byte
    jsr load_metric_at ; call load metric at
    cmp #16 ; 16
    bne @rts_next ; if the test did not match, branch to next
    lda #<road_component_map ; load road segment map into A for secondary pointer low byte
    sta ptr2_lo ; store road segment map into secondary pointer low byte
    lda #>road_component_map ; load road segment map into A for secondary pointer high byte
    sta ptr2_hi ; store road segment map into secondary pointer high byte
    lda current_segment_id ; load active road segment id into A
    jsr store_metric_at ; call store metric at
; Continue with the next path.
; Branch target from @rts_col if the test did not match.
@rts_next:
    inc tmp1 ; increment temporary slot 1
    lda tmp1 ; load temporary slot 1 into A
    cmp #MAP_WIDTH ; check for the end of the row
    beq @rts_next_row ; if the test matched, branch to next row
    jmp @rts_col ; continue at col
; Continue with the next row path.
; Branch target from @rts_next if the test matched.
@rts_next_row:
    inc tmp2 ; increment temporary slot 2
    lda tmp2 ; load temporary slot 2 into A
    cmp #MAP_HEIGHT ; check for the bottom of the map
    beq @rts_done ; if the test matched, branch to done
    jmp @rts_row ; continue at row
; Finish this local path and fall back to the caller or shared exit.
; Branch target from @rts_next_row if the test matched.
@rts_done:
    rts ; Return from subroutine

; Enter the rebuild road segments routine.
rebuild_road_segments:
    lda #<road_component_map ; load road segment map into A for primary pointer low byte
    sta ptr_lo ; store road segment map into primary pointer low byte
    lda #>road_component_map ; load road segment map into A for primary pointer high byte
    sta ptr_hi ; store road segment map into primary pointer high byte
    lda #<old_road_component_map ; load previous road segment map into A for secondary pointer low byte
    sta ptr2_lo ; store previous road segment map into secondary pointer low byte
    lda #>old_road_component_map ; load previous road segment map into A for secondary pointer high byte
    sta ptr2_hi ; store previous road segment map into secondary pointer high byte
    jsr copy_map_buffer ; call copy map buffer

    lda #<road_component_map ; load road segment map into A for secondary pointer low byte
    sta ptr2_lo ; store road segment map into secondary pointer low byte
    lda #>road_component_map ; load road segment map into A for secondary pointer high byte
    sta ptr2_hi ; store road segment map into secondary pointer high byte
    jsr clear_map_buffer ; clear the target map-sized buffer
    jsr clear_segment_used ; call clear segment used

    lda #0 ; load 0 into A for temporary slot 2
    sta tmp2 ; store 0 into temporary slot 2
; Continue with the row path.
@rrs_row:
    lda #0 ; load 0 into A for temporary slot 1
    sta tmp1 ; store 0 into temporary slot 1
; Continue with the col path.
@rrs_col:
    lda tmp1 ; load temporary slot 1 into A
    ldx tmp2 ; load temporary slot 2 into X
    jsr get_tile ; read the tile at the requested map coordinate
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_ROAD ; check for a road tile
    beq @rrs_roadlike ; if the test matched, branch to roadlike
    cmp #TILE_BRIDGE ; check for a bridge tile
    bne @rrs_next ; if the test did not match, branch to next
; Continue with the roadlike path.
; Branch target from @rrs_col if the test matched.
@rrs_roadlike:
    lda #<road_component_map ; load road segment map into A for secondary pointer low byte
    sta ptr2_lo ; store road segment map into secondary pointer low byte
    lda #>road_component_map ; load road segment map into A for secondary pointer high byte
    sta ptr2_hi ; store road segment map into secondary pointer high byte
    jsr load_metric_at ; call load metric at
    bne @rrs_next ; if the test did not match, branch to next
    lda #<road_component_map ; load road segment map into A for secondary pointer low byte
    sta ptr2_lo ; store road segment map into secondary pointer low byte
    lda #>road_component_map ; load road segment map into A for secondary pointer high byte
    sta ptr2_hi ; store road segment map into secondary pointer high byte
    lda #16 ; load 16 into A
    jsr store_metric_at ; call store metric at
    jsr expand_temp_segment ; call expand temp segment
    jsr choose_segment_id_for_temp ; call choose segment id for temp
    jsr relabel_temp_segment ; call relabel temp segment
; Continue with the next path.
; Branch target from @rrs_col if the test did not match.
; Branch target from @rrs_roadlike if the test did not match.
@rrs_next:
    inc tmp1 ; increment temporary slot 1
    lda tmp1 ; load temporary slot 1 into A
    cmp #MAP_WIDTH ; check for the end of the row
    beq @rrs_next_row ; if the test matched, branch to next row
    jmp @rrs_col ; continue at col
; Continue with the next row path.
; Branch target from @rrs_next if the test matched.
@rrs_next_row:
    inc tmp2 ; increment temporary slot 2
    lda tmp2 ; load temporary slot 2 into A
    cmp #MAP_HEIGHT ; check for the bottom of the map
    beq @rrs_done ; if the test matched, branch to done
    jmp @rrs_row ; continue at row
; Finish this local path and fall back to the caller or shared exit.
; Branch target from @rrs_next_row if the test matched.
@rrs_done:
    jsr rebuild_building_segments ; call rebuild building segments
    lda #0 ; prepare to mark road topology as up to date
    sta road_topology_dirty ; mark road topology as up to date
    rts ; Return from subroutine

; Enter the load metric at routine.
load_metric_at:
    ldy tmp2 ; load temporary slot 2 into Y
    lda mul40_lo,y ; load precomputed row*40 lookup into A
    clc ; clear carry before the next add
    adc tmp1 ; add temporary slot 1 into A
    sta ptr_lo ; store A into primary pointer low byte
    lda mul40_hi,y ; load precomputed row*40 lookup into A
    adc #0 ; fold carry into the high byte
    sta ptr_hi ; store A into primary pointer high byte
    lda ptr_lo ; load primary pointer low byte into A
    clc ; clear carry before the next add
    adc ptr2_lo ; add secondary pointer low byte into A
    sta ptr_lo ; store A into primary pointer low byte
    lda ptr_hi ; load primary pointer high byte into A
    adc ptr2_hi ; add secondary pointer high byte into A
    sta ptr_hi ; store A into primary pointer high byte
    ldy #0 ; load 0 into Y
    lda (ptr_lo),y ; load primary pointer low byte into A
    rts ; Return from subroutine

; Enter the store metric at routine.
store_metric_at:
    pha ; save A on the stack
    ldy tmp2 ; load temporary slot 2 into Y
    lda mul40_lo,y ; load precomputed row*40 lookup into A
    clc ; clear carry before the next add
    adc tmp1 ; add temporary slot 1 into A
    sta ptr_lo ; store A into primary pointer low byte
    lda mul40_hi,y ; load precomputed row*40 lookup into A
    adc #0 ; fold carry into the high byte
    sta ptr_hi ; store A into primary pointer high byte
    lda ptr_lo ; load primary pointer low byte into A
    clc ; clear carry before the next add
    adc ptr2_lo ; add secondary pointer low byte into A
    sta ptr_lo ; store A into primary pointer low byte
    lda ptr_hi ; load primary pointer high byte into A
    adc ptr2_hi ; add secondary pointer high byte into A
    sta ptr_hi ; store A into primary pointer high byte
    pla ; restore the saved A value
    ldy #0 ; load 0 into Y for primary pointer low byte
    sta (ptr_lo),y ; store 0 into primary pointer low byte
    rts ; Return from subroutine

; Enter the stamp radius add routine.
stamp_radius_add:
    lda tmp2 ; load temporary slot 2 into A
    sec ; set carry before the subtract/compare sequence
    sbc tmp3 ; subtract temporary slot 3 from A
    bcs @sra_row_lo_ok ; if carry was set, branch to row lo ok
    lda #0 ; load 0 into A for number-print value low byte
; Continue with the row lo ok path.
; Branch target from stamp_radius_add if carry was set.
@sra_row_lo_ok:
    sta np_val_lo ; store 0 into number-print value low byte

    lda tmp2 ; load temporary slot 2 into A
    clc ; clear carry before the next add
    adc tmp3 ; add temporary slot 3 into A
    cmp #MAP_HEIGHT ; check for the bottom of the map
    bcc @sra_row_hi_ok ; if carry stayed clear, branch to row hi ok
    lda #(MAP_HEIGHT - 1) ; load (MAP HEIGHT - 1 into A for number-print value high byte
; Continue with the row hi ok path.
; Branch target from @sra_row_lo_ok if carry stayed clear.
@sra_row_hi_ok:
    sta np_val_hi ; store (MAP HEIGHT - 1 into number-print value high byte

    lda tmp1 ; load temporary slot 1 into A
    sec ; set carry before the subtract/compare sequence
    sbc tmp3 ; subtract temporary slot 3 from A
    bcs @sra_col_lo_ok ; if carry was set, branch to col lo ok
    lda #0 ; load 0 into A for number-print work low byte
; Continue with the col lo ok path.
; Branch target from @sra_row_hi_ok if carry was set.
@sra_col_lo_ok:
    sta np_div_lo ; store 0 into number-print work low byte

    lda tmp1 ; load temporary slot 1 into A
    clc ; clear carry before the next add
    adc tmp3 ; add temporary slot 3 into A
    cmp #MAP_WIDTH ; check for the end of the row
    bcc @sra_col_hi_ok ; if carry stayed clear, branch to col hi ok
    lda #(MAP_WIDTH - 1) ; load (MAP WIDTH - 1 into A
; Continue with the col hi ok path.
; Branch target from @sra_col_lo_ok if carry stayed clear.
@sra_col_hi_ok:
    sec ; set carry before the subtract/compare sequence
    sbc np_div_lo ; subtract number-print work low byte from A
    clc ; clear carry before the next add
    adc #1 ; add 1 into A
    sta np_div_hi ; store A into number-print work high byte

; Continue with the row loop path.
; Branch target from @sra_store if carry was set.
@sra_row_loop:
    ldy np_val_lo ; load number-print value low byte into Y
    lda mul40_lo,y ; load precomputed row*40 lookup into A
    clc ; clear carry before the next add
    adc ptr2_lo ; add secondary pointer low byte into A
    sta ptr_lo ; store A into primary pointer low byte
    lda mul40_hi,y ; load precomputed row*40 lookup into A
    adc ptr2_hi ; add secondary pointer high byte into A
    sta ptr_hi ; store A into primary pointer high byte

    lda np_div_lo ; load number-print work low byte into A
    clc ; clear carry before the next add
    adc ptr_lo ; add primary pointer low byte into A
    sta ptr_lo ; store A into primary pointer low byte
    bcc @sra_ptr_ok ; if carry stayed clear, branch to ptr ok
    inc ptr_hi ; advance the primary pointer to the next page
; Continue with the ptr ok path.
; Branch target from @sra_row_loop if carry stayed clear.
@sra_ptr_ok:
    ldy #0 ; load 0 into Y
; Continue with the col loop path.
; Branch target from @sra_store if the test did not match.
@sra_col_loop:
    lda (ptr_lo),y ; load primary pointer low byte into A
    clc ; clear carry before the next add
    adc tmp4 ; add temporary slot 4 into A
    bcc @sra_store ; if carry stayed clear, branch to store
    lda #$FF ; load $FF into A for primary pointer low byte
; Continue with the store path.
; Branch target from @sra_col_loop if carry stayed clear.
@sra_store:
    sta (ptr_lo),y ; store $FF into primary pointer low byte
    iny ; advance Y to the next offset
    cpy np_div_hi ; number-print work high byte
    bne @sra_col_loop ; if the test did not match, branch to col loop

    inc np_val_lo ; increment number-print value low byte
    lda np_val_hi ; load number-print value high byte into A
    cmp np_val_lo ; number-print value low byte
    bcs @sra_row_loop ; if carry was set, branch to row loop
    rts ; Return from subroutine

; Enter the region has nonzero routine.
region_has_nonzero:
    lda tmp2 ; load temporary slot 2 into A
    sec ; set carry before the subtract/compare sequence
    sbc tmp3 ; subtract temporary slot 3 from A
    bcs @rhn_row_lo_ok ; if carry was set, branch to row lo ok
    lda #0 ; load 0 into A for number-print value low byte
; Continue with the row lo ok path.
; Branch target from region_has_nonzero if carry was set.
@rhn_row_lo_ok:
    sta np_val_lo ; store 0 into number-print value low byte

    lda tmp2 ; load temporary slot 2 into A
    clc ; clear carry before the next add
    adc tmp3 ; add temporary slot 3 into A
    cmp #MAP_HEIGHT ; check for the bottom of the map
    bcc @rhn_row_hi_ok ; if carry stayed clear, branch to row hi ok
    lda #(MAP_HEIGHT - 1) ; load (MAP HEIGHT - 1 into A for number-print value high byte
; Continue with the row hi ok path.
; Branch target from @rhn_row_lo_ok if carry stayed clear.
@rhn_row_hi_ok:
    sta np_val_hi ; store (MAP HEIGHT - 1 into number-print value high byte

    lda tmp1 ; load temporary slot 1 into A
    sec ; set carry before the subtract/compare sequence
    sbc tmp3 ; subtract temporary slot 3 from A
    bcs @rhn_col_lo_ok ; if carry was set, branch to col lo ok
    lda #0 ; load 0 into A for number-print work low byte
; Continue with the col lo ok path.
; Branch target from @rhn_row_hi_ok if carry was set.
@rhn_col_lo_ok:
    sta np_div_lo ; store 0 into number-print work low byte

    lda tmp1 ; load temporary slot 1 into A
    clc ; clear carry before the next add
    adc tmp3 ; add temporary slot 3 into A
    cmp #MAP_WIDTH ; check for the end of the row
    bcc @rhn_col_hi_ok ; if carry stayed clear, branch to col hi ok
    lda #(MAP_WIDTH - 1) ; load (MAP WIDTH - 1 into A
; Continue with the col hi ok path.
; Branch target from @rhn_col_lo_ok if carry stayed clear.
@rhn_col_hi_ok:
    sec ; set carry before the subtract/compare sequence
    sbc np_div_lo ; subtract number-print work low byte from A
    clc ; clear carry before the next add
    adc #1 ; add 1 into A
    sta np_div_hi ; store A into number-print work high byte

; Continue with the row loop path.
; Branch target from @rhn_col_loop if carry was set.
@rhn_row_loop:
    ldy np_val_lo ; load number-print value low byte into Y
    lda mul40_lo,y ; load precomputed row*40 lookup into A
    clc ; clear carry before the next add
    adc ptr2_lo ; add secondary pointer low byte into A
    sta ptr_lo ; store A into primary pointer low byte
    lda mul40_hi,y ; load precomputed row*40 lookup into A
    adc ptr2_hi ; add secondary pointer high byte into A
    sta ptr_hi ; store A into primary pointer high byte

    lda np_div_lo ; load number-print work low byte into A
    clc ; clear carry before the next add
    adc ptr_lo ; add primary pointer low byte into A
    sta ptr_lo ; store A into primary pointer low byte
    bcc @rhn_ptr_ok ; if carry stayed clear, branch to ptr ok
    inc ptr_hi ; advance the primary pointer to the next page
; Continue with the ptr ok path.
; Branch target from @rhn_row_loop if carry stayed clear.
@rhn_ptr_ok:
    ldy #0 ; load 0 into Y
; Continue with the col loop path.
; Branch target from @rhn_col_loop if the test did not match.
@rhn_col_loop:
    lda (ptr_lo),y ; load primary pointer low byte into A
    bne @rhn_found ; if the test did not match, branch to found
    iny ; advance Y to the next offset
    cpy np_div_hi ; number-print work high byte
    bne @rhn_col_loop ; if the test did not match, branch to col loop

    inc np_val_lo ; increment number-print value low byte
    lda np_val_hi ; load number-print value high byte into A
    cmp np_val_lo ; number-print value low byte
    bcs @rhn_row_loop ; if carry was set, branch to row loop
    lda #0 ; load 0 into A
    rts ; Return from subroutine
; Continue with the found path.
; Branch target from @rhn_col_loop if the test did not match.
@rhn_found:
    lda #1 ; load 1 into A
    rts ; Return from subroutine

; Enter the build service maps routine.
build_service_maps:
    jsr clear_sim_maps ; call clear sim maps
    lda #0 ; load 0 into A for temporary slot 2
    sta tmp2 ; store 0 into temporary slot 2
; Continue with the row path.
@bsm_row:
    lda #0 ; load 0 into A for temporary slot 1
    sta tmp1 ; store 0 into temporary slot 1
; Continue with the col path.
@bsm_col:
    lda tmp1 ; load temporary slot 1 into A
    ldx tmp2 ; load temporary slot 2 into X
    jsr get_tile ; read the tile at the requested map coordinate
    sta tmp4 ; store A into temporary slot 4
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_PARK ; park tile type
    bne @bsm_police ; if the test did not match, branch to police
    lda #<park_effect_map ; load park effect map into A for secondary pointer low byte
    sta ptr2_lo ; store park effect map into secondary pointer low byte
    lda #>park_effect_map ; load park effect map into A for secondary pointer high byte
    sta ptr2_hi ; store park effect map into secondary pointer high byte
    lda tmp4 ; load temporary slot 4 into A
    jsr get_tile_density_units ; call tile density units
    jsr mul_by_3 ; call by 3
    sta tmp4 ; store A into temporary slot 4
    lda #PARK_RADIUS ; load PARK RADIUS into A for temporary slot 3
    sta tmp3 ; store PARK RADIUS into temporary slot 3
    jsr stamp_radius_add ; call stamp radius add
    jmp @bsm_next ; continue at next

; Continue with the police path.
; Branch target from @bsm_col if the test did not match.
@bsm_police:
    cmp #TILE_POLICE ; police tile type
    bne @bsm_fire ; if the test did not match, branch to fire
    lda #<police_effect_map ; load police coverage map into A for secondary pointer low byte
    sta ptr2_lo ; store police coverage map into secondary pointer low byte
    lda #>police_effect_map ; load police coverage map into A for secondary pointer high byte
    sta ptr2_hi ; store police coverage map into secondary pointer high byte
    lda tmp4 ; load temporary slot 4 into A
    jsr get_tile_density_units ; call tile density units
    jsr mul_by_2 ; call by 2
    sta tmp4 ; store A into temporary slot 4
    lda #POLICE_RADIUS ; load POLICE RADIUS into A for temporary slot 3
    sta tmp3 ; store POLICE RADIUS into temporary slot 3
    jsr stamp_radius_add ; call stamp radius add
    jmp @bsm_next ; continue at next

; Continue with the fire path.
; Branch target from @bsm_police if the test did not match.
@bsm_fire:
    cmp #TILE_FIRE ; fire-station tile type
    bne @bsm_house ; if the test did not match, branch to house
    lda #<fire_effect_map ; load fire coverage map into A for secondary pointer low byte
    sta ptr2_lo ; store fire coverage map into secondary pointer low byte
    lda #>fire_effect_map ; load fire coverage map into A for secondary pointer high byte
    sta ptr2_hi ; store fire coverage map into secondary pointer high byte
    lda tmp4 ; load temporary slot 4 into A
    jsr get_tile_density_units ; call tile density units
    jsr mul_by_2 ; call by 2
    sta tmp4 ; store A into temporary slot 4
    lda #FIRE_RADIUS ; load FIRE RADIUS into A for temporary slot 3
    sta tmp3 ; store FIRE RADIUS into temporary slot 3
    jsr stamp_radius_add ; call stamp radius add
    jmp @bsm_next ; continue at next

; Continue with the house path.
; Branch target from @bsm_fire if the test did not match.
@bsm_house:
    cmp #TILE_HOUSE ; house tile type
    bne @bsm_factory ; if the test did not match, branch to factory
    lda #<house_zone_map ; load house zone map into A for secondary pointer low byte
    sta ptr2_lo ; store house zone map into secondary pointer low byte
    lda #>house_zone_map ; load house zone map into A for secondary pointer high byte
    sta ptr2_hi ; store house zone map into secondary pointer high byte
    lda tmp4 ; load temporary slot 4 into A
    jsr get_tile_density_units ; call tile density units
    tax ; move A into X for the upcoming table lookup
    lda house_aoe_radius,x ; load house aoe radius into A
    sta tmp3 ; store house aoe radius into temporary slot 3
    lda #1 ; load 1 into A for temporary slot 4
    sta tmp4 ; store 1 into temporary slot 4
    jsr stamp_radius_add ; call stamp radius add
    jmp @bsm_next ; continue at next

; Continue with the factory path.
; Branch target from @bsm_house if the test did not match.
@bsm_factory:
    cmp #TILE_FACTORY ; factory tile type
    bne @bsm_next ; if the test did not match, branch to next
    lda #<factory_zone_map ; load factory zone map into A for secondary pointer low byte
    sta ptr2_lo ; store factory zone map into secondary pointer low byte
    lda #>factory_zone_map ; load factory zone map into A for secondary pointer high byte
    sta ptr2_hi ; store factory zone map into secondary pointer high byte
    lda tmp4 ; load temporary slot 4 into A
    jsr get_tile_density_units ; call tile density units
    tax ; move A into X for the upcoming table lookup
    lda factory_aoe_radius,x ; load factory aoe radius into A
    sta tmp3 ; store factory aoe radius into temporary slot 3
    lda #1 ; load 1 into A for temporary slot 4
    sta tmp4 ; store 1 into temporary slot 4
    jsr stamp_radius_add ; call stamp radius add

; Continue with the next path.
; Branch target from @bsm_factory if the test did not match.
@bsm_next:
    inc tmp1 ; increment temporary slot 1
    lda tmp1 ; load temporary slot 1 into A
    cmp #MAP_WIDTH ; check for the end of the row
    beq @bsm_next_row ; if the test matched, branch to next row
    jmp @bsm_col ; continue at col
; Continue with the next row path.
; Branch target from @bsm_next if the test matched.
@bsm_next_row:
    inc tmp2 ; increment temporary slot 2
    lda tmp2 ; load temporary slot 2 into A
    cmp #MAP_HEIGHT ; check for the bottom of the map
    beq @bsm_done ; if the test matched, branch to done
    jmp @bsm_row ; continue at row
; Finish this local path and fall back to the caller or shared exit.
; Branch target from @bsm_next_row if the test matched.
@bsm_done:
    rts ; Return from subroutine

; Enter the apply neighbor value effect routine.
apply_neighbor_value_effect:
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_ROAD ; check for a road tile
    beq @anv_road ; if the test matched, branch to road
    cmp #TILE_BRIDGE ; check for a bridge tile
    bne @anv_house ; if the test did not match, branch to house
; Continue with the road path.
; Branch target from apply_neighbor_value_effect if the test matched.
@anv_road:
    lda #1 ; load 1 into A for road mask
    sta road_mask ; store 1 into road mask
    lda #VALUE_BONUS_ROAD ; load VALUE BONUS ROAD into A
    jmp add_a_to_tmp3 ; continue at a to tmp3

; Continue with the house path.
; Branch target from apply_neighbor_value_effect if the test did not match.
@anv_house:
    cmp #TILE_HOUSE ; house tile type
    bne @anv_factory ; if the test did not match, branch to factory
    lda #VALUE_BONUS_HOUSE ; load VALUE BONUS HOUSE into A
    jmp add_a_to_tmp3 ; continue at a to tmp3

; Continue with the factory path.
; Branch target from @anv_house if the test did not match.
@anv_factory:
    cmp #TILE_FACTORY ; factory tile type
    bne @anv_park ; if the test did not match, branch to park
    lda tmp3 ; load temporary slot 3 into A
    cmp #VALUE_PENALTY_FACTORY ; VALUE PENALTY FACTORY
    bcs @anv_sub_factory ; if carry was set, branch to sub factory
    lda #0 ; load 0 into A for temporary slot 3
    sta tmp3 ; store 0 into temporary slot 3
    rts ; Return from subroutine
; Continue with the sub factory path.
; Branch target from @anv_factory if carry was set.
@anv_sub_factory:
    sec ; set carry before the subtract/compare sequence
    sbc #VALUE_PENALTY_FACTORY ; subtract VALUE PENALTY FACTORY from A
    sta tmp3 ; store A into temporary slot 3
    rts ; Return from subroutine

; Continue with the park path.
; Branch target from @anv_factory if the test did not match.
@anv_park:
    cmp #TILE_PARK ; park tile type
    bne @anv_power ; if the test did not match, branch to power
    lda #VALUE_BONUS_PARK ; load VALUE BONUS PARK into A
    jmp add_a_to_tmp3 ; continue at a to tmp3

; Continue with the power path.
; Branch target from @anv_park if the test did not match.
@anv_power:
    cmp #TILE_POWER ; power-plant tile type
    bne @anv_police ; if the test did not match, branch to police
    lda tmp3 ; load temporary slot 3 into A
    cmp #VALUE_PENALTY_POWER ; VALUE PENALTY POWER
    bcs @anv_sub_power ; if carry was set, branch to sub power
    lda #0 ; load 0 into A for temporary slot 3
    sta tmp3 ; store 0 into temporary slot 3
    rts ; Return from subroutine
; Continue with the sub power path.
; Branch target from @anv_power if carry was set.
@anv_sub_power:
    sec ; set carry before the subtract/compare sequence
    sbc #VALUE_PENALTY_POWER ; subtract VALUE PENALTY POWER from A
    sta tmp3 ; store A into temporary slot 3
    rts ; Return from subroutine

; Continue with the police path.
; Branch target from @anv_power if the test did not match.
@anv_police:
    cmp #TILE_POLICE ; police tile type
    beq @anv_service ; if the test matched, branch to service
    cmp #TILE_FIRE ; fire-station tile type
    bne @anv_done ; if the test did not match, branch to done
; Continue with the service path.
; Branch target from @anv_police if the test matched.
@anv_service:
    lda #VALUE_BONUS_SERVICE ; load VALUE BONUS SERVICE into A
    jmp add_a_to_tmp3 ; continue at a to tmp3
; Finish this local path and fall back to the caller or shared exit.
; Branch target from @anv_police if the test did not match.
@anv_done:
    rts ; Return from subroutine

; Enter the compute tile value at routine.
compute_tile_value_at:
    lda tmp1 ; load temporary slot 1 into A
    ldx tmp2 ; load temporary slot 2 into X
    jsr get_tile ; read the tile at the requested map coordinate
    sta tmp4 ; store A into temporary slot 4
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    tax ; move A into X for the upcoming table lookup
    lda #0 ; load 0 into A
    cpx #TILE_ROAD ; check for a road tile
    beq @ctv_road ; if the test matched, branch to road
    cpx #TILE_BRIDGE ; check for a bridge tile
    bne @ctv_house ; if the test did not match, branch to house
; Continue with the road path.
; Branch target from compute_tile_value_at if the test matched.
@ctv_road:
    lda #VALUE_BASE_ROAD ; load VALUE BASE ROAD into A
    bne @ctv_base_done ; if the test did not match, branch to base done
; Continue with the house path.
; Branch target from compute_tile_value_at if the test did not match.
@ctv_house:
    cpx #TILE_HOUSE ; house tile type
    bne @ctv_factory ; if the test did not match, branch to factory
    lda #VALUE_BASE_HOUSE ; load VALUE BASE HOUSE into A
    bne @ctv_base_done ; if the test did not match, branch to base done
; Continue with the factory path.
; Branch target from @ctv_house if the test did not match.
@ctv_factory:
    cpx #TILE_FACTORY ; factory tile type
    bne @ctv_park ; if the test did not match, branch to park
    lda #VALUE_BASE_FACTORY ; load VALUE BASE FACTORY into A
    bne @ctv_base_done ; if the test did not match, branch to base done
; Continue with the park path.
; Branch target from @ctv_factory if the test did not match.
@ctv_park:
    cpx #TILE_PARK ; park tile type
    bne @ctv_power ; if the test did not match, branch to power
    lda #VALUE_BASE_PARK ; load VALUE BASE PARK into A
    bne @ctv_base_done ; if the test did not match, branch to base done
; Continue with the power path.
; Branch target from @ctv_park if the test did not match.
@ctv_power:
    cpx #TILE_POWER ; power-plant tile type
    bne @ctv_police ; if the test did not match, branch to police
    lda #VALUE_BASE_POWER ; load VALUE BASE POWER into A
    bne @ctv_base_done ; if the test did not match, branch to base done
; Continue with the police path.
; Branch target from @ctv_power if the test did not match.
@ctv_police:
    cpx #TILE_POLICE ; police tile type
    bne @ctv_fire ; if the test did not match, branch to fire
    lda #VALUE_BASE_POLICE ; load VALUE BASE POLICE into A
    bne @ctv_base_done ; if the test did not match, branch to base done
; Continue with the fire path.
; Branch target from @ctv_police if the test did not match.
@ctv_fire:
    cpx #TILE_FIRE ; fire-station tile type
    bne @ctv_base_done ; if the test did not match, branch to base done
    lda #VALUE_BASE_FIRE ; load VALUE BASE FIRE into A for temporary slot 3
; Continue with the base completion path.
; Branch target from @ctv_road if the test did not match.
; Branch target from @ctv_house if the test did not match.
; Branch target from @ctv_factory if the test did not match.
; Branch target from @ctv_park if the test did not match.
; Branch target from @ctv_power if the test did not match.
; Branch target from @ctv_police if the test did not match.
; Branch target from @ctv_fire if the test did not match.
@ctv_base_done:
    sta tmp3 ; store VALUE BASE FIRE into temporary slot 3

    lda tmp4 ; load temporary slot 4 into A
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    beq @ctv_effects ; if the test matched, branch to effects
    cmp #(TILE_BRIDGE + 1) ; (TILE BRIDGE + 1
    bcs @ctv_effects ; if carry was set, branch to effects
    lda tmp4 ; load temporary slot 4 into A
    jsr get_tile_density_units ; call tile density units
    asl ; shift A left to multiply by two
    asl ; shift A left to multiply by two
    jsr add_a_to_tmp3 ; call a to tmp3

; Continue with the effects path.
; Branch target from @ctv_base_done if the test matched.
; Branch target from @ctv_base_done if carry was set.
@ctv_effects:
    lda #<park_effect_map ; load park effect map into A for secondary pointer low byte
    sta ptr2_lo ; store park effect map into secondary pointer low byte
    lda #>park_effect_map ; load park effect map into A for secondary pointer high byte
    sta ptr2_hi ; store park effect map into secondary pointer high byte
    jsr load_metric_at ; call load metric at
    jsr add_a_to_tmp3 ; call a to tmp3

    lda tmp4 ; load temporary slot 4 into A
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_HOUSE ; house tile type
    beq @ctv_public_safety ; if the test matched, branch to public safety
    cmp #TILE_FACTORY ; factory tile type
    beq @ctv_public_safety ; if the test matched, branch to public safety
    jmp @ctv_neighbors ; continue at neighbors

; Continue with the public safety path.
; Branch target from @ctv_effects if the test matched.
; Branch target from @ctv_effects if the test matched.
@ctv_public_safety:
    lda #<police_effect_map ; load police coverage map into A for secondary pointer low byte
    sta ptr2_lo ; store police coverage map into secondary pointer low byte
    lda #>police_effect_map ; load police coverage map into A for secondary pointer high byte
    sta ptr2_hi ; store police coverage map into secondary pointer high byte
    jsr load_metric_at ; call load metric at
    jsr add_a_to_tmp3 ; call a to tmp3

    lda #<fire_effect_map ; load fire coverage map into A for secondary pointer low byte
    sta ptr2_lo ; store fire coverage map into secondary pointer low byte
    lda #>fire_effect_map ; load fire coverage map into A for secondary pointer high byte
    sta ptr2_hi ; store fire coverage map into secondary pointer high byte
    jsr load_metric_at ; call load metric at
    jsr add_a_to_tmp3 ; call a to tmp3

; Continue with the neighbors path.
@ctv_neighbors:
    lda #0 ; load 0 into A for road mask
    sta road_mask ; store 0 into road mask

    lda tmp2 ; load temporary slot 2 into A
    beq @ctv_south ; if the test matched, branch to south
    lda tmp1 ; load temporary slot 1 into A
    ldx tmp2 ; load temporary slot 2 into X
    dex ; step X back one slot
    jsr get_tile ; read the tile at the requested map coordinate
    jsr apply_neighbor_value_effect ; call apply neighbor value effect

; Continue with the south neighbor path.
; Branch target from @ctv_neighbors if the test matched.
@ctv_south:
    lda tmp2 ; load temporary slot 2 into A
    cmp #(MAP_HEIGHT - 1) ; (MAP HEIGHT - 1
    bcs @ctv_east ; if carry was set, branch to east
    lda tmp1 ; load temporary slot 1 into A
    ldx tmp2 ; load temporary slot 2 into X
    inx ; advance X to the next index
    jsr get_tile ; read the tile at the requested map coordinate
    jsr apply_neighbor_value_effect ; call apply neighbor value effect

; Continue with the east neighbor path.
; Branch target from @ctv_south if carry was set.
@ctv_east:
    lda tmp1 ; load temporary slot 1 into A
    cmp #(MAP_WIDTH - 1) ; (MAP WIDTH - 1
    bcs @ctv_west ; if carry was set, branch to west
    lda tmp1 ; load temporary slot 1 into A
    clc ; clear carry before the next add
    adc #1 ; add 1 into A
    ldx tmp2 ; load temporary slot 2 into X
    jsr get_tile ; read the tile at the requested map coordinate
    jsr apply_neighbor_value_effect ; call apply neighbor value effect

; Continue with the west neighbor path.
; Branch target from @ctv_east if carry was set.
@ctv_west:
    lda tmp1 ; load temporary slot 1 into A
    beq @ctv_need_road ; if the test matched, branch to need road
    lda tmp1 ; load temporary slot 1 into A
    sec ; set carry before the subtract/compare sequence
    sbc #1 ; subtract 1 from A
    ldx tmp2 ; load temporary slot 2 into X
    jsr get_tile ; read the tile at the requested map coordinate
    jsr apply_neighbor_value_effect ; call apply neighbor value effect

; Continue with the need road path.
; Branch target from @ctv_west if the test matched.
@ctv_need_road:
    lda tmp4 ; load temporary slot 4 into A
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_HOUSE ; house tile type
    beq @ctv_check_road ; if the test matched, branch to check road
    cmp #TILE_FACTORY ; factory tile type
    bne @ctv_clamp ; if the test did not match, branch to clamp
; Check road.
; Branch target from @ctv_need_road if the test matched.
@ctv_check_road:
    lda road_mask ; load road mask into A
    bne @ctv_clamp ; if the test did not match, branch to clamp
    lda tmp3 ; load temporary slot 3 into A
    cmp #VALUE_PENALTY_NO_ROAD ; VALUE PENALTY NO ROAD
    bcs @ctv_sub_no_road ; if carry was set, branch to sub no road
    lda #0 ; load 0 into A for temporary slot 3
    sta tmp3 ; store 0 into temporary slot 3
    beq @ctv_clamp ; if the test matched, branch to clamp
; Continue with the sub no road path.
; Branch target from @ctv_check_road if carry was set.
@ctv_sub_no_road:
    sec ; set carry before the subtract/compare sequence
    sbc #VALUE_PENALTY_NO_ROAD ; subtract VALUE PENALTY NO ROAD from A
    sta tmp3 ; store A into temporary slot 3

; Continue with the clamp path.
; Branch target from @ctv_need_road if the test did not match.
; Branch target from @ctv_check_road if the test did not match.
; Branch target from @ctv_check_road if the test matched.
@ctv_clamp:
    lda tmp3 ; load temporary slot 3 into A
    cmp #(VALUE_CAP + 1) ; (VALUE CAP + 1
    bcc @ctv_done ; if carry stayed clear, branch to done
    lda #VALUE_CAP ; load VALUE CAP into A
; Finish this local path and fall back to the caller or shared exit.
; Branch target from @ctv_clamp if carry stayed clear.
@ctv_done:
    rts ; Return from subroutine

; Enter the analyze city tiles routine.
analyze_city_tiles:
    lda #0 ; load 0 into A for park coverage
    sta park_coverage ; store 0 into park coverage
    sta police_coverage ; store A into police coverage
    sta fire_coverage ; store A into fire coverage
    sta land_value_lo ; store A into land value low byte
    sta land_value_hi ; store A into land value high byte
    sta jobs_total ; store A into jobs total
    sta employed_pop ; store A into worker supply total
    sta tmp2 ; store A into temporary slot 2

; Continue with the row path.
@act_row:
    lda #0 ; load 0 into A for temporary slot 1
    sta tmp1 ; store 0 into temporary slot 1
; Continue with the col path.
@act_col:
    jsr compute_tile_value_at ; call compute tile value at
    sta tmp3 ; store A into temporary slot 3

    lda #<tile_value_map ; load tile value map into A for secondary pointer low byte
    sta ptr2_lo ; store tile value map into secondary pointer low byte
    lda #>tile_value_map ; load tile value map into A for secondary pointer high byte
    sta ptr2_hi ; store tile value map into secondary pointer high byte
    lda tmp3 ; load temporary slot 3 into A
    jsr store_metric_at ; call store metric at

    lda tmp4 ; load temporary slot 4 into A
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_HOUSE ; house tile type
    bne @act_check_factory ; if the test did not match, branch to check factory
    jmp @act_house ; continue at house
; Check factory.
; Branch target from @act_col if the test did not match.
@act_check_factory:
    cmp #TILE_FACTORY ; factory tile type
    bne @act_check_police ; if the test did not match, branch to check police
    jmp @act_factory ; continue at factory
; Check police.
; Branch target from @act_check_factory if the test did not match.
@act_check_police:
    cmp #TILE_POLICE ; police tile type
    bne @act_check_fire ; if the test did not match, branch to check fire
    jmp @act_police_jobs ; continue at police jobs
; Check fire.
; Branch target from @act_check_police if the test did not match.
@act_check_fire:
    cmp #TILE_FIRE ; fire-station tile type
    bne @act_other ; if the test did not match, branch to other
    jmp @act_fire_jobs ; continue at fire jobs
; Continue with the other path.
; Branch target from @act_check_fire if the test did not match.
@act_other:
    jmp @act_next ; continue at next

; Continue with the house path.
@act_house:
    lda tmp4 ; load temporary slot 4 into A
    jsr get_tile_density_units ; call tile density units
    sta road_mask ; store A into road mask
    ldx road_mask ; load road mask into X
; Continue with the value loop path.
; Branch target from @act_value_loop if the test did not match.
@act_value_loop:
    lda tmp3 ; load temporary slot 3 into A
    jsr add_to_land_value ; call to land value
    dex ; step X back one slot
    bne @act_value_loop ; if the test did not match, branch to value loop

    lda #<park_effect_map ; load park effect map into A for secondary pointer low byte
    sta ptr2_lo ; store park effect map into secondary pointer low byte
    lda #>park_effect_map ; load park effect map into A for secondary pointer high byte
    sta ptr2_hi ; store park effect map into secondary pointer high byte
    jsr load_metric_at ; call load metric at
    beq @act_police ; if the test matched, branch to police
    lda park_coverage ; load park coverage into A
    clc ; clear carry before the next add
    adc road_mask ; add road mask into A
    bcc @act_store_park ; if carry stayed clear, branch to store park
    lda #$FF ; load $FF into A for park coverage
; Continue with the store park path.
; Branch target from @act_value_loop if carry stayed clear.
@act_store_park:
    sta park_coverage ; store $FF into park coverage

; Continue with the police path.
; Branch target from @act_value_loop if the test matched.
@act_police:
    lda #<police_effect_map ; load police coverage map into A for secondary pointer low byte
    sta ptr2_lo ; store police coverage map into secondary pointer low byte
    lda #>police_effect_map ; load police coverage map into A for secondary pointer high byte
    sta ptr2_hi ; store police coverage map into secondary pointer high byte
    jsr load_metric_at ; call load metric at
    beq @act_fire ; if the test matched, branch to fire
    lda police_coverage ; load police coverage into A
    clc ; clear carry before the next add
    adc road_mask ; add road mask into A
    bcc @act_store_police ; if carry stayed clear, branch to store police
    lda #$FF ; load $FF into A for police coverage
; Continue with the store police path.
; Branch target from @act_police if carry stayed clear.
@act_store_police:
    sta police_coverage ; store $FF into police coverage

; Continue with the fire path.
; Branch target from @act_police if the test matched.
@act_fire:
    lda #<fire_effect_map ; load fire coverage map into A for secondary pointer low byte
    sta ptr2_lo ; store fire coverage map into secondary pointer low byte
    lda #>fire_effect_map ; load fire coverage map into A for secondary pointer high byte
    sta ptr2_hi ; store fire coverage map into secondary pointer high byte
    jsr load_metric_at ; call load metric at
    beq @act_worker ; if the test matched, branch to worker
    lda fire_coverage ; load fire coverage into A
    clc ; clear carry before the next add
    adc road_mask ; add road mask into A
    bcc @act_store_fire ; if carry stayed clear, branch to store fire
    lda #$FF ; load $FF into A for fire coverage
; Continue with the store fire path.
; Branch target from @act_fire if carry stayed clear.
@act_store_fire:
    sta fire_coverage ; store $FF into fire coverage
; Continue with the worker path.
; Branch target from @act_fire if the test matched.
@act_worker:
    lda road_mask ; load road mask into A
    jsr mul_by_10 ; call by 10
    jsr add_to_worker_supply ; call to worker supply
    jmp @act_next ; continue at next

; Continue with the factory path.
@act_factory:
    lda tmp4 ; load temporary slot 4 into A
    jsr get_tile_density_units ; call tile density units
    sta road_mask ; store A into road mask
    sta tmp3 ; store A into temporary slot 3
    lda #<house_zone_map ; load house zone map into A for secondary pointer low byte
    sta ptr2_lo ; store house zone map into secondary pointer low byte
    lda #>house_zone_map ; load house zone map into A for secondary pointer high byte
    sta ptr2_hi ; store house zone map into secondary pointer high byte
    jsr region_has_nonzero ; call region has nonzero
    beq @act_next ; if the test matched, branch to next
    lda road_mask ; load road mask into A
    jsr mul_by_10 ; call by 10
    jsr add_to_jobs ; call to jobs
    jmp @act_next ; continue at next

; Continue with the police jobs path.
@act_police_jobs:
    lda #<house_zone_map ; load house zone map into A for secondary pointer low byte
    sta ptr2_lo ; store house zone map into secondary pointer low byte
    lda #>house_zone_map ; load house zone map into A for secondary pointer high byte
    sta ptr2_hi ; store house zone map into secondary pointer high byte
    jsr load_metric_at ; call load metric at
    beq @act_next ; if the test matched, branch to next
    lda tmp4 ; load temporary slot 4 into A
    jsr get_tile_density_units ; call tile density units
    jsr mul_by_2 ; call by 2
    jsr add_to_jobs ; call to jobs
    jmp @act_next ; continue at next

; Continue with the fire jobs path.
@act_fire_jobs:
    lda #<house_zone_map ; load house zone map into A for secondary pointer low byte
    sta ptr2_lo ; store house zone map into secondary pointer low byte
    lda #>house_zone_map ; load house zone map into A for secondary pointer high byte
    sta ptr2_hi ; store house zone map into secondary pointer high byte
    jsr load_metric_at ; call load metric at
    beq @act_next ; if the test matched, branch to next
    lda tmp4 ; load temporary slot 4 into A
    jsr get_tile_density_units ; call tile density units
    jsr mul_by_2 ; call by 2
    jsr add_to_jobs ; call to jobs

; Continue with the next path.
; Branch target from @act_factory if the test matched.
; Branch target from @act_police_jobs if the test matched.
; Branch target from @act_fire_jobs if the test matched.
@act_next:
    inc tmp1 ; increment temporary slot 1
    lda tmp1 ; load temporary slot 1 into A
    cmp #MAP_WIDTH ; check for the end of the row
    beq @act_next_row ; if the test matched, branch to next row
    jmp @act_col ; continue at col
; Continue with the next row path.
; Branch target from @act_next if the test matched.
@act_next_row:
    inc tmp2 ; increment temporary slot 2
    lda tmp2 ; load temporary slot 2 into A
    cmp #MAP_HEIGHT ; check for the bottom of the map
    beq @act_done ; if the test matched, branch to done
    jmp @act_row ; continue at row
; Finish this local path and fall back to the caller or shared exit.
; Branch target from @act_next_row if the test matched.
@act_done:
    rts ; Return from subroutine

; Enter the to component jobs routine.
add_to_component_jobs:
    clc ; clear carry before the next add
    adc component_jobs ; add current component jobs into A
    bcc @acj_store ; if carry stayed clear, branch to store
    lda #$FF ; load $FF into A for current component jobs
; Continue with the store path.
; Branch target from add_to_component_jobs if carry stayed clear.
@acj_store:
    sta component_jobs ; store $FF into current component jobs
    rts ; Return from subroutine

; Enter the to component workers routine.
add_to_component_workers:
    clc ; clear carry before the next add
    adc component_workers ; add current component workers into A
    bcc @acw_store ; if carry stayed clear, branch to store
    lda #$FF ; load $FF into A for current component workers
; Continue with the store path.
; Branch target from add_to_component_workers if carry stayed clear.
@acw_store:
    sta component_workers ; store $FF into current component workers
    rts ; Return from subroutine

; Enter the touches current road component routine.
touches_current_road_component:
    lda tmp1 ; load temporary slot 1 into A
    sta road_mask ; store temporary slot 1 into road mask
    lda tmp2 ; load temporary slot 2 into A
    sta np_val_lo ; store temporary slot 2 into number-print value low byte

    lda #<road_component_map ; load road segment map into A for secondary pointer low byte
    sta ptr2_lo ; store road segment map into secondary pointer low byte
    lda #>road_component_map ; load road segment map into A for secondary pointer high byte
    sta ptr2_hi ; store road segment map into secondary pointer high byte

    lda np_val_lo ; load number-print value low byte into A
    beq @trc_south ; if the test matched, branch to south
    lda road_mask ; load road mask into A
    sta tmp1 ; store road mask into temporary slot 1
    lda np_val_lo ; load number-print value low byte into A
    sec ; set carry before the subtract/compare sequence
    sbc #1 ; subtract 1 from A
    sta tmp2 ; store A into temporary slot 2
    jsr load_metric_at ; call load metric at
    cmp #1 ; 1
    beq @trc_yes ; if the test matched, branch to yes

; Continue with the south neighbor path.
; Branch target from touches_current_road_component if the test matched.
@trc_south:
    lda np_val_lo ; load number-print value low byte into A
    cmp #(MAP_HEIGHT - 1) ; (MAP HEIGHT - 1
    bcs @trc_east ; if carry was set, branch to east
    lda road_mask ; load road mask into A
    sta tmp1 ; store road mask into temporary slot 1
    lda np_val_lo ; load number-print value low byte into A
    clc ; clear carry before the next add
    adc #1 ; add 1 into A
    sta tmp2 ; store A into temporary slot 2
    jsr load_metric_at ; call load metric at
    cmp #1 ; 1
    beq @trc_yes ; if the test matched, branch to yes

; Continue with the east neighbor path.
; Branch target from @trc_south if carry was set.
@trc_east:
    lda road_mask ; load road mask into A
    cmp #(MAP_WIDTH - 1) ; (MAP WIDTH - 1
    bcs @trc_west ; if carry was set, branch to west
    clc ; clear carry before the next add
    adc #1 ; add 1 into A
    sta tmp1 ; store A into temporary slot 1
    lda np_val_lo ; load number-print value low byte into A
    sta tmp2 ; store number-print value low byte into temporary slot 2
    jsr load_metric_at ; call load metric at
    cmp #1 ; 1
    beq @trc_yes ; if the test matched, branch to yes

; Continue with the west neighbor path.
; Branch target from @trc_east if carry was set.
@trc_west:
    lda road_mask ; load road mask into A
    beq @trc_no ; if the test matched, branch to no
    sec ; set carry before the subtract/compare sequence
    sbc #1 ; subtract 1 from A
    sta tmp1 ; store A into temporary slot 1
    lda np_val_lo ; load number-print value low byte into A
    sta tmp2 ; store number-print value low byte into temporary slot 2
    jsr load_metric_at ; call load metric at
    cmp #1 ; 1
    beq @trc_yes ; if the test matched, branch to yes

; Continue with the no path.
; Branch target from @trc_west if the test matched.
@trc_no:
    lda road_mask ; load road mask into A
    sta tmp1 ; store road mask into temporary slot 1
    lda np_val_lo ; load number-print value low byte into A
    sta tmp2 ; store number-print value low byte into temporary slot 2
    lda #0 ; load 0 into A
    rts ; Return from subroutine

; Continue with the yes path.
; Branch target from touches_current_road_component if the test matched.
; Branch target from @trc_south if the test matched.
; Branch target from @trc_east if the test matched.
; Branch target from @trc_west if the test matched.
@trc_yes:
    lda road_mask ; load road mask into A
    sta tmp1 ; store road mask into temporary slot 1
    lda np_val_lo ; load number-print value low byte into A
    sta tmp2 ; store number-print value low byte into temporary slot 2
    lda #1 ; load 1 into A
    rts ; Return from subroutine

; Enter the expand current road component routine.
expand_current_road_component:
; Continue with the pass path.
; Branch target from @erc_pass_done if the test did not match.
@erc_pass:
    lda #0 ; clear the component-changed flag
    sta component_changed ; clear the component-changed flag
    sta tmp2 ; store A into temporary slot 2

; Continue with the row path.
@erc_row:
    lda #0 ; load 0 into A for temporary slot 1
    sta tmp1 ; store 0 into temporary slot 1
; Continue with the col path.
@erc_col:
    lda tmp1 ; load temporary slot 1 into A
    ldx tmp2 ; load temporary slot 2 into X
    jsr get_tile ; read the tile at the requested map coordinate
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_ROAD ; check for a road tile
    beq @erc_roadlike ; if the test matched, branch to roadlike
    cmp #TILE_BRIDGE ; check for a bridge tile
    bne @erc_next ; if the test did not match, branch to next
; Continue with the roadlike path.
; Branch target from @erc_col if the test matched.
@erc_roadlike:

    lda #<road_component_map ; load road segment map into A for secondary pointer low byte
    sta ptr2_lo ; store road segment map into secondary pointer low byte
    lda #>road_component_map ; load road segment map into A for secondary pointer high byte
    sta ptr2_hi ; store road segment map into secondary pointer high byte
    jsr load_metric_at ; call load metric at
    bne @erc_next ; if the test did not match, branch to next

    jsr touches_current_road_component ; call touches current road component
    beq @erc_next ; if the test matched, branch to next

    lda #<road_component_map ; load road segment map into A for secondary pointer low byte
    sta ptr2_lo ; store road segment map into secondary pointer low byte
    lda #>road_component_map ; load road segment map into A for secondary pointer high byte
    sta ptr2_hi ; store road segment map into secondary pointer high byte
    lda #1 ; load 1 into A
    jsr store_metric_at ; call store metric at
    lda #1 ; set the component-changed flag
    sta component_changed ; set the component-changed flag

; Continue with the next path.
; Branch target from @erc_col if the test did not match.
; Branch target from @erc_roadlike if the test did not match.
; Branch target from @erc_roadlike if the test matched.
@erc_next:
    inc tmp1 ; increment temporary slot 1
    lda tmp1 ; load temporary slot 1 into A
    cmp #MAP_WIDTH ; check for the end of the row
    beq @erc_next_row ; if the test matched, branch to next row
    jmp @erc_col ; continue at col
; Continue with the next row path.
; Branch target from @erc_next if the test matched.
@erc_next_row:
    inc tmp2 ; increment temporary slot 2
    lda tmp2 ; load temporary slot 2 into A
    cmp #MAP_HEIGHT ; check for the bottom of the map
    beq @erc_pass_done ; if the test matched, branch to pass done
    jmp @erc_row ; continue at row

; Continue with the pass completion path.
; Branch target from @erc_next_row if the test matched.
@erc_pass_done:
    lda component_changed ; load component change flag into A
    bne @erc_pass ; if the test did not match, branch to pass
    rts ; Return from subroutine

; Enter the mark current road component processed routine.
mark_current_road_component_processed:
    lda #0 ; load 0 into A for temporary slot 2
    sta tmp2 ; store 0 into temporary slot 2
; Continue with the row path.
@mrc_row:
    lda #0 ; load 0 into A for temporary slot 1
    sta tmp1 ; store 0 into temporary slot 1
; Continue with the col path.
@mrc_col:
    lda #<road_component_map ; load road segment map into A for secondary pointer low byte
    sta ptr2_lo ; store road segment map into secondary pointer low byte
    lda #>road_component_map ; load road segment map into A for secondary pointer high byte
    sta ptr2_hi ; store road segment map into secondary pointer high byte
    jsr load_metric_at ; call load metric at
    cmp #1 ; 1
    bne @mrc_next ; if the test did not match, branch to next
    lda #<road_component_map ; load road segment map into A for secondary pointer low byte
    sta ptr2_lo ; store road segment map into secondary pointer low byte
    lda #>road_component_map ; load road segment map into A for secondary pointer high byte
    sta ptr2_hi ; store road segment map into secondary pointer high byte
    lda #2 ; load 2 into A
    jsr store_metric_at ; call store metric at
; Continue with the next path.
; Branch target from @mrc_col if the test did not match.
@mrc_next:
    inc tmp1 ; increment temporary slot 1
    lda tmp1 ; load temporary slot 1 into A
    cmp #MAP_WIDTH ; check for the end of the row
    beq @mrc_next_row ; if the test matched, branch to next row
    jmp @mrc_col ; continue at col
; Continue with the next row path.
; Branch target from @mrc_next if the test matched.
@mrc_next_row:
    inc tmp2 ; increment temporary slot 2
    lda tmp2 ; load temporary slot 2 into A
    cmp #MAP_HEIGHT ; check for the bottom of the map
    beq @mrc_done ; if the test matched, branch to done
    jmp @mrc_row ; continue at row
; Finish this local path and fall back to the caller or shared exit.
; Branch target from @mrc_next_row if the test matched.
@mrc_done:
    rts ; Return from subroutine

; Enter the score current road component routine.
score_current_road_component:
    lda #0 ; load 0 into A for current component jobs
    sta component_jobs ; store 0 into current component jobs
    sta component_workers ; store A into current component workers
    sta tmp2 ; store A into temporary slot 2

; Continue with the row path.
@src_row:
    lda #0 ; load 0 into A for temporary slot 1
    sta tmp1 ; store 0 into temporary slot 1
; Continue with the col path.
@src_col:
    lda tmp1 ; load temporary slot 1 into A
    ldx tmp2 ; load temporary slot 2 into X
    jsr get_tile ; read the tile at the requested map coordinate
    sta tmp4 ; store A into temporary slot 4
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    bne @src_not_empty ; if the test did not match, branch to not empty
    jmp @src_next ; continue at next
; Continue with the not empty path.
; Branch target from @src_col if the test did not match.
@src_not_empty:
    cmp #TILE_WATER ; check for water
    bne @src_not_water ; if the test did not match, branch to not water
    jmp @src_next ; continue at next
; Continue with the not water path.
; Branch target from @src_not_empty if the test did not match.
@src_not_water:
    cmp #TILE_TREE ; check for an unbuildable tree tile
    bne @src_not_tree ; if the test did not match, branch to not tree
    jmp @src_next ; continue at next
; Continue with the not tree path.
; Branch target from @src_not_water if the test did not match.
@src_not_tree:

    jsr touches_current_road_component ; call touches current road component
    bne @src_connected ; if the test did not match, branch to connected
    jmp @src_next ; continue at next
; Continue with the connected path.
; Branch target from @src_not_tree if the test did not match.
@src_connected:

    lda tmp4 ; load temporary slot 4 into A
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_HOUSE ; house tile type
    bne @src_factory ; if the test did not match, branch to factory
    lda tmp4 ; load temporary slot 4 into A
    jsr get_tile_density_units ; call tile density units
    jsr mul_by_10 ; call by 10
    jsr add_to_component_workers ; call to component workers
    jmp @src_next ; continue at next

; Continue with the factory path.
; Branch target from @src_connected if the test did not match.
@src_factory:
    cmp #TILE_FACTORY ; factory tile type
    bne @src_police ; if the test did not match, branch to police
    lda #<house_zone_map ; load house zone map into A for secondary pointer low byte
    sta ptr2_lo ; store house zone map into secondary pointer low byte
    lda #>house_zone_map ; load house zone map into A for secondary pointer high byte
    sta ptr2_hi ; store house zone map into secondary pointer high byte
    lda tmp4 ; load temporary slot 4 into A
    jsr get_tile_density_units ; call tile density units
    tax ; move A into X for the upcoming table lookup
    lda factory_aoe_radius,x ; load factory aoe radius into A
    sta tmp3 ; store factory aoe radius into temporary slot 3
    jsr region_has_nonzero ; call region has nonzero
    beq @src_next ; if the test matched, branch to next
    lda tmp4 ; load temporary slot 4 into A
    jsr get_tile_density_units ; call tile density units
    jsr mul_by_10 ; call by 10
    jsr add_to_component_jobs ; call to component jobs
    jmp @src_next ; continue at next

; Continue with the police path.
; Branch target from @src_factory if the test did not match.
@src_police:
    cmp #TILE_POLICE ; police tile type
    bne @src_fire ; if the test did not match, branch to fire
    lda #<house_zone_map ; load house zone map into A for secondary pointer low byte
    sta ptr2_lo ; store house zone map into secondary pointer low byte
    lda #>house_zone_map ; load house zone map into A for secondary pointer high byte
    sta ptr2_hi ; store house zone map into secondary pointer high byte
    jsr load_metric_at ; call load metric at
    beq @src_next ; if the test matched, branch to next
    lda tmp4 ; load temporary slot 4 into A
    jsr get_tile_density_units ; call tile density units
    jsr mul_by_2 ; call by 2
    jsr add_to_component_jobs ; call to component jobs
    jmp @src_next ; continue at next

; Continue with the fire path.
; Branch target from @src_police if the test did not match.
@src_fire:
    cmp #TILE_FIRE ; fire-station tile type
    bne @src_next ; if the test did not match, branch to next
    lda #<house_zone_map ; load house zone map into A for secondary pointer low byte
    sta ptr2_lo ; store house zone map into secondary pointer low byte
    lda #>house_zone_map ; load house zone map into A for secondary pointer high byte
    sta ptr2_hi ; store house zone map into secondary pointer high byte
    jsr load_metric_at ; call load metric at
    beq @src_next ; if the test matched, branch to next
    lda tmp4 ; load temporary slot 4 into A
    jsr get_tile_density_units ; call tile density units
    jsr mul_by_2 ; call by 2
    jsr add_to_component_jobs ; call to component jobs

; Continue with the next path.
; Branch target from @src_factory if the test matched.
; Branch target from @src_police if the test matched.
; Branch target from @src_fire if the test did not match.
; Branch target from @src_fire if the test matched.
@src_next:
    inc tmp1 ; increment temporary slot 1
    lda tmp1 ; load temporary slot 1 into A
    cmp #MAP_WIDTH ; check for the end of the row
    beq @src_next_row ; if the test matched, branch to next row
    jmp @src_col ; continue at col
; Continue with the next row path.
; Branch target from @src_next if the test matched.
@src_next_row:
    inc tmp2 ; increment temporary slot 2
    lda tmp2 ; load temporary slot 2 into A
    cmp #MAP_HEIGHT ; check for the bottom of the map
    beq @src_totals ; if the test matched, branch to totals
    jmp @src_row ; continue at row

; Continue with the totals path.
; Branch target from @src_next_row if the test matched.
@src_totals:
    lda component_workers ; load current component workers into A
    beq @src_done ; if the test matched, branch to done
    lda component_jobs ; load current component jobs into A
    beq @src_done ; if the test matched, branch to done
    jsr add_to_jobs ; call to jobs
    lda component_workers ; load current component workers into A
    cmp component_jobs ; current component jobs
    bcc @src_use_workers ; if carry stayed clear, branch to use workers
    lda component_jobs ; load current component jobs into A
    jmp @src_add_employed ; continue at add employed
; Continue with the use workers path.
; Branch target from @src_totals if carry stayed clear.
@src_use_workers:
    lda component_workers ; load current component workers into A
; Continue with the add employed path.
@src_add_employed:
    jsr add_to_worker_supply ; call to worker supply
; Finish this local path and fall back to the caller or shared exit.
; Branch target from @src_totals if the test matched.
; Branch target from @src_totals if the test matched.
@src_done:
    rts ; Return from subroutine

; Enter the analyze road networks routine.
analyze_road_networks:
    lda #0 ; load 0 into A for jobs total
    sta jobs_total ; store 0 into jobs total
    sta employed_pop ; store A into worker supply total
    jsr clear_segment_totals ; call clear segment totals
    sta tmp2 ; store A into temporary slot 2

; Continue with the row path.
@arn_row:
    lda #0 ; load 0 into A for temporary slot 1
    sta tmp1 ; store 0 into temporary slot 1
; Continue with the col path.
@arn_col:
    lda #<building_segment_map ; load building-to-road segment map into A for secondary pointer low byte
    sta ptr2_lo ; store building-to-road segment map into secondary pointer low byte
    lda #>building_segment_map ; load building-to-road segment map into A for secondary pointer high byte
    sta ptr2_hi ; store building-to-road segment map into secondary pointer high byte
    jsr load_metric_at ; call load metric at
    sta road_mask ; store A into road mask
    bne @arn_has_segments ; if the test did not match, branch to has segments
    jmp @arn_next ; continue at next

; Continue with the has segments path.
; Branch target from @arn_col if the test did not match.
@arn_has_segments:

    lda tmp1 ; load temporary slot 1 into A
    ldx tmp2 ; load temporary slot 2 into X
    jsr get_tile ; read the tile at the requested map coordinate
    sta tmp4 ; store A into temporary slot 4
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    cmp #TILE_HOUSE ; house tile type
    bne @arn_check_factory ; if the test did not match, branch to check factory
    lda tmp4 ; load temporary slot 4 into A
    jsr get_tile_density_units ; call tile density units
    jsr mul_by_10 ; call by 10
    sta tmp3 ; store A into temporary slot 3
    lda road_mask ; load road mask into A
    jsr add_workers_for_segments ; call workers for segments
    jmp @arn_next ; continue at next

; Check factory.
; Branch target from @arn_has_segments if the test did not match.
@arn_check_factory:
    cmp #TILE_FACTORY ; factory tile type
    bne @arn_check_police ; if the test did not match, branch to check police
    lda #<house_zone_map ; load house zone map into A for secondary pointer low byte
    sta ptr2_lo ; store house zone map into secondary pointer low byte
    lda #>house_zone_map ; load house zone map into A for secondary pointer high byte
    sta ptr2_hi ; store house zone map into secondary pointer high byte
    lda tmp4 ; load temporary slot 4 into A
    jsr get_tile_density_units ; call tile density units
    tax ; move A into X for the upcoming table lookup
    lda factory_aoe_radius,x ; load factory aoe radius into A
    sta tmp3 ; store factory aoe radius into temporary slot 3
    jsr region_has_nonzero ; call region has nonzero
    beq @arn_next ; if the test matched, branch to next
    lda tmp4 ; load temporary slot 4 into A
    jsr get_tile_density_units ; call tile density units
    jsr mul_by_10 ; call by 10
    sta tmp3 ; store A into temporary slot 3
    lda road_mask ; load road mask into A
    jsr add_jobs_for_segments ; call jobs for segments
    jmp @arn_next ; continue at next

; Check police.
; Branch target from @arn_check_factory if the test did not match.
@arn_check_police:
    cmp #TILE_POLICE ; police tile type
    bne @arn_check_fire ; if the test did not match, branch to check fire
    lda #<house_zone_map ; load house zone map into A for secondary pointer low byte
    sta ptr2_lo ; store house zone map into secondary pointer low byte
    lda #>house_zone_map ; load house zone map into A for secondary pointer high byte
    sta ptr2_hi ; store house zone map into secondary pointer high byte
    jsr load_metric_at ; call load metric at
    beq @arn_next ; if the test matched, branch to next
    lda tmp4 ; load temporary slot 4 into A
    jsr get_tile_density_units ; call tile density units
    jsr mul_by_2 ; call by 2
    sta tmp3 ; store A into temporary slot 3
    lda road_mask ; load road mask into A
    jsr add_jobs_for_segments ; call jobs for segments
    jmp @arn_next ; continue at next

; Check fire.
; Branch target from @arn_check_police if the test did not match.
@arn_check_fire:
    cmp #TILE_FIRE ; fire-station tile type
    bne @arn_next ; if the test did not match, branch to next
    lda #<house_zone_map ; load house zone map into A for secondary pointer low byte
    sta ptr2_lo ; store house zone map into secondary pointer low byte
    lda #>house_zone_map ; load house zone map into A for secondary pointer high byte
    sta ptr2_hi ; store house zone map into secondary pointer high byte
    jsr load_metric_at ; call load metric at
    beq @arn_next ; if the test matched, branch to next
    lda tmp4 ; load temporary slot 4 into A
    jsr get_tile_density_units ; call tile density units
    jsr mul_by_2 ; call by 2
    sta tmp3 ; store A into temporary slot 3
    lda road_mask ; load road mask into A
    jsr add_jobs_for_segments ; call jobs for segments

; Continue with the next path.
; Branch target from @arn_check_factory if the test matched.
; Branch target from @arn_check_police if the test matched.
; Branch target from @arn_check_fire if the test did not match.
; Branch target from @arn_check_fire if the test matched.
@arn_next:
    inc tmp1 ; increment temporary slot 1
    lda tmp1 ; load temporary slot 1 into A
    cmp #MAP_WIDTH ; check for the end of the row
    beq @arn_next_row ; if the test matched, branch to next row
    jmp @arn_col ; continue at col
; Continue with the next row path.
; Branch target from @arn_next if the test matched.
@arn_next_row:
    inc tmp2 ; increment temporary slot 2
    lda tmp2 ; load temporary slot 2 into A
    cmp #MAP_HEIGHT ; check for the bottom of the map
    beq @arn_totals ; if the test matched, branch to totals
    jmp @arn_row ; continue at row

; Continue with the totals path.
; Branch target from @arn_next_row if the test matched.
@arn_totals:
    ldx #1 ; load 1 into X
; Continue with the seg loop path.
; Branch target from @arn_seg_next if the test did not match.
@arn_seg_loop:
    lda segment_jobs,x ; load jobs per road segment into A
    jsr add_to_jobs ; call to jobs
    lda segment_workers,x ; load workers per road segment into A
    beq @arn_seg_next ; if the test matched, branch to seg next
    cmp segment_jobs,x ; jobs per road segment
    bcc @arn_use_workers ; if carry stayed clear, branch to use workers
    lda segment_jobs,x ; load jobs per road segment into A
    jmp @arn_add_emp ; continue at add emp
; Continue with the use workers path.
; Branch target from @arn_seg_loop if carry stayed clear.
@arn_use_workers:
    lda segment_workers,x ; load workers per road segment into A
; Continue with the add emp path.
@arn_add_emp:
    jsr add_to_worker_supply ; call to worker supply
; Continue with the seg next path.
; Branch target from @arn_seg_loop if the test matched.
@arn_seg_next:
    inx ; advance X to the next index
    cpx #16 ; 16
    bne @arn_seg_loop ; if the test did not match, branch to seg loop
; Finish this local path and fall back to the caller or shared exit.
@arn_done:
    rts ; Return from subroutine

; Enter the workers for segments routine.
add_workers_for_segments:
    sta tmp4 ; store A into temporary slot 4
    and #$0F ; mask A with $0F
    beq @awfs_high ; if the test matched, branch to awfs high
    tax ; move A into X for the upcoming table lookup
    lda tmp3 ; load temporary slot 3 into A
    clc ; clear carry before the next add
    adc segment_workers,x ; add workers per road segment into A
    bcc @awfs_store_low ; if carry stayed clear, branch to awfs store low
    lda #$FF ; load $FF into A for workers per road segment
; Continue with the awfs store low path.
; Branch target from add_workers_for_segments if carry stayed clear.
@awfs_store_low:
    sta segment_workers,x ; store $FF into workers per road segment
; Continue with the awfs high path.
; Branch target from add_workers_for_segments if the test matched.
@awfs_high:
    lda tmp4 ; load temporary slot 4 into A
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    beq @awfs_done ; if the test matched, branch to awfs done
    tax ; move A into X for the upcoming table lookup
    lda tmp3 ; load temporary slot 3 into A
    clc ; clear carry before the next add
    adc segment_workers,x ; add workers per road segment into A
    bcc @awfs_store_high ; if carry stayed clear, branch to awfs store high
    lda #$FF ; load $FF into A for workers per road segment
; Continue with the awfs store high path.
; Branch target from @awfs_high if carry stayed clear.
@awfs_store_high:
    sta segment_workers,x ; store $FF into workers per road segment
; Continue with the awfs completion path.
; Branch target from @awfs_high if the test matched.
@awfs_done:
    rts ; Return from subroutine

; Enter the jobs for segments routine.
add_jobs_for_segments:
    sta tmp4 ; store A into temporary slot 4
    and #$0F ; mask A with $0F
    beq @ajfs_high ; if the test matched, branch to ajfs high
    tax ; move A into X for the upcoming table lookup
    lda tmp3 ; load temporary slot 3 into A
    clc ; clear carry before the next add
    adc segment_jobs,x ; add jobs per road segment into A
    bcc @ajfs_store_low ; if carry stayed clear, branch to ajfs store low
    lda #$FF ; load $FF into A for jobs per road segment
; Continue with the ajfs store low path.
; Branch target from add_jobs_for_segments if carry stayed clear.
@ajfs_store_low:
    sta segment_jobs,x ; store $FF into jobs per road segment
; Continue with the ajfs high path.
; Branch target from add_jobs_for_segments if the test matched.
@ajfs_high:
    lda tmp4 ; load temporary slot 4 into A
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    beq @ajfs_done ; if the test matched, branch to ajfs done
    tax ; move A into X for the upcoming table lookup
    lda tmp3 ; load temporary slot 3 into A
    clc ; clear carry before the next add
    adc segment_jobs,x ; add jobs per road segment into A
    bcc @ajfs_store_high ; if carry stayed clear, branch to ajfs store high
    lda #$FF ; load $FF into A for jobs per road segment
; Continue with the ajfs store high path.
; Branch target from @ajfs_high if carry stayed clear.
@ajfs_store_high:
    sta segment_jobs,x ; store $FF into jobs per road segment
; Continue with the ajfs completion path.
; Branch target from @ajfs_high if the test matched.
@ajfs_done:
    rts ; Return from subroutine

; ============================================================
; run_simulation
; Called from the main loop when sim_counter reaches zero.
; Updates money, jobs, population, power, happiness, crime, year.
; ============================================================
run_simulation:

    ; ===========================================================
    ; POWER BALANCE
    ; ===========================================================
    ; power_avail = plants * 50
    lda cnt_power ; load power into A
    jsr mul_by_50 ; call by 50
    sta power_avail ; store A into available power total

    ; power_needed = houses*5 + factories*20 + police*2 + fire*2
    lda cnt_houses ; load houses into A
    jsr mul_by_5 ; call by 5
    sta tmp1 ; store A into temporary slot 1
    lda cnt_factories ; load factories into A
    jsr mul_by_20 ; call by 20
    clc ; clear carry before the next add
    adc tmp1 ; add temporary slot 1 into A
    bcc @pwr_police ; if carry stayed clear, branch to police
    lda #$FF ; load $FF into A for temporary slot 1
; Continue with the police path.
; Branch target from run_simulation if carry stayed clear.
@pwr_police:
    sta tmp1 ; store $FF into temporary slot 1

    lda cnt_police ; load police into A
    jsr mul_by_2 ; call by 2
    clc ; clear carry before the next add
    adc tmp1 ; add temporary slot 1 into A
    bcc @pwr_fire ; if carry stayed clear, branch to fire
    lda #$FF ; load $FF into A for temporary slot 1
; Continue with the fire path.
; Branch target from @pwr_police if carry stayed clear.
@pwr_fire:
    sta tmp1 ; store $FF into temporary slot 1

    lda cnt_fire ; load fire into A
    jsr mul_by_2 ; call by 2
    clc ; clear carry before the next add
    adc tmp1 ; add temporary slot 1 into A
    bcc @pwr_store ; if carry stayed clear, branch to store
    lda #$FF ; load $FF into A for power demand total
; Continue with the store path.
; Branch target from @pwr_fire if carry stayed clear.
@pwr_store:
    sta power_needed ; store $FF into power demand total

    lda #0 ; load 0 into A for temporary slot 2
    sta tmp2                ; tmp2 = blackout flag
    lda power_avail ; load available power total into A
    cmp power_needed ; power demand total
    bcs @jobs ; if carry was set, branch to jobs
    lda #1 ; load 1 into A for temporary slot 2
    sta tmp2 ; store 1 into temporary slot 2

    ; ===========================================================
    ; JOBS / EMPLOYMENT
    ; ===========================================================
; Branch target from @pwr_store if carry was set.
@jobs:
    jsr build_service_maps ; call build service maps
    jsr analyze_city_tiles ; call analyze city tiles
    jsr analyze_road_networks ; call analyze road networks

    lda employed_pop ; load worker supply total into A
    cmp jobs_total ; jobs total
    bcc @jobs_overlap_ready ; if carry stayed clear, branch to jobs overlap ready
    lda jobs_total ; load jobs total into A
; Continue with the jobs overlap ready path.
; Branch target from @jobs if carry stayed clear.
@jobs_overlap_ready:
    sta employed_pop ; store jobs total into worker supply total

    lda population ; load population counter into A
    cmp employed_pop ; worker supply total
    bcc @all_employed ; if carry stayed clear, branch to employed
    beq @all_employed ; if the test matched, branch to employed
    lda population ; load population counter into A
    sec ; set carry before the subtract/compare sequence
    sbc employed_pop ; subtract worker supply total from A
    sta tmp1                ; tmp1 = unemployed residents
    bne @crime ; if the test did not match, branch to crime
; Continue with the employed path.
; Branch target from @jobs_overlap_ready if carry stayed clear.
; Branch target from @jobs_overlap_ready if the test matched.
@all_employed:
    lda population ; load population counter into A
    sta employed_pop ; store population counter into worker supply total
    lda #0 ; load 0 into A for temporary slot 1
    sta tmp1 ; store 0 into temporary slot 1

    ; ===========================================================
    ; CRIME = base + unemployment + blackout pressure
    ;         - local police - local fire - local parks
    ; ===========================================================
; Branch target from @jobs_overlap_ready if the test did not match.
@crime:
    lda police_coverage ; load police coverage into A
    lsr ; shift A right by one bit
    sta tmp3 ; store A into temporary slot 3
    lda #CRIME_BASE ; load CRIME BASE into A for crime
    sta crime ; store CRIME BASE into crime

    lda tmp1 ; load temporary slot 1 into A
    jsr mul_by_2 ; call by 2
    clc ; clear carry before the next add
    adc crime ; add crime into A
    bcs @crime_cap ; if carry was set, branch to crime cap
    sta crime ; store A into crime
    bcc @crime_blackout ; if carry stayed clear, branch to crime blackout
; Continue with the crime cap path.
; Branch target from @crime if carry was set.
@crime_cap:
    lda #100 ; load 100 into A for crime
    sta crime ; store 100 into crime

; Continue with the crime blackout path.
; Branch target from @crime if carry stayed clear.
@crime_blackout:
    lda tmp2 ; load temporary slot 2 into A
    beq @crime_police ; if the test matched, branch to crime police
    lda crime ; load crime into A
    clc ; clear carry before the next add
    adc #10 ; add 10 into A
    cmp #101 ; 101
    bcc @crime_store_blackout ; if carry stayed clear, branch to crime store blackout
    lda #100 ; load 100 into A for crime
; Continue with the crime store blackout path.
; Branch target from @crime_blackout if carry stayed clear.
@crime_store_blackout:
    sta crime ; store 100 into crime

; Continue with the crime police path.
; Branch target from @crime_blackout if the test matched.
@crime_police:
    lda crime ; load crime into A
    cmp tmp3 ; temporary slot 3
    bcs @crime_sub_police ; if carry was set, branch to crime sub police
    lda #0 ; load 0 into A for crime
    sta crime ; store 0 into crime
    beq @crime_fire ; if the test matched, branch to crime fire
; Continue with the crime sub police path.
; Branch target from @crime_police if carry was set.
@crime_sub_police:
    sec ; set carry before the subtract/compare sequence
    sbc tmp3 ; subtract temporary slot 3 from A
    sta crime ; store A into crime

; Continue with the crime fire path.
; Branch target from @crime_police if the test matched.
@crime_fire:
    lda cnt_fire ; load fire into A
    lda fire_coverage ; load fire coverage into A
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    sta tmp3 ; store A into temporary slot 3
    lda crime ; load crime into A
    cmp tmp3 ; temporary slot 3
    bcs @crime_sub_fire ; if carry was set, branch to crime sub fire
    lda #0 ; load 0 into A for crime
    sta crime ; store 0 into crime
    beq @crime_parks ; if the test matched, branch to crime parks
; Continue with the crime sub fire path.
; Branch target from @crime_fire if carry was set.
@crime_sub_fire:
    sec ; set carry before the subtract/compare sequence
    sbc tmp3 ; subtract temporary slot 3 from A
    sta crime ; store A into crime

; Continue with the crime parks path.
; Branch target from @crime_fire if the test matched.
@crime_parks:
    lda park_coverage ; load park coverage into A
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    sta tmp3 ; store A into temporary slot 3
    lda crime ; load crime into A
    cmp tmp3 ; temporary slot 3
    bcs @crime_sub_parks ; if carry was set, branch to crime sub parks
    lda #0 ; load 0 into A for crime
    sta crime ; store 0 into crime
    beq @happiness ; if the test matched, branch to happiness
; Continue with the crime sub parks path.
; Branch target from @crime_parks if carry was set.
@crime_sub_parks:
    sec ; set carry before the subtract/compare sequence
    sbc tmp3 ; subtract temporary slot 3 from A
    sta crime ; store A into crime
; Continue with the crime completion path.
@crime_done:

    ; ===========================================================
    ; HAPPINESS = base + local coverage + land value + full employment
    ;             - unemployment - blackout - crime
    ; clamped [0, 100]
    ; ===========================================================
; Branch target from @crime_parks if the test matched.
@happiness:
    lda #HAPPINESS_BASE ; load HAPPINESS BASE into A for happiness
    sta happiness ; store HAPPINESS BASE into happiness

    lda park_coverage ; load park coverage into A
    lsr ; shift A right by one bit
    clc ; clear carry before the next add
    adc happiness ; add happiness into A
    cmp #101 ; 101
    bcc @hap_store_parks ; if carry stayed clear, branch to store parks
    lda #100 ; load 100 into A for happiness
; Continue with the store parks path.
; Branch target from @happiness if carry stayed clear.
@hap_store_parks:
    sta happiness ; store 100 into happiness

    lda police_coverage ; load police coverage into A
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    clc ; clear carry before the next add
    adc happiness ; add happiness into A
    cmp #101 ; 101
    bcc @hap_store_police ; if carry stayed clear, branch to store police
    lda #100 ; load 100 into A for happiness
; Continue with the store police path.
; Branch target from @hap_store_parks if carry stayed clear.
@hap_store_police:
    sta happiness ; store 100 into happiness

    lda fire_coverage ; load fire coverage into A
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    clc ; clear carry before the next add
    adc happiness ; add happiness into A
    cmp #101 ; 101
    bcc @hap_store_fire ; if carry stayed clear, branch to store fire
    lda #100 ; load 100 into A for happiness
; Continue with the store fire path.
; Branch target from @hap_store_police if carry stayed clear.
@hap_store_fire:
    sta happiness ; store 100 into happiness

    lda land_value_hi ; load land value high byte into A
    lsr ; shift A right by one bit
    clc ; clear carry before the next add
    adc happiness ; add happiness into A
    cmp #101 ; 101
    bcc @hap_store_value ; if carry stayed clear, branch to store value
    lda #100 ; load 100 into A for happiness
; Continue with the store value path.
; Branch target from @hap_store_fire if carry stayed clear.
@hap_store_value:
    sta happiness ; store 100 into happiness

    lda tmp1 ; load temporary slot 1 into A
    beq @hap_job_bonus ; if the test matched, branch to job bonus
    jsr mul_by_2 ; call by 2
    sta tmp3 ; store A into temporary slot 3
    lda happiness ; load happiness into A
    cmp tmp3 ; temporary slot 3
    bcs @hap_sub_unemp ; if carry was set, branch to sub unemp
    lda #0 ; load 0 into A for happiness
    sta happiness ; store 0 into happiness
    beq @hap_blackout ; if the test matched, branch to blackout
; Continue with the sub unemp path.
; Branch target from @hap_store_value if carry was set.
@hap_sub_unemp:
    sec ; set carry before the subtract/compare sequence
    sbc tmp3 ; subtract temporary slot 3 from A
    sta happiness ; store A into happiness

; Continue with the job bonus path.
; Branch target from @hap_store_value if the test matched.
@hap_job_bonus:
    lda population ; load population counter into A
    beq @hap_blackout ; if the test matched, branch to blackout
    lda tmp1 ; load temporary slot 1 into A
    bne @hap_blackout ; if the test did not match, branch to blackout
    lda happiness ; load happiness into A
    clc ; clear carry before the next add
    adc #10 ; add 10 into A
    cmp #101 ; 101
    bcc @hap_store_bonus ; if carry stayed clear, branch to store bonus
    lda #100 ; load 100 into A for happiness
; Continue with the store bonus path.
; Branch target from @hap_job_bonus if carry stayed clear.
@hap_store_bonus:
    sta happiness ; store 100 into happiness

; Continue with the blackout path.
; Branch target from @hap_store_value if the test matched.
; Branch target from @hap_job_bonus if the test matched.
; Branch target from @hap_job_bonus if the test did not match.
@hap_blackout:
    lda tmp2 ; load temporary slot 2 into A
    beq @hap_crime ; if the test matched, branch to crime
    lda happiness ; load happiness into A
    cmp #15 ; 15
    bcs @hap_sub_blackout ; if carry was set, branch to sub blackout
    lda #0 ; load 0 into A for happiness
    sta happiness ; store 0 into happiness
    beq @hap_crime ; if the test matched, branch to crime
; Continue with the sub blackout path.
; Branch target from @hap_blackout if carry was set.
@hap_sub_blackout:
    sec ; set carry before the subtract/compare sequence
    sbc #15 ; subtract 15 from A
    sta happiness ; store A into happiness

; Continue with the crime path.
; Branch target from @hap_blackout if the test matched.
; Branch target from @hap_blackout if the test matched.
@hap_crime:
    lda crime ; load crime into A
    lsr ; shift A right by one bit
    sta tmp3 ; store A into temporary slot 3
    lda happiness ; load happiness into A
    cmp tmp3 ; temporary slot 3
    bcs @hap_sub_crime ; if carry was set, branch to sub crime
    lda #0 ; load 0 into A for happiness
    sta happiness ; store 0 into happiness
    beq @economy ; if the test matched, branch to economy
; Continue with the sub crime path.
; Branch target from @hap_crime if carry was set.
@hap_sub_crime:
    sec ; set carry before the subtract/compare sequence
    sbc tmp3 ; subtract temporary slot 3 from A
    sta happiness ; store A into happiness

    ; ===========================================================
    ; ECONOMY
    ; revenue = resident taxes + payroll taxes + housing tax
    ;         + industrial taxes
    ; costs   = upkeep + unemployment + blackout penalty
    ; ===========================================================
; Branch target from @hap_crime if the test matched.
@economy:
    lda #0 ; load 0 into A for revenue low byte
    sta rev_lo ; store 0 into revenue low byte
    sta rev_hi ; store A into revenue high byte
    sta cost_lo ; store A into cost low byte
    sta cost_hi ; store A into cost high byte

    lda population ; load population counter into A
    jsr mul_by_2 ; call by 2
    jsr add_to_revenue ; call to revenue

    lda employed_pop ; load worker supply total into A
    jsr mul_by_2 ; call by 2
    jsr add_to_revenue ; call to revenue

    lda cnt_houses ; load houses into A
    jsr add_to_revenue ; call to revenue

    lda land_value_hi ; load land value high byte into A
    jsr add_to_revenue ; call to revenue

    lda cnt_factories ; load factories into A
    jsr mul_by_20 ; call by 20
    jsr add_to_revenue ; call to revenue

    lda cnt_roads ; load roads into A
    jsr add_to_cost ; call to cost

    lda cnt_houses ; load houses into A
    jsr add_to_cost ; call to cost

    lda cnt_factories ; load factories into A
    jsr mul_by_5 ; call by 5
    jsr add_to_cost ; call to cost

    lda cnt_parks ; load parks into A
    jsr mul_by_5 ; call by 5
    jsr add_to_cost ; call to cost

    lda cnt_power ; load power into A
    jsr mul_by_20 ; call by 20
    jsr add_to_cost ; call to cost

    lda cnt_police ; load police into A
    jsr mul_by_10 ; call by 10
    jsr add_to_cost ; call to cost

    lda cnt_fire ; load fire into A
    jsr mul_by_10 ; call by 10
    jsr add_to_cost ; call to cost

    lda tmp1 ; load temporary slot 1 into A
    jsr mul_by_2 ; call by 2
    jsr add_to_cost ; call to cost

    lda tmp2 ; load temporary slot 2 into A
    beq @apply_net ; if the test matched, branch to apply net
    lda #BLACKOUT_PENALTY ; load BLACKOUT PENALTY into A
    jsr add_to_cost ; call to cost

    ; net = revenue - cost
; Branch target from @economy if the test matched.
@apply_net:
    lda rev_lo ; load revenue low byte into A
    sec ; set carry before the subtract/compare sequence
    sbc cost_lo ; subtract cost low byte from A
    sta rev_lo ; store A into revenue low byte
    lda rev_hi ; load revenue high byte into A
    sbc cost_hi ; subtract cost high byte from A
    sta rev_hi ; store A into revenue high byte

    ; money (16-bit signed) += net
    lda money_lo ; load cash low byte into A
    clc ; clear carry before the next add
    adc rev_lo ; add revenue low byte into A
    sta money_lo ; store A into cash low byte
    lda money_hi ; load cash high byte into A
    adc rev_hi ; add revenue high byte into A
    sta money_hi ; store A into cash high byte

    ; Clamp money ≥ 0
    bit money_hi ; Test bits and set flags: money_hi
    bpl @money_floor_ok ; if the result is non-negative, branch to money floor ok
    lda #0 ; load 0 into A for cash low byte
    sta money_lo ; store 0 into cash low byte
    sta money_hi ; store A into cash high byte
    ; Bankrupt message
    lda #<str_msg_bankrupt ; load bankrupt string into A for primary pointer low byte
    sta ptr_lo ; store bankrupt string into primary pointer low byte
    lda #>str_msg_bankrupt ; load bankrupt string into A for primary pointer high byte
    sta ptr_hi ; store bankrupt string into primary pointer high byte
    ldx #0 ; load 0 into X
    ldy #UI_ROW_MSG ; load message row into Y
    lda #COLOR_LTRED ; load light red into A
    jsr print_str_col ; draw the prepared string at the requested position
    lda #180 ; load 180 into A for message timer
    sta msg_timer ; store 180 into message timer
; Continue with the money floor ok path.
; Branch target from @apply_net if the result is non-negative.
@money_floor_ok:

    ; Clamp money ≤ $7FFF (32767) to keep money_hi bit 7 clear (positive).
    ; bpl branches when bit 7 of money_hi = 0 (money < $8000) → no clamp needed.
    ; Falls through when bit 7 = 1 (money ≥ $8000) → clamp to $7FFF.
    lda money_hi ; load cash high byte into A
    bpl @money_ceil_ok ; if the result is non-negative, branch to money ceil ok
    lda #$7F ; load $7F into A for cash high byte
    sta money_hi ; store $7F into cash high byte
    lda #$FF ; load $FF into A for cash low byte
    sta money_lo ; store $FF into cash low byte
; Continue with the money ceil ok path.
; Branch target from @money_floor_ok if the result is non-negative.
@money_ceil_ok:

    ; ===========================================================
    ; POPULATION
    ; desired population is bounded by housing and jobs.
    ; growth needs happiness; shrink happens when jobs/housing
    ; cannot support the current population or the city turns sour.
    ; ===========================================================
    lda cnt_houses ; load houses into A
    jsr mul_by_10 ; call by 10
    sta tmp3                ; housing capacity

    lda jobs_total ; load jobs total into A
    clc ; clear carry before the next add
    adc #POP_JOB_BUFFER ; add POP JOB BUFFER into A
    bcc @pop_jobs_ok ; if carry stayed clear, branch to jobs ok
    lda #$FF ; load $FF into A
; Continue with the jobs ok path.
; Branch target from @money_ceil_ok if carry stayed clear.
@pop_jobs_ok:
    cmp tmp3 ; temporary slot 3
    bcc @pop_target_ready ; if carry stayed clear, branch to target ready
    lda tmp3 ; load temporary slot 3 into A
; Continue with the target ready path.
; Branch target from @pop_jobs_ok if carry stayed clear.
@pop_target_ready:
    sta tmp4                ; desired population target

    lda population ; load population counter into A
    cmp tmp4 ; temporary slot 4
    beq @pop_balance ; if the test matched, branch to balance
    bcs @pop_shrink ; if carry was set, branch to shrink

    ; population < target → grow if the economy is attractive
    lda happiness ; load happiness into A
    cmp #55 ; 55
    bcc @pop_done           ; not happy enough
    inc population ; increment population counter
    bne @pop_done ; if the test did not match, branch to done

; Continue with the shrink path.
; Branch target from @pop_target_ready if carry was set.
@pop_shrink:
    lda happiness ; load happiness into A
    cmp #30 ; 30
    bcc @pop_do_shrink ; if carry stayed clear, branch to do shrink
    lda population ; load population counter into A
    cmp tmp4 ; temporary slot 4
    beq @pop_done ; if the test matched, branch to done
; Continue with the do shrink path.
; Branch target from @pop_shrink if carry stayed clear.
@pop_do_shrink:
    lda population ; load population counter into A
    beq @pop_done ; if the test matched, branch to done
    dec population ; decrement population counter
    bne @pop_done ; if the test did not match, branch to done

; Continue with the balance path.
; Branch target from @pop_target_ready if the test matched.
@pop_balance:
    lda happiness ; load happiness into A
    cmp #30 ; 30
    bcs @pop_done ; if carry was set, branch to done
    lda population ; load population counter into A
    beq @pop_done ; if the test matched, branch to done
    dec population ; decrement population counter
; Finish this local path and fall back to the caller or shared exit.
; Branch target from @pop_target_ready when not happy enough.
; Branch target from @pop_target_ready if the test did not match.
; Branch target from @pop_shrink if the test matched.
; Branch target from @pop_do_shrink if the test matched.
; Branch target from @pop_do_shrink if the test did not match.
; Branch target from @pop_balance if carry was set.
; Branch target from @pop_balance if the test matched.
@pop_done:

    ; ===========================================================
    ; ADVANCE YEAR (every YEAR_TICKS simulation ticks)
    ; ===========================================================
    inc tick_count ; increment tick count
    lda tick_count ; load tick count into A
    cmp #YEAR_TICKS ; YEAR TICKS
    bne @no_year ; if the test did not match, branch to year
    lda #0 ; load 0 into A for tick count
    sta tick_count ; store 0 into tick count
    inc year_lo ; increment year low byte
    bne @no_year ; if the test did not match, branch to year
    inc year_hi ; increment year high byte
; Continue with the year path.
; Branch target from @pop_done if the test did not match.
; Branch target from @pop_done if the test did not match.
@no_year:

    ; Reset counter and flag UI for redraw
    lda #SIM_INTERVAL ; load simulation interval into A for simulation countdown
    sta sim_counter ; store simulation interval into simulation countdown
    lda #1 ; prepare to mark the UI as needing a redraw
    sta dirty_ui ; mark the UI as needing a redraw

    rts ; Return from subroutine
