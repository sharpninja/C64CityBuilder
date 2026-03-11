; ============================================================
; C64 City Builder - Economic / Population Simulation
; Included by main.s.  Runs once per SIM_INTERVAL frames.
; ============================================================

    .segment "BSS"
park_effect_map:    .res MAP_SIZE
police_effect_map:  .res MAP_SIZE
fire_effect_map:    .res MAP_SIZE
house_zone_map:     .res MAP_SIZE
factory_zone_map:   .res MAP_SIZE
tile_value_map:     .res MAP_SIZE
road_component_map: .res MAP_SIZE
component_jobs:     .res 1
component_workers:  .res 1
component_changed:  .res 1

    .segment "CODE"

; ============================================================
; Multiply helpers: A × constant → A  (caps at 255)
; These preserve X and Y.
; ============================================================

; --- A * 5 -------------------------------------------------
mul_by_5:
    sta tmp4
    beq @m5_done
    lda #0
    ldx tmp4
@m5_loop:
    clc
    adc #5
    bcs @m5_cap
    dex
    bne @m5_loop
@m5_done:
    rts
@m5_cap:
    lda #$FF
    rts

; --- A * 10 ------------------------------------------------
mul_by_10:
    sta tmp4
    beq @m10_done
    lda #0
    ldx tmp4
@m10_loop:
    clc
    adc #10
    bcs @m10_cap
    dex
    bne @m10_loop
@m10_done:
    rts
@m10_cap:
    lda #$FF
    rts

; --- A * 20 ------------------------------------------------
mul_by_20:
    sta tmp4
    beq @m20_done
    lda #0
    ldx tmp4
@m20_loop:
    clc
    adc #20
    bcs @m20_cap
    dex
    bne @m20_loop
@m20_done:
    rts
@m20_cap:
    lda #$FF
    rts

; --- A * 50 ------------------------------------------------
mul_by_50:
    sta tmp4
    beq @m50_done
    lda #0
    ldx tmp4
@m50_loop:
    clc
    adc #50
    bcs @m50_cap
    dex
    bne @m50_loop
@m50_done:
    rts
@m50_cap:
    lda #$FF
    rts

; --- A * 2  (simple left shift) ----------------------------
mul_by_2:
    asl
    bcs @m2_cap
    rts
@m2_cap:
    lda #$FF
    rts

; --- A * 3 -------------------------------------------------
mul_by_3:
    sta tmp4
    asl
    bcs @m3_cap
    clc
    adc tmp4
    bcs @m3_cap
    rts
@m3_cap:
    lda #$FF
    rts

; ============================================================
; 8-bit accumulator helpers for the city economy
; ============================================================
add_to_jobs:
    clc
    adc jobs_total
    bcc @atj_store
    lda #$FF
@atj_store:
    sta jobs_total
    rts

add_to_revenue:
    clc
    adc rev_lo
    sta rev_lo
    bcc @atr_done
    inc rev_hi
@atr_done:
    rts

add_to_cost:
    clc
    adc cost_lo
    sta cost_lo
    bcc @atc_done
    inc cost_hi
@atc_done:
    rts

add_to_land_value:
    clc
    adc land_value_lo
    sta land_value_lo
    bcc @atl_done
    inc land_value_hi
    bne @atl_done
    lda #$FF
    sta land_value_lo
    sta land_value_hi
@atl_done:
    rts

add_to_worker_supply:
    clc
    adc employed_pop
    bcc @atw_store
    lda #$FF
@atw_store:
    sta employed_pop
    rts

add_a_to_tmp3:
    clc
    adc tmp3
    bcc @a3_store
    lda #$FF
@a3_store:
    sta tmp3
    rts

clear_map_buffer:
    lda ptr2_lo
    sta ptr_lo
    lda ptr2_hi
    sta ptr_hi
    lda #0
    ldx #3
@cmb_page:
    ldy #0
@cmb_loop:
    sta (ptr_lo),y
    iny
    bne @cmb_loop
    inc ptr_hi
    dex
    bne @cmb_page
    ldy #0
@cmb_rem:
    sta (ptr_lo),y
    iny
    cpy #(MAP_SIZE - 768)
    bne @cmb_rem
    rts

clear_sim_maps:
    lda #<park_effect_map
    sta ptr2_lo
    lda #>park_effect_map
    sta ptr2_hi
    jsr clear_map_buffer

    lda #<police_effect_map
    sta ptr2_lo
    lda #>police_effect_map
    sta ptr2_hi
    jsr clear_map_buffer

    lda #<fire_effect_map
    sta ptr2_lo
    lda #>fire_effect_map
    sta ptr2_hi
    jsr clear_map_buffer

    lda #<house_zone_map
    sta ptr2_lo
    lda #>house_zone_map
    sta ptr2_hi
    jsr clear_map_buffer

    lda #<factory_zone_map
    sta ptr2_lo
    lda #>factory_zone_map
    sta ptr2_hi
    jsr clear_map_buffer

    lda #<tile_value_map
    sta ptr2_lo
    lda #>tile_value_map
    sta ptr2_hi
    jsr clear_map_buffer

    lda #<road_component_map
    sta ptr2_lo
    lda #>road_component_map
    sta ptr2_hi
    jsr clear_map_buffer
    rts

