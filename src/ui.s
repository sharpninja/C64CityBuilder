; ============================================================
; C64 City Builder - UI / Status-Bar Rendering
; Included by main.s.
; ============================================================

    .segment "CODE"

; ============================================================
; print_str_col
; Print null-terminated screen-code string.
; Inputs: X = column, Y = row, A = colour, ptr_lo/hi = string
; Trashes: A, X, Y (X used as col offset inside)
; ============================================================
print_str_col:
    stx tmp1            ; col
    sty tmp2            ; row
    and #$07
    sta tmp3            ; colour

    ; Base screen address = SCREEN_BASE + row*40
    ldx tmp2
    lda mul40_lo,x
    clc
    adc #<SCREEN_BASE
    sta ptr2_lo
    lda mul40_hi,x
    adc #>SCREEN_BASE
    sta ptr2_hi

    ; Add column offset
    lda tmp1
    clc
    adc ptr2_lo
    sta ptr2_lo
    bcc @psc_nc1
    inc ptr2_hi
@psc_nc1:

    ; Print characters until null terminator
    ldy #0
@psc_loop:
    lda (ptr_lo),y
    beq @psc_done
    sta (ptr2_lo),y         ; write screen char
    lda ptr_lo
    sta np_div_lo
    lda ptr_hi
    sta np_div_hi
    lda ptr2_lo
    sta ptr_lo
    lda ptr2_hi
    clc
    adc #($D8 - $44)
    sta ptr_hi
    lda tmp3
    sta (ptr_lo),y          ; write colour
    lda np_div_lo
    sta ptr_lo
    lda np_div_hi
    sta ptr_hi
    iny
    bne @psc_loop           ; up to 255 chars
@psc_done:
    rts

; ============================================================
; print_dec16
; Print 5-digit decimal representation of np_val_lo:np_val_hi.
; Inputs: X = start column, Y = start row
; Colour is always COLOR_WHITE.
; Trashes: A, X, Y
; ============================================================
print_dec16:
    stx tmp1            ; col
    sty tmp2            ; row

    ; Copy input value to working register
    lda np_val_lo
    sta np_div_lo
    lda np_val_hi
    sta np_div_hi

    ; Compute screen destination: SCREEN_BASE + row*40 + col
    ldx tmp2
    lda mul40_lo,x
    clc
    adc #<SCREEN_BASE
    sta ptr2_lo
    lda mul40_hi,x
    adc #>SCREEN_BASE
    sta ptr2_hi
    lda tmp1
    clc
    adc ptr2_lo
    sta ptr2_lo
    bcc @pd_nc1
    inc ptr2_hi
@pd_nc1:

    ; Extract 5 decimal digits using table-driven subtraction
    ldx #0              ; digit index (0=ten-thousands … 4=ones)
    ldy #0              ; screen offset

@pd_loop:
    ; Load divisor for digit X
    lda pow10_lo,x
    sta tmp1
    lda pow10_hi,x
    sta tmp2
    lda #0
    sta tmp3            ; digit value

    ; Subtract divisor while np_div >= divisor
@pd_sub:
    ; 16-bit unsigned compare: np_div >= (tmp2:tmp1)?
    lda np_div_hi
    cmp tmp2
    bcc @pd_emit        ; hi < → done
    bne @pd_do_sub      ; hi > → subtract
    lda np_div_lo       ; hi equal → compare lo
    cmp tmp1
    bcc @pd_emit        ; lo < → done
@pd_do_sub:
    lda np_div_lo
    sec
    sbc tmp1
    sta np_div_lo
    lda np_div_hi
    sbc tmp2
    sta np_div_hi
    inc tmp3
    bne @pd_sub         ; always (digit 0-9)

@pd_emit:
    lda tmp3
    ora #$30            ; digit 0-9 → screen code 48-57 ('0'-'9'); no carry dependency
    sta (ptr2_lo),y

    lda ptr2_hi
    sta tmp4
    lda ptr2_hi
    clc
    adc #($D8 - $44)
    sta ptr2_hi
    lda #COLOR_WHITE
    sta (ptr2_lo),y
    lda tmp4
    sta ptr2_hi

    iny
    inx
    cpx #5
    bne @pd_loop

    rts

