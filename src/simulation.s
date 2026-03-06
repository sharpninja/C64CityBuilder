; ============================================================
; C64 City Builder - Economic / Population Simulation
; Included by main.s.  Runs once per SIM_INTERVAL frames.
; ============================================================

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

; ============================================================
; run_simulation
; Called from the main loop when sim_counter reaches zero.
; Updates money, population, power, happiness, crime, year.
; ============================================================
run_simulation:

    ; ===========================================================
    ; POWER BALANCE
    ; ===========================================================
    ; power_avail = cnt_power * 50
    lda cnt_power
    jsr mul_by_50
    sta power_avail

    ; power_needed = houses*5 + factories*20
    lda cnt_houses
    jsr mul_by_5
    sta tmp1
    lda cnt_factories
    jsr mul_by_20
    clc
    adc tmp1
    bcc @pwr_ok
    lda #$FF
@pwr_ok:
    sta power_needed

    ; ===========================================================
    ; HAPPINESS  =  base + parks*10 − power_deficit_penalty − crime/2
    ; clamped [0, 100]
    ; ===========================================================
    lda #HAPPINESS_BASE
    sta happiness

    ; + parks * 10
    lda cnt_parks
    jsr mul_by_10
    clc
    adc happiness
    bcs @hap_max_parks
    cmp #100
    bcc @hap_store_parks
@hap_max_parks:
    lda #100
@hap_store_parks:
    sta happiness

    ; power deficit penalty
    lda power_avail
    cmp power_needed
    bcs @hap_no_pwr_pen      ; avail >= needed → no penalty
    lda happiness
    cmp #10
    bcc @hap_pwr_zero
    sec
    sbc #10
    sta happiness
    bne @hap_no_pwr_pen
@hap_pwr_zero:
    lda #0
    sta happiness
@hap_no_pwr_pen:

    ; − crime / 2
    lda crime
    lsr
    sta tmp1
    lda happiness
    cmp tmp1
    bcs @hap_crime_sub
    lda #0
    sta happiness
    beq @hap_done
@hap_crime_sub:
    sec
    sbc tmp1
    sta happiness
@hap_done:

    ; ===========================================================
    ; CRIME  =  CRIME_BASE − police * CRIME_PER_POLICE
    ; clamped [0, 100]
    ; ===========================================================
    lda cnt_police
    jsr mul_by_10
    sta tmp1
    lda #CRIME_BASE
    cmp tmp1
    bcs @crime_sub
    lda #0
    sta crime
    beq @crime_done
@crime_sub:
    sec
    sbc tmp1
    sta crime
@crime_done:

    ; ===========================================================
    ; INCOME / EXPENSES  → update money (16-bit)
    ; income  = factories * 50
    ; expense = roads*1 + houses*2 + factories*10 + parks*5
    ;         + power*50 + police*20 + fire*20
    ; ===========================================================

    ; --- Income (8-bit, factories≤255 → income≤12750 → need 16-bit)
    ; We accumulate income as 16-bit in (tmp1 lo, tmp2 hi)
    lda cnt_factories
    jsr mul_by_50           ; A = factories*50 (capped 255)
    sta tmp1
    lda #0
    sta tmp2                ; treat as 16-bit 0:A

    ; --- Expenses (8-bit, accumulated in tmp3)
    lda cnt_roads           ; × 1
    sta tmp3

    lda cnt_houses
    jsr mul_by_2
    clc
    adc tmp3
    bcc @e1
    lda #$FF
@e1:
    sta tmp3

    lda cnt_factories
    jsr mul_by_10
    clc
    adc tmp3
    bcc @e2
    lda #$FF
@e2:
    sta tmp3

    lda cnt_parks
    jsr mul_by_5
    clc
    adc tmp3
    bcc @e3
    lda #$FF
@e3:
    sta tmp3

    lda cnt_power
    jsr mul_by_50
    clc
    adc tmp3
    bcc @e4
    lda #$FF
@e4:
    sta tmp3

    lda cnt_police
    jsr mul_by_20
    clc
    adc tmp3
    bcc @e5
    lda #$FF
@e5:
    sta tmp3

    lda cnt_fire
    jsr mul_by_20
    clc
    adc tmp3
    bcc @e6
    lda #$FF
@e6:
    sta tmp3                ; total expenses in tmp3

    ; net = income - expenses  (signed 8-bit → extend to 16-bit)
    lda tmp1
    sec
    sbc tmp3
    sta tmp1                ; net (signed 8-bit)
    ; sign-extend to 16-bit in tmp1/tmp2
    lda tmp1
    and #$80
    beq @net_pos
    lda #$FF
    sta tmp2
    bne @apply_net
@net_pos:
    lda #0
    sta tmp2
@apply_net:
    ; money (16-bit signed) += net
    lda money_lo
    clc
    adc tmp1
    sta money_lo
    lda money_hi
    adc tmp2
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

    ; Clamp money ≤ $7FFF (32767) so high byte stays positive
    lda money_hi
    bpl @money_ceil_ok
    lda #$7F
    sta money_hi
    lda #$FF
    sta money_lo
@money_ceil_ok:

    ; ===========================================================
    ; POPULATION
    ; target = houses * 10  (ideal population)
    ; grow if pop < target AND happiness >= 50
    ; shrink if pop > 0 AND happiness < 30
    ; ===========================================================
    lda cnt_houses
    jsr mul_by_10
    sta tmp1                ; target population

    lda population
    cmp tmp1
    beq @pop_done
    bcs @pop_maybe_shrink

    ; population < target → try to grow
    lda happiness
    cmp #50
    bcc @pop_done           ; not happy enough
    inc population
    bne @pop_done

@pop_maybe_shrink:
    ; population > target  OR  target = 0 → maybe shrink
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