load_metric_at:
    ldy tmp2
    lda mul40_lo,y
    clc
    adc tmp1
    sta ptr_lo
    lda mul40_hi,y
    adc #0
    sta ptr_hi
    lda ptr_lo
    clc
    adc ptr2_lo
    sta ptr_lo
    lda ptr_hi
    adc ptr2_hi
    sta ptr_hi
    ldy #0
    lda (ptr_lo),y
    rts

store_metric_at:
    pha
    ldy tmp2
    lda mul40_lo,y
    clc
    adc tmp1
    sta ptr_lo
    lda mul40_hi,y
    adc #0
    sta ptr_hi
    lda ptr_lo
    clc
    adc ptr2_lo
    sta ptr_lo
    lda ptr_hi
    adc ptr2_hi
    sta ptr_hi
    pla
    ldy #0
    sta (ptr_lo),y
    rts

stamp_radius_add:
    lda tmp2
    sec
    sbc tmp3
    bcs @sra_row_lo_ok
    lda #0
@sra_row_lo_ok:
    sta np_val_lo

    lda tmp2
    clc
    adc tmp3
    cmp #MAP_HEIGHT
    bcc @sra_row_hi_ok
    lda #(MAP_HEIGHT - 1)
@sra_row_hi_ok:
    sta np_val_hi

    lda tmp1
    sec
    sbc tmp3
    bcs @sra_col_lo_ok
    lda #0
@sra_col_lo_ok:
    sta np_div_lo

    lda tmp1
    clc
    adc tmp3
    cmp #MAP_WIDTH
    bcc @sra_col_hi_ok
    lda #(MAP_WIDTH - 1)
@sra_col_hi_ok:
    sec
    sbc np_div_lo
    clc
    adc #1
    sta np_div_hi

@sra_row_loop:
    ldy np_val_lo
    lda mul40_lo,y
    clc
    adc ptr2_lo
    sta ptr_lo
    lda mul40_hi,y
    adc ptr2_hi
    sta ptr_hi

    lda np_div_lo
    clc
    adc ptr_lo
    sta ptr_lo
    bcc @sra_ptr_ok
    inc ptr_hi
@sra_ptr_ok:
    ldy #0
@sra_col_loop:
    lda (ptr_lo),y
    clc
    adc tmp4
    bcc @sra_store
    lda #$FF
@sra_store:
    sta (ptr_lo),y
    iny
    cpy np_div_hi
    bne @sra_col_loop

    inc np_val_lo
    lda np_val_hi
    cmp np_val_lo
    bcs @sra_row_loop
    rts

region_has_nonzero:
    lda tmp2
    sec
    sbc tmp3
    bcs @rhn_row_lo_ok
    lda #0
@rhn_row_lo_ok:
    sta np_val_lo

    lda tmp2
    clc
    adc tmp3
    cmp #MAP_HEIGHT
    bcc @rhn_row_hi_ok
    lda #(MAP_HEIGHT - 1)
@rhn_row_hi_ok:
    sta np_val_hi

    lda tmp1
    sec
    sbc tmp3
    bcs @rhn_col_lo_ok
    lda #0
@rhn_col_lo_ok:
    sta np_div_lo

    lda tmp1
    clc
    adc tmp3
    cmp #MAP_WIDTH
    bcc @rhn_col_hi_ok
    lda #(MAP_WIDTH - 1)
@rhn_col_hi_ok:
    sec
    sbc np_div_lo
    clc
    adc #1
    sta np_div_hi

@rhn_row_loop:
    ldy np_val_lo
    lda mul40_lo,y
    clc
    adc ptr2_lo
    sta ptr_lo
    lda mul40_hi,y
    adc ptr2_hi
    sta ptr_hi

    lda np_div_lo
    clc
    adc ptr_lo
    sta ptr_lo
    bcc @rhn_ptr_ok
    inc ptr_hi
@rhn_ptr_ok:
    ldy #0
@rhn_col_loop:
    lda (ptr_lo),y
    bne @rhn_found
    iny
    cpy np_div_hi
    bne @rhn_col_loop

    inc np_val_lo
    lda np_val_hi
    cmp np_val_lo
    bcs @rhn_row_loop
    lda #0
    rts
@rhn_found:
    lda #1
    rts

build_service_maps:
    jsr clear_sim_maps
    lda #0
    sta tmp2
@bsm_row:
    lda #0
    sta tmp1