; ============================================================
; fill_row_color
; Fill one screen row in the colour RAM with a single colour.
; Inputs: X = row (0-24), A = colour
; Trashes A, Y.
; ============================================================
fill_row_color:
    sta tmp3
    lda mul40_lo,x
    clc
    adc #<COLOR_BASE
    sta ptr2_lo
    lda mul40_hi,x
    adc #>COLOR_BASE
    sta ptr2_hi
    lda tmp3
    ldy #0
@frc_loop:
    sta (ptr2_lo),y
    iny
    cpy #SCREEN_COLS
    bne @frc_loop
    rts

; ============================================================
; fill_row_char
; Fill one entire screen row with a character.
; Inputs: X = row, A = screen character
; Trashes A, Y.
; ============================================================
fill_row_char:
    sta tmp3
    lda mul40_lo,x
    clc
    adc #<SCREEN_BASE
    sta ptr2_lo
    lda mul40_hi,x
    adc #>SCREEN_BASE
    sta ptr2_hi
    lda tmp3
    ldy #0
@frch_loop:
    sta (ptr2_lo),y
    iny
    cpy #SCREEN_COLS
    bne @frch_loop
    rts

; ============================================================
; draw_status_bar
; Render rows 20-24 (the entire UI area).
; ============================================================
draw_status_bar:
    ; ---- Row 20: power/jobs/happiness/crime ---------------
    ; First fill row with spaces
    ldx #UI_ROW_SEP
    lda #32
    jsr fill_row_char
    ldx #UI_ROW_SEP
    lda #COLOR_DKGRAY
    jsr fill_row_color

    ; PWR:
    lda #<str_pwr
    sta ptr_lo
    lda #>str_pwr
    sta ptr_hi
    ldx #0
    ldy #UI_ROW_SEP
    lda #COLOR_YELLOW
    jsr print_str_col

    lda power_avail
    sta np_val_lo
    lda #0
    sta np_val_hi
    ldx #2
    ldy #UI_ROW_SEP
    jsr print_dec16

    ; JOB:
    lda #<str_job
    sta ptr_lo
    lda #>str_job
    sta ptr_hi
    ldx #10
    ldy #UI_ROW_SEP
    lda #COLOR_LTGREEN
    jsr print_str_col

    lda jobs_total
    sta np_val_lo
    lda #0
    sta np_val_hi
    ldx #12
    ldy #UI_ROW_SEP
    jsr print_dec16

    ; HAP:
    lda #<str_hap
    sta ptr_lo
    lda #>str_hap
    sta ptr_hi
    ldx #20
    ldy #UI_ROW_SEP
    lda #COLOR_CYAN
    jsr print_str_col

    lda happiness
    sta np_val_lo
    lda #0
    sta np_val_hi
    ldx #22
    ldy #UI_ROW_SEP
    jsr print_dec16

    ; CRM:
    lda #<str_crm
    sta ptr_lo
    lda #>str_crm
    sta ptr_hi
    ldx #30
    ldy #UI_ROW_SEP
    lda #COLOR_LTRED
    jsr print_str_col

    lda crime
    sta np_val_lo
    lda #0
    sta np_val_hi
    ldx #32
    ldy #UI_ROW_SEP
    jsr print_dec16

    ; ---- Row 21: Year / Cash / Population -----------------
    ldx #UI_ROW_STATS
    lda #32
    jsr fill_row_char
    ldx #UI_ROW_STATS
    lda #COLOR_WHITE
    jsr fill_row_color

    ; YR:
    lda #<str_yr
    sta ptr_lo
    lda #>str_yr
    sta ptr_hi
    ldx #0
    ldy #UI_ROW_STATS
    lda #COLOR_YELLOW
    jsr print_str_col

    lda year_lo
    sta np_val_lo
    lda year_hi
    sta np_val_hi
    ldx #3
    ldy #UI_ROW_STATS
    jsr print_dec16

    ; $:
    lda #<str_cash
    sta ptr_lo
    lda #>str_cash
    sta ptr_hi
    ldx #9
    ldy #UI_ROW_STATS
    lda #COLOR_YELLOW
    jsr print_str_col

    lda money_lo
    sta np_val_lo
    lda money_hi
    sta np_val_hi
    ldx #12
    ldy #UI_ROW_STATS
    jsr print_dec16

    ; POP:
    lda #<str_pop
    sta ptr_lo
    lda #>str_pop
    sta ptr_hi
    ldx #19
    ldy #UI_ROW_STATS
    lda #COLOR_YELLOW
    jsr print_str_col

    lda population
    sta np_val_lo
    lda #0
    sta np_val_hi
    ldx #24
    ldy #UI_ROW_STATS
    jsr print_dec16

    jsr draw_cursor_tile_info

    ; ---- Row 22: Building menu ----------------------------
    lda #<str_menu
    sta ptr_lo
    lda #>str_menu
    sta ptr_hi
    ldx #0
    ldy #UI_ROW_MENU
    lda #COLOR_LTBLUE
    jsr print_str_col

    ; Highlight selected building entry
    jsr highlight_sel_building

    ; ---- Row 23: Mode label + message -------------------
    jsr draw_mode_row

    ; ---- Row 24: Help line ------------------------------
    lda #<str_help
    sta ptr_lo
    lda #>str_help
    sta ptr_hi
    ldx #0
    ldy #UI_ROW_HELP
    lda #COLOR_MDGRAY
    jsr print_str_col

    lda #0
    sta dirty_ui
    rts