@bsm_col:
    lda tmp1
    ldx tmp2
    jsr get_tile
    sta tmp4
    and #TILE_TYPE_MASK
    cmp #TILE_PARK
    bne @bsm_police
    lda #<park_effect_map
    sta ptr2_lo
    lda #>park_effect_map
    sta ptr2_hi
    lda tmp4
    jsr get_tile_density_units
    jsr mul_by_3
    sta tmp4
    lda #PARK_RADIUS
    sta tmp3
    jsr stamp_radius_add
    jmp @bsm_next

@bsm_police:
    cmp #TILE_POLICE
    bne @bsm_fire
    lda #<police_effect_map
    sta ptr2_lo
    lda #>police_effect_map
    sta ptr2_hi
    lda tmp4
    jsr get_tile_density_units
    jsr mul_by_2
    sta tmp4
    lda #POLICE_RADIUS
    sta tmp3
    jsr stamp_radius_add
    jmp @bsm_next

@bsm_fire:
    cmp #TILE_FIRE
    bne @bsm_house
    lda #<fire_effect_map
    sta ptr2_lo
    lda #>fire_effect_map
    sta ptr2_hi
    lda tmp4
    jsr get_tile_density_units
    jsr mul_by_2
    sta tmp4
    lda #FIRE_RADIUS
    sta tmp3
    jsr stamp_radius_add
    jmp @bsm_next

@bsm_house:
    cmp #TILE_HOUSE
    bne @bsm_factory
    lda #<house_zone_map
    sta ptr2_lo
    lda #>house_zone_map
    sta ptr2_hi
    lda tmp4
    jsr get_tile_density_units
    tax
    lda house_aoe_radius,x
    sta tmp3
    lda #1
    sta tmp4
    jsr stamp_radius_add
    jmp @bsm_next

@bsm_factory:
    cmp #TILE_FACTORY
    bne @bsm_next
    lda #<factory_zone_map
    sta ptr2_lo
    lda #>factory_zone_map
    sta ptr2_hi
    lda tmp4
    jsr get_tile_density_units
    tax
    lda factory_aoe_radius,x
    sta tmp3
    lda #1
    sta tmp4
    jsr stamp_radius_add

@bsm_next:
    inc tmp1
    lda tmp1
    cmp #MAP_WIDTH
    beq @bsm_next_row
    jmp @bsm_col
@bsm_next_row:
    inc tmp2
    lda tmp2
    cmp #MAP_HEIGHT
    beq @bsm_done
    jmp @bsm_row
@bsm_done:
    rts

apply_neighbor_value_effect:
    and #TILE_TYPE_MASK
    cmp #TILE_ROAD
    bne @anv_house
    lda #1
    sta road_mask
    lda #VALUE_BONUS_ROAD
    jmp add_a_to_tmp3

@anv_house:
    cmp #TILE_HOUSE
    bne @anv_factory
    lda #VALUE_BONUS_HOUSE
    jmp add_a_to_tmp3

@anv_factory:
    cmp #TILE_FACTORY
    bne @anv_park
    lda tmp3
    cmp #VALUE_PENALTY_FACTORY
    bcs @anv_sub_factory
    lda #0
    sta tmp3
    rts
@anv_sub_factory:
    sec
    sbc #VALUE_PENALTY_FACTORY
    sta tmp3
    rts

@anv_park:
    cmp #TILE_PARK
    bne @anv_power
    lda #VALUE_BONUS_PARK
    jmp add_a_to_tmp3

@anv_power:
    cmp #TILE_POWER
    bne @anv_police
    lda tmp3
    cmp #VALUE_PENALTY_POWER
    bcs @anv_sub_power
    lda #0
    sta tmp3
    rts
@anv_sub_power:
    sec
    sbc #VALUE_PENALTY_POWER
    sta tmp3
    rts

@anv_police:
    cmp #TILE_POLICE
    beq @anv_service
    cmp #TILE_FIRE
    bne @anv_done
@anv_service:
    lda #VALUE_BONUS_SERVICE
    jmp add_a_to_tmp3
@anv_done:
    rts

compute_tile_value_at:
    lda tmp1
    ldx tmp2
    jsr get_tile
    sta tmp4
    and #TILE_TYPE_MASK
    tax
    lda #0
    cpx #TILE_ROAD
    bne @ctv_house
    lda #VALUE_BASE_ROAD
    bne @ctv_base_done
@ctv_house:
    cpx #TILE_HOUSE
    bne @ctv_factory
    lda #VALUE_BASE_HOUSE
    bne @ctv_base_done
@ctv_factory:
    cpx #TILE_FACTORY
    bne @ctv_park
    lda #VALUE_BASE_FACTORY
    bne @ctv_base_done
@ctv_park:
    cpx #TILE_PARK
    bne @ctv_power
    lda #VALUE_BASE_PARK
    bne @ctv_base_done
@ctv_power:
    cpx #TILE_POWER
    bne @ctv_police
    lda #VALUE_BASE_POWER
    bne @ctv_base_done
@ctv_police:
    cpx #TILE_POLICE
    bne @ctv_fire
    lda #VALUE_BASE_POLICE
    bne @ctv_base_done
@ctv_fire:
    cpx #TILE_FIRE
    bne @ctv_base_done
    lda #VALUE_BASE_FIRE
@ctv_base_done:
    sta tmp3

    lda tmp4
    and #TILE_TYPE_MASK
    beq @ctv_effects
    cmp #(TILE_FIRE + 1)
    bcs @ctv_effects
    lda tmp4
    jsr get_tile_density_units
    asl
    asl
    jsr add_a_to_tmp3

@ctv_effects:
    lda #<park_effect_map
    sta ptr2_lo
    lda #>park_effect_map
    sta ptr2_hi
    jsr load_metric_at
    jsr add_a_to_tmp3

    lda tmp4
    and #TILE_TYPE_MASK
    cmp #TILE_HOUSE
    beq @ctv_public_safety
    cmp #TILE_FACTORY
    beq @ctv_public_safety
    jmp @ctv_neighbors

@ctv_public_safety:
    lda #<police_effect_map
    sta ptr2_lo
    lda #>police_effect_map
    sta ptr2_hi
    jsr load_metric_at
    jsr add_a_to_tmp3

    lda #<fire_effect_map
    sta ptr2_lo
    lda #>fire_effect_map
    sta ptr2_hi
    jsr load_metric_at
    jsr add_a_to_tmp3

@ctv_neighbors:
    lda #0
    sta road_mask

    lda tmp2
    beq @ctv_south
    lda tmp1
    ldx tmp2
    dex
    jsr get_tile
    jsr apply_neighbor_value_effect

@ctv_south:
    lda tmp2
    cmp #(MAP_HEIGHT - 1)
    bcs @ctv_east
    lda tmp1
    ldx tmp2
    inx
    jsr get_tile
    jsr apply_neighbor_value_effect

@ctv_east:
    lda tmp1
    cmp #(MAP_WIDTH - 1)
    bcs @ctv_west
    lda tmp1
    clc
    adc #1
    ldx tmp2
    jsr get_tile
    jsr apply_neighbor_value_effect

@ctv_west:
    lda tmp1
    beq @ctv_need_road
    lda tmp1
    sec
    sbc #1
    ldx tmp2
    jsr get_tile
    jsr apply_neighbor_value_effect

@ctv_need_road:
    lda tmp4
    and #TILE_TYPE_MASK
    cmp #TILE_HOUSE
    beq @ctv_check_road
    cmp #TILE_FACTORY
    bne @ctv_clamp
@ctv_check_road:
    lda road_mask
    bne @ctv_clamp
    lda tmp3
    cmp #VALUE_PENALTY_NO_ROAD
    bcs @ctv_sub_no_road
    lda #0
    sta tmp3
    beq @ctv_clamp
@ctv_sub_no_road:
    sec
    sbc #VALUE_PENALTY_NO_ROAD
    sta tmp3

@ctv_clamp:
    lda tmp3
    cmp #(VALUE_CAP + 1)
    bcc @ctv_done
    lda #VALUE_CAP
@ctv_done:
    rts

analyze_city_tiles:
    lda #0
    sta park_coverage
    sta police_coverage
    sta fire_coverage
    sta land_value_lo
    sta land_value_hi
    sta jobs_total
    sta employed_pop
    sta tmp2

@act_row:
    lda #0
    sta tmp1
@act_col:
    jsr compute_tile_value_at
    sta tmp3

    lda #<tile_value_map
    sta ptr2_lo
    lda #>tile_value_map
    sta ptr2_hi
    lda tmp3
    jsr store_metric_at

    lda tmp4
    and #TILE_TYPE_MASK
    cmp #TILE_HOUSE
    bne @act_check_factory
    jmp @act_house
@act_check_factory:
    cmp #TILE_FACTORY
    bne @act_check_police
    jmp @act_factory
@act_check_police:
    cmp #TILE_POLICE
    bne @act_check_fire
    jmp @act_police_jobs
@act_check_fire:
    cmp #TILE_FIRE
    bne @act_other
    jmp @act_fire_jobs
@act_other:
    jmp @act_next

@act_house:
    lda tmp4
    jsr get_tile_density_units
    sta road_mask
    ldx road_mask
@act_value_loop:
    lda tmp3
    jsr add_to_land_value
    dex
    bne @act_value_loop

    lda #<park_effect_map
    sta ptr2_lo
    lda #>park_effect_map
    sta ptr2_hi
    jsr load_metric_at
    beq @act_police
    lda park_coverage
    clc
    adc road_mask
    bcc @act_store_park
    lda #$FF
@act_store_park:
    sta park_coverage