; ============================================================
; draw_mode_row
; Print mode label and manage timed message on row UI_ROW_MSG.
; ============================================================
draw_mode_row:
    ; Mode label
    lda game_mode
    bne @dm_demo
    lda #<str_mode_build
    sta ptr_lo
    lda #>str_mode_build
    sta ptr_hi
    bne @dm_print
@dm_demo:
    lda #<str_mode_demo
    sta ptr_lo
    lda #>str_mode_demo
    sta ptr_hi
@dm_print:
    ldx #0
    ldy #UI_ROW_MSG
    lda #COLOR_CYAN
    jsr print_str_col

    ; Manage message timer
    lda msg_timer
    beq @dm_needs
    dec msg_timer
    bne @dm_done
    ; Timer expired: clear message area
@dm_needs:
    jsr draw_city_needs
@dm_done:
    rts

; ============================================================
; draw_city_needs
; Show passive city-need indicators in the message area when
; there is no active timed message.
; ============================================================
draw_city_needs:
    lda #<str_msg_empty
    sta ptr_lo
    lda #>str_msg_empty
    sta ptr_hi
    ldx #11
    ldy #UI_ROW_MSG
    lda #COLOR_WHITE
    jsr print_str_col

    lda #<str_needs_hdr
    sta ptr_lo
    lda #>str_needs_hdr
    sta ptr_hi
    ldx #11
    ldy #UI_ROW_MSG
    lda #COLOR_MDGRAY
    jsr print_str_col

    lda #0
    sta tmp1

    lda power_avail
    cmp power_needed
    bcs @dcn_jobs
    lda #<str_need_pwr
    sta ptr_lo
    lda #>str_need_pwr
    sta ptr_hi
    ldx #18
    ldy #UI_ROW_MSG
    lda #COLOR_ORANGE
    jsr print_str_col
    lda #1
    sta tmp1

@dcn_jobs:
    lda employed_pop
    cmp population
    beq @dcn_housing
    lda #<str_need_job
    sta ptr_lo
    lda #>str_need_job
    sta ptr_hi
    ldx #22
    ldy #UI_ROW_MSG
    lda #COLOR_YELLOW
    jsr print_str_col
    lda #1
    sta tmp1

@dcn_housing:
    lda population
    beq @dcn_parks
    lda cnt_houses
    jsr mul_by_10
    sta tmp2
    lda population
    cmp tmp2
    bcc @dcn_parks
    lda #<str_need_hse
    sta ptr_lo
    lda #>str_need_hse
    sta ptr_hi
    ldx #26
    ldy #UI_ROW_MSG
    lda #COLOR_CYAN
    jsr print_str_col
    lda #1
    sta tmp1