@act_police:
    lda #<police_effect_map
    sta ptr2_lo
    lda #>police_effect_map
    sta ptr2_hi
    jsr load_metric_at
    beq @act_fire
    lda police_coverage
    clc
    adc road_mask
    bcc @act_store_police
    lda #$FF
@act_store_police:
    sta police_coverage

@act_fire:
    lda #<fire_effect_map
    sta ptr2_lo
    lda #>fire_effect_map
    sta ptr2_hi
    jsr load_metric_at
    beq @act_worker
    lda fire_coverage
    clc
    adc road_mask
    bcc @act_store_fire
    lda #$FF
@act_store_fire:
    sta fire_coverage
@act_worker:
    lda road_mask
    jsr mul_by_10
    jsr add_to_worker_supply
    jmp @act_next

@act_factory:
    lda tmp4
    jsr get_tile_density_units
    sta road_mask
    sta tmp3
    lda #<house_zone_map
    sta ptr2_lo
    lda #>house_zone_map
    sta ptr2_hi
    jsr region_has_nonzero
    beq @act_next
    lda road_mask
    jsr mul_by_10
    jsr add_to_jobs
    jmp @act_next

@act_police_jobs:
    lda #<house_zone_map
    sta ptr2_lo
    lda #>house_zone_map
    sta ptr2_hi
    jsr load_metric_at
    beq @act_next
    lda tmp4
    jsr get_tile_density_units
    jsr mul_by_2
    jsr add_to_jobs
    jmp @act_next

@act_fire_jobs:
    lda #<house_zone_map
    sta ptr2_lo
    lda #>house_zone_map
    sta ptr2_hi
    jsr load_metric_at
    beq @act_next
    lda tmp4
    jsr get_tile_density_units
    jsr mul_by_2
    jsr add_to_jobs

@act_next:
    inc tmp1
    lda tmp1
    cmp #MAP_WIDTH
    beq @act_next_row
    jmp @act_col
@act_next_row:
    inc tmp2
    lda tmp2
    cmp #MAP_HEIGHT
    beq @act_done
    jmp @act_row
@act_done:
    rts

add_to_component_jobs:
    clc
    adc component_jobs
    bcc @acj_store
    lda #$FF
@acj_store:
    sta component_jobs
    rts

add_to_component_workers:
    clc
    adc component_workers
    bcc @acw_store
    lda #$FF
@acw_store:
    sta component_workers
    rts

touches_current_road_component:
    lda tmp1
    sta road_mask
    lda tmp2
    sta np_val_lo

    lda #<road_component_map
    sta ptr2_lo
    lda #>road_component_map
    sta ptr2_hi

    lda np_val_lo
    beq @trc_south
    lda road_mask
    sta tmp1
    lda np_val_lo
    sec
    sbc #1
    sta tmp2
    jsr load_metric_at
    cmp #1
    beq @trc_yes

@trc_south:
    lda np_val_lo
    cmp #(MAP_HEIGHT - 1)
    bcs @trc_east
    lda road_mask
    sta tmp1
    lda np_val_lo
    clc
    adc #1
    sta tmp2
    jsr load_metric_at
    cmp #1
    beq @trc_yes

@trc_east:
    lda road_mask
    cmp #(MAP_WIDTH - 1)
    bcs @trc_west
    clc
    adc #1
    sta tmp1
    lda np_val_lo
    sta tmp2
    jsr load_metric_at
    cmp #1
    beq @trc_yes

@trc_west:
    lda road_mask
    beq @trc_no
    sec
    sbc #1
    sta tmp1
    lda np_val_lo
    sta tmp2
    jsr load_metric_at
    cmp #1
    beq @trc_yes

@trc_no:
    lda road_mask
    sta tmp1
    lda np_val_lo
    sta tmp2
    lda #0
    rts

@trc_yes:
    lda road_mask
    sta tmp1
    lda np_val_lo
    sta tmp2
    lda #1
    rts

expand_current_road_component:
@erc_pass:
    lda #0
    sta component_changed
    sta tmp2

@erc_row:
    lda #0
    sta tmp1
@erc_col:
    lda tmp1
    ldx tmp2
    jsr get_tile
    and #TILE_TYPE_MASK
    cmp #TILE_ROAD
    bne @erc_next

    lda #<road_component_map
    sta ptr2_lo
    lda #>road_component_map
    sta ptr2_hi
    jsr load_metric_at
    bne @erc_next

    jsr touches_current_road_component
    beq @erc_next

    lda #<road_component_map
    sta ptr2_lo
    lda #>road_component_map
    sta ptr2_hi
    lda #1
    jsr store_metric_at
    lda #1
    sta component_changed

@erc_next:
    inc tmp1
    lda tmp1
    cmp #MAP_WIDTH
    beq @erc_next_row
    jmp @erc_col