@dcn_parks:
    lda happiness
    cmp #45
    bcs @dcn_safety
    lda #<str_need_prk
    sta ptr_lo
    lda #>str_need_prk
    sta ptr_hi
    ldx #30
    ldy #UI_ROW_MSG
    lda #COLOR_LTGREEN
    jsr print_str_col
    lda #1
    sta tmp1

@dcn_safety:
    lda crime
    cmp #35
    bcc @dcn_ok
    lda #<str_need_saf
    sta ptr_lo
    lda #>str_need_saf
    sta ptr_hi
    ldx #34
    ldy #UI_ROW_MSG
    lda #COLOR_LTRED
    jsr print_str_col
    lda #1
    sta tmp1

@dcn_ok:
    lda tmp1
    bne @dcn_done
    lda #<str_need_ok
    sta ptr_lo
    lda #>str_need_ok
    sta ptr_hi
    ldx #18
    ldy #UI_ROW_MSG
    lda #COLOR_LTGREEN
    jsr print_str_col

@dcn_done:
    rts

; ============================================================
; draw_cursor_tile_info
; Show the tile type and density level under the cursor on the
; stats row. Buildable tiles show L1-L4; terrain shows L-.
; ============================================================
draw_cursor_tile_info:
    lda cursor_x
    ldx cursor_y
    jsr get_tile
    sta tmp4
    and #TILE_TYPE_MASK
    asl
    tax
    lda hud_tile_names,x
    sta ptr_lo
    lda hud_tile_names+1,x
    sta ptr_hi
    ldx #29
    ldy #UI_ROW_STATS
    lda #COLOR_CYAN
    jsr print_str_col

    lda tmp4
    and #TILE_TYPE_MASK
    cmp #TILE_ROAD
    bcc @dcti_no_level
    cmp #TILE_FIRE + 1
    bcs @dcti_no_level
    lda tmp4
    and #TILE_DENSITY_MASK
    lsr
    lsr
    lsr
    lsr
    asl
    tax
    lda hud_level_names,x
    sta ptr_lo
    lda hud_level_names+1,x
    sta ptr_hi
    bne @dcti_print_level

@dcti_no_level:
    lda #<str_lvl_na
    sta ptr_lo
    lda #>str_lvl_na
    sta ptr_hi

@dcti_print_level:
    ldx #34
    ldy #UI_ROW_STATS
    lda #COLOR_LTBLUE
    jsr print_str_col

    lda tmp4
    jsr get_cursor_tile_impact
    jsr draw_cursor_tile_impact
    rts

; ============================================================
; get_cursor_tile_impact
; A = raw tile byte. Returns the direct per-tick cash impact
; of the tile as a signed 8-bit value.
; ============================================================
get_cursor_tile_impact:
    sta tmp2
    and #TILE_TYPE_MASK
    tax

    cpx #TILE_ROAD
    bne @gcti_house
    lda tmp2
    jsr get_tile_density_units
    eor #$FF
    clc
    adc #1
    rts

@gcti_house:
    cpx #TILE_HOUSE
    bne @gcti_factory
    lda tmp2
    jsr get_tile_density_units
    rts

@gcti_factory:
    cpx #TILE_FACTORY
    bne @gcti_park
    lda tmp2
    jsr get_tile_density_units
    sta tmp4
    jsr mul_by_10
    sta tmp1
    lda tmp4
    jsr mul_by_5
    clc
    adc tmp1
    rts

@gcti_park:
    cpx #TILE_PARK
    bne @gcti_power
    lda tmp2
    jsr get_tile_density_units
    jsr mul_by_5
    eor #$FF
    clc
    adc #1
    rts

@gcti_power:
    cpx #TILE_POWER
    bne @gcti_police
    lda tmp2
    jsr get_tile_density_units
    jsr mul_by_20
    eor #$FF
    clc
    adc #1
    rts

@gcti_police:
    cpx #TILE_POLICE
    bne @gcti_fire
    lda tmp2
    jsr get_tile_density_units
    jsr mul_by_10
    eor #$FF
    clc
    adc #1
    rts

@gcti_fire:
    cpx #TILE_FIRE
    bne @gcti_zero
    lda tmp2
    jsr get_tile_density_units
    jsr mul_by_10
    eor #$FF
    clc
    adc #1
    rts