@erc_next_row:
    inc tmp2
    lda tmp2
    cmp #MAP_HEIGHT
    beq @erc_pass_done
    jmp @erc_row

@erc_pass_done:
    lda component_changed
    bne @erc_pass
    rts

mark_current_road_component_processed:
    lda #0
    sta tmp2
@mrc_row:
    lda #0
    sta tmp1
@mrc_col:
    lda #<road_component_map
    sta ptr2_lo
    lda #>road_component_map
    sta ptr2_hi
    jsr load_metric_at
    cmp #1
    bne @mrc_next
    lda #<road_component_map
    sta ptr2_lo
    lda #>road_component_map
    sta ptr2_hi
    lda #2
    jsr store_metric_at
@mrc_next:
    inc tmp1
    lda tmp1
    cmp #MAP_WIDTH
    beq @mrc_next_row
    jmp @mrc_col
@mrc_next_row:
    inc tmp2
    lda tmp2
    cmp #MAP_HEIGHT
    beq @mrc_done
    jmp @mrc_row
@mrc_done:
    rts

score_current_road_component:
    lda #0
    sta component_jobs
    sta component_workers
    sta tmp2

@src_row:
    lda #0
    sta tmp1
@src_col:
    lda tmp1
    ldx tmp2
    jsr get_tile
    sta tmp4
    and #TILE_TYPE_MASK
    bne @src_not_empty
    jmp @src_next
@src_not_empty:
    cmp #TILE_WATER
    bne @src_not_water
    jmp @src_next
@src_not_water:
    cmp #TILE_TREE
    bne @src_not_tree
    jmp @src_next
@src_not_tree:

    jsr touches_current_road_component
    bne @src_connected
    jmp @src_next
@src_connected:

    lda tmp4
    and #TILE_TYPE_MASK
    cmp #TILE_HOUSE
    bne @src_factory
    lda tmp4
    jsr get_tile_density_units
    jsr mul_by_10
    jsr add_to_component_workers
    jmp @src_next

@src_factory:
    cmp #TILE_FACTORY
    bne @src_police
    lda #<house_zone_map
    sta ptr2_lo
    lda #>house_zone_map
    sta ptr2_hi
    lda tmp4
    jsr get_tile_density_units
    tax
    lda factory_aoe_radius,x
    sta tmp3
    jsr region_has_nonzero
    beq @src_next
    lda tmp4
    jsr get_tile_density_units
    jsr mul_by_10
    jsr add_to_component_jobs
    jmp @src_next

@src_police:
    cmp #TILE_POLICE
    bne @src_fire
    lda #<house_zone_map
    sta ptr2_lo
    lda #>house_zone_map
    sta ptr2_hi
    jsr load_metric_at
    beq @src_next
    lda tmp4
    jsr get_tile_density_units
    jsr mul_by_2
    jsr add_to_component_jobs
    jmp @src_next

@src_fire:
    cmp #TILE_FIRE
    bne @src_next
    lda #<house_zone_map
    sta ptr2_lo
    lda #>house_zone_map
    sta ptr2_hi
    jsr load_metric_at
    beq @src_next
    lda tmp4
    jsr get_tile_density_units
    jsr mul_by_2
    jsr add_to_component_jobs

@src_next:
    inc tmp1
    lda tmp1
    cmp #MAP_WIDTH
    beq @src_next_row
    jmp @src_col
@src_next_row:
    inc tmp2
    lda tmp2
    cmp #MAP_HEIGHT
    beq @src_totals
    jmp @src_row

@src_totals:
    lda component_workers
    beq @src_done
    lda component_jobs
    beq @src_done
    jsr add_to_jobs
    lda component_workers
    cmp component_jobs
    bcc @src_use_workers
    lda component_jobs
    jmp @src_add_employed
@src_use_workers:
    lda component_workers
@src_add_employed:
    jsr add_to_worker_supply
@src_done:
    rts

analyze_road_networks:
    lda #0
    sta jobs_total
    sta employed_pop
    sta tmp2

@arn_row:
    lda #0
    sta tmp1
@arn_col:
    lda tmp1
    ldx tmp2
    jsr get_tile
    and #TILE_TYPE_MASK
    cmp #TILE_ROAD
    bne @arn_next

    lda #<road_component_map
    sta ptr2_lo
    lda #>road_component_map
    sta ptr2_hi
    jsr load_metric_at
    bne @arn_next

    lda #<road_component_map
    sta ptr2_lo
    lda #>road_component_map
    sta ptr2_hi
    lda #1
    jsr store_metric_at
    jsr expand_current_road_component
    jsr score_current_road_component
    jsr mark_current_road_component_processed

@arn_next:
    inc tmp1
    lda tmp1
    cmp #MAP_WIDTH
    beq @arn_next_row
    jmp @arn_col
@arn_next_row:
    inc tmp2
    lda tmp2
    cmp #MAP_HEIGHT
    beq @arn_done
    jmp @arn_row
@arn_done:
    rts

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
    lda cnt_power
    jsr mul_by_50
    sta power_avail

    ; power_needed = houses*5 + factories*20 + police*2 + fire*2
    lda cnt_houses
    jsr mul_by_5
    sta tmp1
    lda cnt_factories
    jsr mul_by_20
    clc
    adc tmp1
    bcc @pwr_police
    lda #$FF
@pwr_police:
    sta tmp1

    lda cnt_police
    jsr mul_by_2
    clc
    adc tmp1
    bcc @pwr_fire
    lda #$FF
@pwr_fire:
    sta tmp1

    lda cnt_fire
    jsr mul_by_2
    clc
    adc tmp1
    bcc @pwr_store
    lda #$FF
@pwr_store:
    sta power_needed

    lda #0
    sta tmp2                ; tmp2 = blackout flag
    lda power_avail
    cmp power_needed
    bcs @jobs
    lda #1
    sta tmp2

    ; ===========================================================
    ; JOBS / EMPLOYMENT
    ; ===========================================================
@jobs:
    jsr build_service_maps
    jsr analyze_city_tiles
    jsr analyze_road_networks

    lda employed_pop
    cmp jobs_total
    bcc @jobs_overlap_ready
    lda jobs_total
@jobs_overlap_ready:
    sta employed_pop

    lda population
    cmp employed_pop
    bcc @all_employed
    beq @all_employed
    lda population
    sec
    sbc employed_pop
    sta tmp1                ; tmp1 = unemployed residents
    bne @crime
@all_employed:
    lda population
    sta employed_pop
    lda #0
    sta tmp1

    ; ===========================================================
    ; CRIME = base + unemployment + blackout pressure
    ;         - local police - local fire - local parks
    ; ===========================================================
@crime:
    lda police_coverage
    lsr
    sta tmp3
    lda #CRIME_BASE
    sta crime

    lda tmp1
    jsr mul_by_2
    clc
    adc crime
    bcs @crime_cap
    sta crime
    bcc @crime_blackout
@crime_cap:
    lda #100
    sta crime

@crime_blackout:
    lda tmp2
    beq @crime_police
    lda crime
    clc
    adc #10
    cmp #101
    bcc @crime_store_blackout
    lda #100
@crime_store_blackout:
    sta crime

@crime_police:
    lda crime
    cmp tmp3
    bcs @crime_sub_police
    lda #0
    sta crime
    beq @crime_fire
@crime_sub_police:
    sec
    sbc tmp3
    sta crime

@crime_fire:
    lda cnt_fire
    lda fire_coverage
    lsr
    lsr
    sta tmp3
    lda crime
    cmp tmp3
    bcs @crime_sub_fire
    lda #0
    sta crime
    beq @crime_parks
@crime_sub_fire:
    sec
    sbc tmp3
    sta crime

@crime_parks:
    lda park_coverage
    lsr
    lsr
    sta tmp3
    lda crime
    cmp tmp3
    bcs @crime_sub_parks
    lda #0
    sta crime
    beq @happiness
@crime_sub_parks:
    sec
    sbc tmp3
    sta crime
@crime_done:

    ; ===========================================================
    ; HAPPINESS = base + local coverage + land value + full employment
    ;             - unemployment - blackout - crime
    ; clamped [0, 100]
    ; ===========================================================
@happiness:
    lda #HAPPINESS_BASE
    sta happiness

    lda park_coverage
    lsr
    clc
    adc happiness
    cmp #101
    bcc @hap_store_parks
    lda #100
@hap_store_parks:
    sta happiness

    lda police_coverage
    lsr
    lsr
    clc
    adc happiness
    cmp #101
    bcc @hap_store_police
    lda #100
@hap_store_police:
    sta happiness

    lda fire_coverage
    lsr
    lsr
    clc
    adc happiness
    cmp #101
    bcc @hap_store_fire
    lda #100
@hap_store_fire:
    sta happiness

    lda land_value_hi
    lsr
    clc
    adc happiness
    cmp #101
    bcc @hap_store_value
    lda #100
@hap_store_value:
    sta happiness

    lda tmp1
    beq @hap_job_bonus
    jsr mul_by_2
    sta tmp3
    lda happiness
    cmp tmp3
    bcs @hap_sub_unemp
    lda #0
    sta happiness
    beq @hap_blackout
@hap_sub_unemp:
    sec
    sbc tmp3
    sta happiness

@hap_job_bonus:
    lda population
    beq @hap_blackout
    lda tmp1
    bne @hap_blackout
    lda happiness
    clc
    adc #10
    cmp #101
    bcc @hap_store_bonus
    lda #100
@hap_store_bonus:
    sta happiness

@hap_blackout:
    lda tmp2
    beq @hap_crime
    lda happiness
    cmp #15
    bcs @hap_sub_blackout
    lda #0
    sta happiness
    beq @hap_crime