@gcti_zero:
    lda #0
    rts

; ============================================================
; draw_cursor_tile_impact
; A = signed 8-bit per-tick impact. Draws a compact 3-char
; signed value at the end of the stats row.
; ============================================================
draw_cursor_tile_impact:
    sta tmp4
    lda #43
    sta tmp1
    lda #COLOR_LTGREEN
    sta tmp2
    lda tmp4
    beq @dcti_zero
    bpl @dcti_abs_ready
    lda #45
    sta tmp1
    lda #COLOR_LTRED
    sta tmp2
    lda tmp4
    eor #$FF
    clc
    adc #1
    bne @dcti_abs_ready

@dcti_zero:
    lda #COLOR_WHITE
    sta tmp2
    lda #0

@dcti_abs_ready:
    ldx #0
@dcti_tens:
    cmp #10
    bcc @dcti_digits
    sec
    sbc #10
    inx
    bne @dcti_tens

@dcti_digits:
    sta tmp3
    stx np_div_lo

    ldy #UI_ROW_STATS
    lda mul40_lo,y
    clc
    adc #<SCREEN_BASE
    sta ptr2_lo
    lda mul40_hi,y
    adc #>SCREEN_BASE
    sta ptr2_hi
    lda ptr2_lo
    clc
    adc #37
    sta ptr2_lo
    bcc @dcti_scr_ok
    inc ptr2_hi
@dcti_scr_ok:

    ldy #UI_ROW_STATS
    lda mul40_lo,y
    clc
    adc #<COLOR_BASE
    sta ptr_lo
    lda mul40_hi,y
    adc #>COLOR_BASE
    sta ptr_hi
    lda ptr_lo
    clc
    adc #37
    sta ptr_lo
    bcc @dcti_col_ok
    inc ptr_hi
@dcti_col_ok:

    ldy #0
    lda tmp1
    sta (ptr2_lo),y
    lda tmp2
    sta (ptr_lo),y
    iny

    lda np_div_lo
    beq @dcti_blank_tens
    clc
    adc #$30
    bne @dcti_store_tens
@dcti_blank_tens:
    lda #32
@dcti_store_tens:
    sta (ptr2_lo),y
    lda tmp2
    sta (ptr_lo),y
    iny

    lda tmp3
    clc
    adc #$30
    sta (ptr2_lo),y
    lda tmp2
    sta (ptr_lo),y
    rts

; ============================================================
; highlight_sel_building
; Recolour the active building entry on row UI_ROW_MENU to yellow.
; ============================================================
; Column start positions for each entry (1-indexed)
; Menu string layout:
;   "1:RD 2:HSE 3:FAC 4:PRK 5:PWR 6:POL 7:FIR"
;    0    5     11    17    23    29    35
; ============================================================
    .segment "RODATA"
menu_entry_col:
    .byte 0, 5, 11, 17, 23, 29, 35     ; start cols for entries 1-7
menu_entry_len:
    .byte 4, 5,  5,  5,  5,  5,  5     ; char count for each entry

    .segment "CODE"

highlight_sel_building:
    lda sel_building
    beq @hsel_done
    cmp #8
    bcs @hsel_done

    ; Look up start column for this entry (sel_building is 1-7)
    tax
    dex                         ; 0-based index
    lda menu_entry_col,x
    sta tmp1                    ; start col
    lda menu_entry_len,x
    sta tmp2                    ; entry width

    ; Compute colour address: COLOR_BASE + UI_ROW_MENU*40 + col
    ldy #UI_ROW_MENU
    lda mul40_lo,y
    clc
    adc #<COLOR_BASE
    sta ptr2_lo
    lda mul40_hi,y
    adc #>COLOR_BASE
    sta ptr2_hi

    lda tmp1
    clc
    adc ptr2_lo
    sta ptr2_lo
    bcc @hsel_nc
    inc ptr2_hi
@hsel_nc:

    ldy #0
    lda tmp2
    sta tmp3                    ; iteration count
    lda #COLOR_YELLOW
@hsel_loop:
    sta (ptr2_lo),y
    iny
    dec tmp3
    bne @hsel_loop
@hsel_done:
    rts