@hap_sub_blackout:
    sec
    sbc #15
    sta happiness

@hap_crime:
    lda crime
    lsr
    sta tmp3
    lda happiness
    cmp tmp3
    bcs @hap_sub_crime
    lda #0
    sta happiness
    beq @economy
@hap_sub_crime:
    sec
    sbc tmp3
    sta happiness

    ; ===========================================================
    ; ECONOMY
    ; revenue = resident taxes + payroll taxes + housing tax
    ;         + industrial taxes
    ; costs   = upkeep + unemployment + blackout penalty
    ; ===========================================================
@economy:
    lda #0
    sta rev_lo
    sta rev_hi
    sta cost_lo
    sta cost_hi

    lda population
    jsr mul_by_2
    jsr add_to_revenue

    lda employed_pop
    jsr mul_by_2
    jsr add_to_revenue

    lda cnt_houses
    jsr add_to_revenue

    lda land_value_hi
    jsr add_to_revenue

    lda cnt_factories
    jsr mul_by_20
    jsr add_to_revenue

    lda cnt_roads
    jsr add_to_cost

    lda cnt_houses
    jsr add_to_cost

    lda cnt_factories
    jsr mul_by_5
    jsr add_to_cost

    lda cnt_parks
    jsr mul_by_5
    jsr add_to_cost

    lda cnt_power
    jsr mul_by_20
    jsr add_to_cost

    lda cnt_police
    jsr mul_by_10
    jsr add_to_cost

    lda cnt_fire
    jsr mul_by_10
    jsr add_to_cost

    lda tmp1
    jsr mul_by_2
    jsr add_to_cost

    lda tmp2
    beq @apply_net
    lda #BLACKOUT_PENALTY
    jsr add_to_cost

    ; net = revenue - cost
@apply_net:
    lda rev_lo
    sec
    sbc cost_lo
    sta rev_lo
    lda rev_hi
    sbc cost_hi
    sta rev_hi

    ; money (16-bit signed) += net
    lda money_lo
    clc
    adc rev_lo
    sta money_lo
    lda money_hi
    adc rev_hi
    sta money_hi

    ; Clamp money ≥ 0
    bit money_hi
    bpl @money_floor_ok
    lda #0
    sta money_lo
    sta money_hi
    ; Bankrupt message
    lda #<str_msg_bankrupt
    sta ptr_lo
    lda #>str_msg_bankrupt
    sta ptr_hi
    ldx #0
    ldy #UI_ROW_MSG
    lda #COLOR_LTRED
    jsr print_str_col
    lda #180
    sta msg_timer
@money_floor_ok:

    ; Clamp money ≤ $7FFF (32767) to keep money_hi bit 7 clear (positive).
    ; bpl branches when bit 7 of money_hi = 0 (money < $8000) → no clamp needed.
    ; Falls through when bit 7 = 1 (money ≥ $8000) → clamp to $7FFF.
    lda money_hi
    bpl @money_ceil_ok
    lda #$7F
    sta money_hi
    lda #$FF
    sta money_lo
@money_ceil_ok:

    ; ===========================================================
    ; POPULATION
    ; desired population is bounded by housing and jobs.
    ; growth needs happiness; shrink happens when jobs/housing
    ; cannot support the current population or the city turns sour.
    ; ===========================================================
    lda cnt_houses
    jsr mul_by_10
    sta tmp3                ; housing capacity

    lda jobs_total
    clc
    adc #POP_JOB_BUFFER
    bcc @pop_jobs_ok
    lda #$FF
@pop_jobs_ok:
    cmp tmp3
    bcc @pop_target_ready
    lda tmp3
@pop_target_ready:
    sta tmp4                ; desired population target

    lda population
    cmp tmp4
    beq @pop_balance
    bcs @pop_shrink

    ; population < target → grow if the economy is attractive
    lda happiness
    cmp #55
    bcc @pop_done           ; not happy enough
    inc population
    bne @pop_done

@pop_shrink:
    lda happiness
    cmp #30
    bcc @pop_do_shrink
    lda population
    cmp tmp4
    beq @pop_done
@pop_do_shrink:
    lda population
    beq @pop_done
    dec population
    bne @pop_done

@pop_balance:
    lda happiness
    cmp #30
    bcs @pop_done
    lda population
    beq @pop_done
    dec population
@pop_done:

    ; ===========================================================
    ; ADVANCE YEAR (every YEAR_TICKS simulation ticks)
    ; ===========================================================
    inc tick_count
    lda tick_count
    cmp #YEAR_TICKS
    bne @no_year
    lda #0
    sta tick_count
    inc year_lo
    bne @no_year
    inc year_hi
@no_year:

    ; Reset counter and flag UI for redraw
    lda #SIM_INTERVAL
    sta sim_counter
    lda #1
    sta dirty_ui

    rts
