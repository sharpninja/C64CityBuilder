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
    and #$07 ; mask A with $07
    sta tmp3            ; colour

    ; Base screen address = SCREEN_BASE + row*40
    ldx tmp2 ; load temporary slot 2 into X
    lda mul40_lo,x ; load precomputed row*40 lookup into A
    clc ; clear carry before the next add
    adc #<SCREEN_BASE ; add screen RAM base into A
    sta ptr2_lo ; store A into secondary pointer low byte
    lda mul40_hi,x ; load precomputed row*40 lookup into A
    adc #>SCREEN_BASE ; add screen RAM base into A
    sta ptr2_hi ; store A into secondary pointer high byte

    ; Add column offset
    lda tmp1 ; load temporary slot 1 into A
    clc ; clear carry before the next add
    adc ptr2_lo ; add secondary pointer low byte into A
    sta ptr2_lo ; store A into secondary pointer low byte
    bcc @psc_nc1 ; if carry stayed clear, branch to nc1
    inc ptr2_hi ; advance the secondary pointer to the next page
; Continue with the nc1 path.
; Branch target from print_str_col if carry stayed clear.
@psc_nc1:

    ; Print characters until null terminator
    ldy #0 ; load 0 into Y
; Repeat the current loop.
; Branch target from @psc_loop when up to 255 chars.
@psc_loop:
    lda (ptr_lo),y ; load primary pointer low byte into A
    beq @psc_done ; if the test matched, branch to done
    sta (ptr2_lo),y         ; write screen char
    lda ptr_lo ; load primary pointer low byte into A
    sta np_div_lo ; store primary pointer low byte into number-print work low byte
    lda ptr_hi ; load primary pointer high byte into A
    sta np_div_hi ; store primary pointer high byte into number-print work high byte
    lda ptr2_lo ; load secondary pointer low byte into A
    sta ptr_lo ; store secondary pointer low byte into primary pointer low byte
    lda ptr2_hi ; load secondary pointer high byte into A
    clc ; clear carry before the next add
    adc #($D8 - $44) ; add ($D8 - $44 into A
    sta ptr_hi ; store A into primary pointer high byte
    lda tmp3 ; load temporary slot 3 into A
    sta (ptr_lo),y          ; write colour
    lda np_div_lo ; load number-print work low byte into A
    sta ptr_lo ; store number-print work low byte into primary pointer low byte
    lda np_div_hi ; load number-print work high byte into A
    sta ptr_hi ; store number-print work high byte into primary pointer high byte
    iny ; advance Y to the next offset
    bne @psc_loop           ; up to 255 chars
; Finish this local path and fall back to the caller or shared exit.
; Branch target from @psc_loop if the test matched.
@psc_done:
    rts ; Return from subroutine

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
    lda np_val_lo ; load number-print value low byte into A
    sta np_div_lo ; store number-print value low byte into number-print work low byte
    lda np_val_hi ; load number-print value high byte into A
    sta np_div_hi ; store number-print value high byte into number-print work high byte

    ; Compute screen destination: SCREEN_BASE + row*40 + col
    ldx tmp2 ; load temporary slot 2 into X
    lda mul40_lo,x ; load precomputed row*40 lookup into A
    clc ; clear carry before the next add
    adc #<SCREEN_BASE ; add screen RAM base into A
    sta ptr2_lo ; store A into secondary pointer low byte
    lda mul40_hi,x ; load precomputed row*40 lookup into A
    adc #>SCREEN_BASE ; add screen RAM base into A
    sta ptr2_hi ; store A into secondary pointer high byte
    lda tmp1 ; load temporary slot 1 into A
    clc ; clear carry before the next add
    adc ptr2_lo ; add secondary pointer low byte into A
    sta ptr2_lo ; store A into secondary pointer low byte
    bcc @pd_nc1 ; if carry stayed clear, branch to nc1
    inc ptr2_hi ; advance the secondary pointer to the next page
; Continue with the nc1 path.
; Branch target from print_dec16 if carry stayed clear.
@pd_nc1:

    ; Extract 5 decimal digits using table-driven subtraction
    ldx #0              ; digit index (0=ten-thousands … 4=ones)
    ldy #0              ; screen offset

; Repeat the current loop.
; Branch target from @pd_emit if the test did not match.
@pd_loop:
    ; Load divisor for digit X
    lda pow10_lo,x ; load power-of-ten lookup table into A
    sta tmp1 ; store power-of-ten lookup table into temporary slot 1
    lda pow10_hi,x ; load power-of-ten lookup table into A
    sta tmp2 ; store power-of-ten lookup table into temporary slot 2
    lda #0 ; load 0 into A for temporary slot 3
    sta tmp3            ; digit value

    ; Subtract divisor while np_div >= divisor
; Branch target from @pd_do_sub when always (digit 0-9).
@pd_sub:
    ; 16-bit unsigned compare: np_div >= (tmp2:tmp1)?
    lda np_div_hi ; load number-print work high byte into A
    cmp tmp2 ; temporary slot 2
    bcc @pd_emit        ; hi < → done
    bne @pd_do_sub      ; hi > → subtract
    lda np_div_lo       ; hi equal → compare lo
    cmp tmp1 ; temporary slot 1
    bcc @pd_emit        ; lo < → done
; Continue with the do sub path.
; Branch target from @pd_sub when hi > → subtract.
@pd_do_sub:
    lda np_div_lo ; load number-print work low byte into A
    sec ; set carry before the subtract/compare sequence
    sbc tmp1 ; subtract temporary slot 1 from A
    sta np_div_lo ; store A into number-print work low byte
    lda np_div_hi ; load number-print work high byte into A
    sbc tmp2 ; subtract temporary slot 2 from A
    sta np_div_hi ; store A into number-print work high byte
    inc tmp3 ; bump the current digit count
    bne @pd_sub         ; always (digit 0-9)

; Continue with the emit path.
; Branch target from @pd_sub when hi < → done.
; Branch target from @pd_sub when lo < → done.
@pd_emit:
    lda tmp3 ; load temporary slot 3 into A
    ora #$30            ; digit 0-9 → screen code 48-57 ('0'-'9'); no carry dependency
    sta (ptr2_lo),y ; store A into secondary pointer low byte

    lda ptr2_hi ; load secondary pointer high byte into A
    sta tmp4 ; store secondary pointer high byte into temporary slot 4
    lda ptr2_hi ; load secondary pointer high byte into A
    clc ; clear carry before the next add
    adc #($D8 - $44) ; add ($D8 - $44 into A
    sta ptr2_hi ; store A into secondary pointer high byte
    lda #COLOR_WHITE ; load white into A for secondary pointer low byte
    sta (ptr2_lo),y ; store white into secondary pointer low byte
    lda tmp4 ; load temporary slot 4 into A
    sta ptr2_hi ; store temporary slot 4 into secondary pointer high byte

    iny ; advance Y to the next offset
    inx ; advance X to the next index
    cpx #5 ; 5
    bne @pd_loop ; if the test did not match, branch to loop

    rts ; Return from subroutine

; ============================================================
; fill_row_color
; Fill one screen row in the colour RAM with a single colour.
; Inputs: X = row (0-24), A = colour
; Trashes A, Y.
; ============================================================
fill_row_color:
    sta tmp3 ; store A into temporary slot 3
    lda mul40_lo,x ; load precomputed row*40 lookup into A
    clc ; clear carry before the next add
    adc #<COLOR_BASE ; add color RAM base into A
    sta ptr2_lo ; store A into secondary pointer low byte
    lda mul40_hi,x ; load precomputed row*40 lookup into A
    adc #>COLOR_BASE ; add color RAM base into A
    sta ptr2_hi ; store A into secondary pointer high byte
    lda tmp3 ; load temporary slot 3 into A
    ldy #0 ; load 0 into Y for secondary pointer low byte
; Repeat the current loop.
; Branch target from @frc_loop if the test did not match.
@frc_loop:
    sta (ptr2_lo),y ; store 0 into secondary pointer low byte
    iny ; advance Y to the next offset
    cpy #SCREEN_COLS ; check whether the whole row has been filled
    bne @frc_loop ; if the test did not match, branch to loop
    rts ; Return from subroutine

; ============================================================
; fill_row_char
; Fill one entire screen row with a character.
; Inputs: X = row, A = screen character
; Trashes A, Y.
; ============================================================
fill_row_char:
    sta tmp3 ; store A into temporary slot 3
    lda mul40_lo,x ; load precomputed row*40 lookup into A
    clc ; clear carry before the next add
    adc #<SCREEN_BASE ; add screen RAM base into A
    sta ptr2_lo ; store A into secondary pointer low byte
    lda mul40_hi,x ; load precomputed row*40 lookup into A
    adc #>SCREEN_BASE ; add screen RAM base into A
    sta ptr2_hi ; store A into secondary pointer high byte
    lda tmp3 ; load temporary slot 3 into A
    ldy #0 ; load 0 into Y for secondary pointer low byte
; Continue with the frch loop path.
; Branch target from @frch_loop if the test did not match.
@frch_loop:
    sta (ptr2_lo),y ; store 0 into secondary pointer low byte
    iny ; advance Y to the next offset
    cpy #SCREEN_COLS ; check whether the whole row has been filled
    bne @frch_loop ; if the test did not match, branch to frch loop
    rts ; Return from subroutine

; ============================================================
; draw_status_bar
; Render rows 20-24 (the entire UI area).
; ============================================================
draw_status_bar:
    ; ---- Top row: Building menu -----------------------------
    ldx #UI_ROW_MENU ; load menu row into X
    lda #32 ; load 32 into A
    jsr fill_row_char ; fill the row with one character
    ldx #UI_ROW_MENU ; load menu row into X
    lda #COLOR_BLUE ; load blue into A
    jsr fill_row_color ; fill the row with one color
    lda #<str_menu ; load menu string into A for primary pointer low byte
    sta ptr_lo ; store menu string into primary pointer low byte
    lda #>str_menu ; load menu string into A for primary pointer high byte
    sta ptr_hi ; store menu string into primary pointer high byte
    ldx #0 ; load 0 into X
    ldy #UI_ROW_MENU ; load menu row into Y
    lda #COLOR_LTBLUE ; load light blue into A
    jsr print_str_col ; draw the prepared string at the requested position

    ; Highlight selected building entry, then restore icon cells
    ; to multicolor map-style colours.
    jsr highlight_sel_building ; call highlight sel building
    jsr color_menu_icons ; call color menu icons

    ; ---- Row 20: power/jobs/happiness/crime ---------------
    ; First fill row with spaces
    ldx #UI_ROW_SEP ; load UI ROW SEP into X
    lda #32 ; load 32 into A
    jsr fill_row_char ; fill the row with one character
    ldx #UI_ROW_SEP ; load UI ROW SEP into X
    lda #COLOR_DKGRAY ; load COLOR DKGRAY into A
    jsr fill_row_color ; fill the row with one color

    ; PWR:
    lda #<str_pwr ; load pwr string into A for primary pointer low byte
    sta ptr_lo ; store pwr string into primary pointer low byte
    lda #>str_pwr ; load pwr string into A for primary pointer high byte
    sta ptr_hi ; store pwr string into primary pointer high byte
    ldx #0 ; load 0 into X
    ldy #UI_ROW_SEP ; load UI ROW SEP into Y
    lda #COLOR_YELLOW ; load yellow into A
    jsr print_str_col ; draw the prepared string at the requested position

    lda power_avail ; load available power total into A
    sta np_val_lo ; store available power total into number-print value low byte
    lda #0 ; load 0 into A for number-print value high byte
    sta np_val_hi ; store 0 into number-print value high byte
    ldx #2 ; load 2 into X
    ldy #UI_ROW_SEP ; load UI ROW SEP into Y
    jsr print_dec16 ; print the 16-bit value as decimal text

    ; JOB:
    lda #<str_job ; load job string into A for primary pointer low byte
    sta ptr_lo ; store job string into primary pointer low byte
    lda #>str_job ; load job string into A for primary pointer high byte
    sta ptr_hi ; store job string into primary pointer high byte
    ldx #10 ; load 10 into X
    ldy #UI_ROW_SEP ; load UI ROW SEP into Y
    lda #COLOR_LTGREEN ; load light green into A
    jsr print_str_col ; draw the prepared string at the requested position

    lda jobs_total ; load jobs total into A
    sta np_val_lo ; store jobs total into number-print value low byte
    lda #0 ; load 0 into A for number-print value high byte
    sta np_val_hi ; store 0 into number-print value high byte
    ldx #12 ; load 12 into X
    ldy #UI_ROW_SEP ; load UI ROW SEP into Y
    jsr print_dec16 ; print the 16-bit value as decimal text

    ; HAP:
    lda #<str_hap ; load hap string into A for primary pointer low byte
    sta ptr_lo ; store hap string into primary pointer low byte
    lda #>str_hap ; load hap string into A for primary pointer high byte
    sta ptr_hi ; store hap string into primary pointer high byte
    ldx #20 ; load 20 into X
    ldy #UI_ROW_SEP ; load UI ROW SEP into Y
    lda #COLOR_CYAN ; load cyan into A
    jsr print_str_col ; draw the prepared string at the requested position

    lda happiness ; load happiness into A
    sta np_val_lo ; store happiness into number-print value low byte
    lda #0 ; load 0 into A for number-print value high byte
    sta np_val_hi ; store 0 into number-print value high byte
    ldx #22 ; load 22 into X
    ldy #UI_ROW_SEP ; load UI ROW SEP into Y
    jsr print_dec16 ; print the 16-bit value as decimal text

    ; CRM:
    lda #<str_crm ; load crm string into A for primary pointer low byte
    sta ptr_lo ; store crm string into primary pointer low byte
    lda #>str_crm ; load crm string into A for primary pointer high byte
    sta ptr_hi ; store crm string into primary pointer high byte
    ldx #30 ; load 30 into X
    ldy #UI_ROW_SEP ; load UI ROW SEP into Y
    lda #COLOR_LTRED ; load light red into A
    jsr print_str_col ; draw the prepared string at the requested position

    lda crime ; load crime into A
    sta np_val_lo ; store crime into number-print value low byte
    lda #0 ; load 0 into A for number-print value high byte
    sta np_val_hi ; store 0 into number-print value high byte
    ldx #32 ; load 32 into X
    ldy #UI_ROW_SEP ; load UI ROW SEP into Y
    jsr print_dec16 ; print the 16-bit value as decimal text

    ; ---- Row 21: Year / Cash / Population -----------------
    ldx #UI_ROW_STATS ; load UI ROW STATS into X
    lda #32 ; load 32 into A
    jsr fill_row_char ; fill the row with one character
    ldx #UI_ROW_STATS ; load UI ROW STATS into X
    lda #COLOR_WHITE ; load white into A
    jsr fill_row_color ; fill the row with one color

    ; YR:
    lda #<str_yr ; load yr string into A for primary pointer low byte
    sta ptr_lo ; store yr string into primary pointer low byte
    lda #>str_yr ; load yr string into A for primary pointer high byte
    sta ptr_hi ; store yr string into primary pointer high byte
    ldx #0 ; load 0 into X
    ldy #UI_ROW_STATS ; load UI ROW STATS into Y
    lda #COLOR_YELLOW ; load yellow into A
    jsr print_str_col ; draw the prepared string at the requested position

    lda year_lo ; load year low byte into A
    sta np_val_lo ; store year low byte into number-print value low byte
    lda year_hi ; load year high byte into A
    sta np_val_hi ; store year high byte into number-print value high byte
    ldx #2 ; load 2 into X
    ldy #UI_ROW_STATS ; load UI ROW STATS into Y
    jsr print_dec16 ; print the 16-bit value as decimal text

    ; $:
    lda #<str_cash ; load cash string into A for primary pointer low byte
    sta ptr_lo ; store cash string into primary pointer low byte
    lda #>str_cash ; load cash string into A for primary pointer high byte
    sta ptr_hi ; store cash string into primary pointer high byte
    ldx #10 ; load 10 into X
    ldy #UI_ROW_STATS ; load UI ROW STATS into Y
    lda #COLOR_YELLOW ; load yellow into A
    jsr print_str_col ; draw the prepared string at the requested position

    lda money_lo ; load cash low byte into A
    sta np_val_lo ; store cash low byte into number-print value low byte
    lda money_hi ; load cash high byte into A
    sta np_val_hi ; store cash high byte into number-print value high byte
    ldx #12 ; load 12 into X
    ldy #UI_ROW_STATS ; load UI ROW STATS into Y
    jsr print_dec16 ; print the 16-bit value as decimal text

    ; POP:
    lda #<str_pop ; load pop string into A for primary pointer low byte
    sta ptr_lo ; store pop string into primary pointer low byte
    lda #>str_pop ; load pop string into A for primary pointer high byte
    sta ptr_hi ; store pop string into primary pointer high byte
    ldx #20 ; load 20 into X
    ldy #UI_ROW_STATS ; load UI ROW STATS into Y
    lda #COLOR_YELLOW ; load yellow into A
    jsr print_str_col ; draw the prepared string at the requested position

    lda population ; load population counter into A
    sta np_val_lo ; store population counter into number-print value low byte
    lda #0 ; load 0 into A for number-print value high byte
    sta np_val_hi ; store 0 into number-print value high byte
    ldx #22 ; load 22 into X
    ldy #UI_ROW_STATS ; load UI ROW STATS into Y
    jsr print_dec16 ; print the 16-bit value as decimal text

    jsr draw_cursor_tile_info ; call draw cursor tile info

    ; ---- Row 23: Mode label + message -------------------
    jsr draw_mode_row ; call draw mode row

    ; ---- Row 24: Help line ------------------------------
    lda #<str_help ; load help string into A for primary pointer low byte
    sta ptr_lo ; store help string into primary pointer low byte
    lda #>str_help ; load help string into A for primary pointer high byte
    sta ptr_hi ; store help string into primary pointer high byte
    ldx #0 ; load 0 into X
    ldy #UI_ROW_HELP ; load UI ROW HELP into Y
    lda #COLOR_MDGRAY ; load COLOR MDGRAY into A
    jsr print_str_col ; draw the prepared string at the requested position

    lda #0 ; prepare to mark the UI as clean
    sta dirty_ui ; mark the UI as clean
    rts ; Return from subroutine

; ============================================================
; draw_mode_row
; Print mode label and manage timed message on row UI_ROW_MSG.
; ============================================================
draw_mode_row:
    ; Mode label
    lda game_mode ; load current tool mode into A
    bne @dm_demo ; if the test did not match, branch to demo
    lda #<str_mode_build ; load mode build string into A for primary pointer low byte
    sta ptr_lo ; store mode build string into primary pointer low byte
    lda #>str_mode_build ; load mode build string into A for primary pointer high byte
    sta ptr_hi ; store mode build string into primary pointer high byte
    bne @dm_print ; if the test did not match, branch to print
; Continue with the demolition path.
; Branch target from draw_mode_row if the test did not match.
@dm_demo:
    lda #<str_mode_demo ; load mode demo string into A for primary pointer low byte
    sta ptr_lo ; store mode demo string into primary pointer low byte
    lda #>str_mode_demo ; load mode demo string into A for primary pointer high byte
    sta ptr_hi ; store mode demo string into primary pointer high byte
; Continue with the print path.
; Branch target from draw_mode_row if the test did not match.
@dm_print:
    ldx #0 ; load 0 into X
    ldy #UI_ROW_MSG ; load message row into Y
    lda #COLOR_CYAN ; load cyan into A
    jsr print_str_col ; draw the prepared string at the requested position

    ; Manage message timer
    lda msg_timer ; load message timer into A
    beq @dm_needs ; if the test matched, branch to needs
    dec msg_timer ; decrement message timer
    bne @dm_done ; if the test did not match, branch to done
    ; Timer expired: clear message area
; Branch target from @dm_print if the test matched.
@dm_needs:
    jsr draw_city_needs ; call draw city needs
; Finish this local path and fall back to the caller or shared exit.
; Branch target from @dm_print if the test did not match.
@dm_done:
    rts ; Return from subroutine

; ============================================================
; draw_city_needs
; Show passive city-need indicators in the message area when
; there is no active timed message.
; ============================================================
draw_city_needs:
    lda #<str_msg_empty ; load empty string into A for primary pointer low byte
    sta ptr_lo ; store empty string into primary pointer low byte
    lda #>str_msg_empty ; load empty string into A for primary pointer high byte
    sta ptr_hi ; store empty string into primary pointer high byte
    ldx #11 ; load 11 into X
    ldy #UI_ROW_MSG ; load message row into Y
    lda #COLOR_WHITE ; load white into A
    jsr print_str_col ; draw the prepared string at the requested position

    lda #<str_needs_hdr ; load needs hdr string into A for primary pointer low byte
    sta ptr_lo ; store needs hdr string into primary pointer low byte
    lda #>str_needs_hdr ; load needs hdr string into A for primary pointer high byte
    sta ptr_hi ; store needs hdr string into primary pointer high byte
    ldx #11 ; load 11 into X
    ldy #UI_ROW_MSG ; load message row into Y
    lda #COLOR_MDGRAY ; load COLOR MDGRAY into A
    jsr print_str_col ; draw the prepared string at the requested position

    lda #0 ; load 0 into A for temporary slot 1
    sta tmp1 ; store 0 into temporary slot 1

    lda power_avail ; load available power total into A
    cmp power_needed ; power demand total
    bcs @dcn_jobs ; if carry was set, branch to jobs
    lda #<str_need_pwr ; load need pwr string into A for primary pointer low byte
    sta ptr_lo ; store need pwr string into primary pointer low byte
    lda #>str_need_pwr ; load need pwr string into A for primary pointer high byte
    sta ptr_hi ; store need pwr string into primary pointer high byte
    ldx #18 ; load 18 into X
    ldy #UI_ROW_MSG ; load message row into Y
    lda #COLOR_ORANGE ; load orange into A
    jsr print_str_col ; draw the prepared string at the requested position
    lda #1 ; load 1 into A for temporary slot 1
    sta tmp1 ; store 1 into temporary slot 1

; Continue with the jobs path.
; Branch target from draw_city_needs if carry was set.
@dcn_jobs:
    lda employed_pop ; load worker supply total into A
    cmp population ; population counter
    beq @dcn_housing ; if the test matched, branch to housing
    lda #<str_need_job ; load need job string into A for primary pointer low byte
    sta ptr_lo ; store need job string into primary pointer low byte
    lda #>str_need_job ; load need job string into A for primary pointer high byte
    sta ptr_hi ; store need job string into primary pointer high byte
    ldx #22 ; load 22 into X
    ldy #UI_ROW_MSG ; load message row into Y
    lda #COLOR_YELLOW ; load yellow into A
    jsr print_str_col ; draw the prepared string at the requested position
    lda #1 ; load 1 into A for temporary slot 1
    sta tmp1 ; store 1 into temporary slot 1

; Continue with the housing path.
; Branch target from @dcn_jobs if the test matched.
@dcn_housing:
    lda population ; load population counter into A
    beq @dcn_parks ; if the test matched, branch to parks
    lda cnt_houses ; load houses into A
    jsr mul_by_10 ; call by 10
    sta tmp2 ; store A into temporary slot 2
    lda population ; load population counter into A
    cmp tmp2 ; temporary slot 2
    bcc @dcn_parks ; if carry stayed clear, branch to parks
    lda #<str_need_hse ; load need hse string into A for primary pointer low byte
    sta ptr_lo ; store need hse string into primary pointer low byte
    lda #>str_need_hse ; load need hse string into A for primary pointer high byte
    sta ptr_hi ; store need hse string into primary pointer high byte
    ldx #26 ; load 26 into X
    ldy #UI_ROW_MSG ; load message row into Y
    lda #COLOR_CYAN ; load cyan into A
    jsr print_str_col ; draw the prepared string at the requested position
    lda #1 ; load 1 into A for temporary slot 1
    sta tmp1 ; store 1 into temporary slot 1

; Continue with the parks path.
; Branch target from @dcn_housing if the test matched.
; Branch target from @dcn_housing if carry stayed clear.
@dcn_parks:
    lda happiness ; load happiness into A
    cmp #45 ; 45
    bcs @dcn_safety ; if carry was set, branch to safety
    lda #<str_need_prk ; load need prk string into A for primary pointer low byte
    sta ptr_lo ; store need prk string into primary pointer low byte
    lda #>str_need_prk ; load need prk string into A for primary pointer high byte
    sta ptr_hi ; store need prk string into primary pointer high byte
    ldx #30 ; load 30 into X
    ldy #UI_ROW_MSG ; load message row into Y
    lda #COLOR_LTGREEN ; load light green into A
    jsr print_str_col ; draw the prepared string at the requested position
    lda #1 ; load 1 into A for temporary slot 1
    sta tmp1 ; store 1 into temporary slot 1

; Continue with the safety path.
; Branch target from @dcn_parks if carry was set.
@dcn_safety:
    lda crime ; load crime into A
    cmp #35 ; 35
    bcc @dcn_ok ; if carry stayed clear, branch to ok
    lda #<str_need_saf ; load need saf string into A for primary pointer low byte
    sta ptr_lo ; store need saf string into primary pointer low byte
    lda #>str_need_saf ; load need saf string into A for primary pointer high byte
    sta ptr_hi ; store need saf string into primary pointer high byte
    ldx #34 ; load 34 into X
    ldy #UI_ROW_MSG ; load message row into Y
    lda #COLOR_LTRED ; load light red into A
    jsr print_str_col ; draw the prepared string at the requested position
    lda #1 ; load 1 into A for temporary slot 1
    sta tmp1 ; store 1 into temporary slot 1

; Continue with the ok path.
; Branch target from @dcn_safety if carry stayed clear.
@dcn_ok:
    lda tmp1 ; load temporary slot 1 into A
    bne @dcn_done ; if the test did not match, branch to done
    lda #<str_need_ok ; load need ok string into A for primary pointer low byte
    sta ptr_lo ; store need ok string into primary pointer low byte
    lda #>str_need_ok ; load need ok string into A for primary pointer high byte
    sta ptr_hi ; store need ok string into primary pointer high byte
    ldx #18 ; load 18 into X
    ldy #UI_ROW_MSG ; load message row into Y
    lda #COLOR_LTGREEN ; load light green into A
    jsr print_str_col ; draw the prepared string at the requested position

; Finish this local path and fall back to the caller or shared exit.
; Branch target from @dcn_ok if the test did not match.
@dcn_done:
    rts ; Return from subroutine

; ============================================================
; draw_cursor_tile_info
; Show the tile type and density level under the cursor on the
; stats row. Buildable tiles show L1-L4; terrain shows L-.
; ============================================================
draw_cursor_tile_info:
    lda cursor_x ; load cursor column into A
    ldx cursor_y ; load cursor row into X
    jsr get_tile ; read the tile at the requested map coordinate
    sta tmp4 ; store A into temporary slot 4
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    asl ; shift A left to multiply by two
    tax ; move A into X for the upcoming table lookup
    lda hud_tile_names,x ; load tile names into A
    sta ptr_lo ; store tile names into primary pointer low byte
    lda hud_tile_names+1,x ; load tile names+1 into A
    sta ptr_hi ; store tile names+1 into primary pointer high byte
    ldx #29 ; load 29 into X
    ldy #UI_ROW_STATS ; load UI ROW STATS into Y
    lda #COLOR_CYAN ; load cyan into A
    jsr print_str_col ; draw the prepared string at the requested position

    lda tmp4 ; load temporary slot 4 into A
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    sta tmp3 ; store A into temporary slot 3
    cmp #TILE_ROAD ; check for a road tile
    beq @dcti_segment ; if the test matched, branch to dcti segment
    cmp #TILE_BRIDGE ; check for a bridge tile
    beq @dcti_segment ; if the test matched, branch to dcti segment
    lda tmp3 ; load temporary slot 3 into A
    cmp #TILE_ROAD ; check for a road tile
    bcc @dcti_no_level ; if carry stayed clear, branch to dcti no level
    cmp #TILE_BRIDGE + 1 ; TILE BRIDGE + 1
    bcs @dcti_no_level ; if carry was set, branch to dcti no level
    lda tmp4 ; load temporary slot 4 into A
    and #TILE_DENSITY_MASK ; keep only the density bits
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    lsr ; shift A right by one bit
    asl ; shift A left to multiply by two
    tax ; move A into X for the upcoming table lookup
    lda hud_level_names,x ; load level names into A
    sta ptr_lo ; store level names into primary pointer low byte
    lda hud_level_names+1,x ; load level names+1 into A
    sta ptr_hi ; store level names+1 into primary pointer high byte
    bne @dcti_print_level ; if the test did not match, branch to dcti print level

; Continue with the dcti segment path.
; Branch target from draw_cursor_tile_info if the test matched.
; Branch target from draw_cursor_tile_info if the test matched.
@dcti_segment:
    lda #<road_component_map ; load road segment map into A for secondary pointer low byte
    sta ptr2_lo ; store road segment map into secondary pointer low byte
    lda #>road_component_map ; load road segment map into A for secondary pointer high byte
    sta ptr2_hi ; store road segment map into secondary pointer high byte
    lda cursor_x ; load cursor column into A
    sta tmp1 ; store cursor column into temporary slot 1
    lda cursor_y ; load cursor row into A
    sta tmp2 ; store cursor row into temporary slot 2
    jsr load_metric_at ; call load metric at
    asl ; shift A left to multiply by two
    tax ; move A into X for the upcoming table lookup
    lda hud_segment_names,x ; load segment names into A
    sta ptr_lo ; store segment names into primary pointer low byte
    lda hud_segment_names+1,x ; load segment names+1 into A
    sta ptr_hi ; store segment names+1 into primary pointer high byte
    bne @dcti_print_level ; if the test did not match, branch to dcti print level

; Continue with the dcti no level path.
; Branch target from draw_cursor_tile_info if carry stayed clear.
; Branch target from draw_cursor_tile_info if carry was set.
@dcti_no_level:
    lda #<str_lvl_na ; load na string into A for primary pointer low byte
    sta ptr_lo ; store na string into primary pointer low byte
    lda #>str_lvl_na ; load na string into A for primary pointer high byte
    sta ptr_hi ; store na string into primary pointer high byte

; Continue with the dcti print level path.
; Branch target from draw_cursor_tile_info if the test did not match.
; Branch target from @dcti_segment if the test did not match.
@dcti_print_level:
    ldx #34 ; load 34 into X
    ldy #UI_ROW_STATS ; load UI ROW STATS into Y
    lda #COLOR_LTBLUE ; load light blue into A
    jsr print_str_col ; draw the prepared string at the requested position

    lda tmp4 ; load temporary slot 4 into A
    jsr get_cursor_tile_impact ; call cursor tile impact
    jsr draw_cursor_tile_impact ; call draw cursor tile impact
    rts ; Return from subroutine

; ============================================================
; get_cursor_tile_impact
; A = raw tile byte. Returns the direct per-tick cash impact
; of the tile as a signed 8-bit value.
; ============================================================
get_cursor_tile_impact:
    sta tmp2 ; store A into temporary slot 2
    and #TILE_TYPE_MASK ; keep only the base tile-type bits
    tax ; move A into X for the upcoming table lookup

    cpx #TILE_ROAD ; check for a road tile
    beq @gcti_road ; if the test matched, branch to gcti road
    cpx #TILE_BRIDGE ; check for a bridge tile
    bne @gcti_house ; if the test did not match, branch to gcti house
; Continue with the gcti road path.
; Branch target from get_cursor_tile_impact if the test matched.
@gcti_road:
    lda tmp2 ; load temporary slot 2 into A
    jsr get_tile_density_units ; call tile density units
    eor #$FF ; Exclusive-OR A with operand; immediate mode #$FF
    clc ; clear carry before the next add
    adc #1 ; add 1 into A
    rts ; Return from subroutine

; Continue with the gcti house path.
; Branch target from get_cursor_tile_impact if the test did not match.
@gcti_house:
    cpx #TILE_HOUSE ; house tile type
    bne @gcti_factory ; if the test did not match, branch to gcti factory
    lda tmp2 ; load temporary slot 2 into A
    jsr get_tile_density_units ; call tile density units
    rts ; Return from subroutine

; Continue with the gcti factory path.
; Branch target from @gcti_house if the test did not match.
@gcti_factory:
    cpx #TILE_FACTORY ; factory tile type
    bne @gcti_park ; if the test did not match, branch to gcti park
    lda tmp2 ; load temporary slot 2 into A
    jsr get_tile_density_units ; call tile density units
    sta tmp4 ; store A into temporary slot 4
    jsr mul_by_10 ; call by 10
    sta tmp1 ; store A into temporary slot 1
    lda tmp4 ; load temporary slot 4 into A
    jsr mul_by_5 ; call by 5
    clc ; clear carry before the next add
    adc tmp1 ; add temporary slot 1 into A
    rts ; Return from subroutine

; Continue with the gcti park path.
; Branch target from @gcti_factory if the test did not match.
@gcti_park:
    cpx #TILE_PARK ; park tile type
    bne @gcti_power ; if the test did not match, branch to gcti power
    lda tmp2 ; load temporary slot 2 into A
    jsr get_tile_density_units ; call tile density units
    jsr mul_by_5 ; call by 5
    eor #$FF ; Exclusive-OR A with operand; immediate mode #$FF
    clc ; clear carry before the next add
    adc #1 ; add 1 into A
    rts ; Return from subroutine

; Continue with the gcti power path.
; Branch target from @gcti_park if the test did not match.
@gcti_power:
    cpx #TILE_POWER ; power-plant tile type
    bne @gcti_police ; if the test did not match, branch to gcti police
    lda tmp2 ; load temporary slot 2 into A
    jsr get_tile_density_units ; call tile density units
    jsr mul_by_20 ; call by 20
    eor #$FF ; Exclusive-OR A with operand; immediate mode #$FF
    clc ; clear carry before the next add
    adc #1 ; add 1 into A
    rts ; Return from subroutine

; Continue with the gcti police path.
; Branch target from @gcti_power if the test did not match.
@gcti_police:
    cpx #TILE_POLICE ; police tile type
    bne @gcti_fire ; if the test did not match, branch to gcti fire
    lda tmp2 ; load temporary slot 2 into A
    jsr get_tile_density_units ; call tile density units
    jsr mul_by_10 ; call by 10
    eor #$FF ; Exclusive-OR A with operand; immediate mode #$FF
    clc ; clear carry before the next add
    adc #1 ; add 1 into A
    rts ; Return from subroutine

; Continue with the gcti fire path.
; Branch target from @gcti_police if the test did not match.
@gcti_fire:
    cpx #TILE_FIRE ; fire-station tile type
    bne @gcti_zero ; if the test did not match, branch to gcti zero
    lda tmp2 ; load temporary slot 2 into A
    jsr get_tile_density_units ; call tile density units
    jsr mul_by_10 ; call by 10
    eor #$FF ; Exclusive-OR A with operand; immediate mode #$FF
    clc ; clear carry before the next add
    adc #1 ; add 1 into A
    rts ; Return from subroutine

; Continue with the gcti zero path.
; Branch target from @gcti_fire if the test did not match.
@gcti_zero:
    lda #0 ; load 0 into A
    rts ; Return from subroutine

; ============================================================
; draw_cursor_tile_impact
; A = signed 8-bit per-tick impact. Draws a compact 3-char
; signed value at the end of the stats row.
; ============================================================
draw_cursor_tile_impact:
    sta tmp4 ; store A into temporary slot 4
    lda #43 ; load 43 into A for temporary slot 1
    sta tmp1 ; store 43 into temporary slot 1
    lda #COLOR_LTGREEN ; load light green into A for temporary slot 2
    sta tmp2 ; store light green into temporary slot 2
    lda tmp4 ; load temporary slot 4 into A
    beq @dcti_zero ; if the test matched, branch to dcti zero
    bpl @dcti_abs_ready ; if the result is non-negative, branch to dcti abs ready
    lda #45 ; load 45 into A for temporary slot 1
    sta tmp1 ; store 45 into temporary slot 1
    lda #COLOR_LTRED ; load light red into A for temporary slot 2
    sta tmp2 ; store light red into temporary slot 2
    lda tmp4 ; load temporary slot 4 into A
    eor #$FF ; Exclusive-OR A with operand; immediate mode #$FF
    clc ; clear carry before the next add
    adc #1 ; add 1 into A
    bne @dcti_abs_ready ; if the test did not match, branch to dcti abs ready

; Continue with the dcti zero path.
; Branch target from draw_cursor_tile_impact if the test matched.
@dcti_zero:
    lda #COLOR_WHITE ; load white into A for temporary slot 2
    sta tmp2 ; store white into temporary slot 2
    lda #0 ; load 0 into A

; Continue with the dcti abs ready path.
; Branch target from draw_cursor_tile_impact if the result is non-negative.
; Branch target from draw_cursor_tile_impact if the test did not match.
@dcti_abs_ready:
    ldx #0 ; load 0 into X
; Continue with the dcti tens path.
; Branch target from @dcti_tens if the test did not match.
@dcti_tens:
    cmp #10 ; 10
    bcc @dcti_digits ; if carry stayed clear, branch to dcti digits
    sec ; set carry before the subtract/compare sequence
    sbc #10 ; subtract 10 from A
    inx ; advance X to the next index
    bne @dcti_tens ; if the test did not match, branch to dcti tens

; Continue with the dcti digits path.
; Branch target from @dcti_tens if carry stayed clear.
@dcti_digits:
    sta tmp3 ; store A into temporary slot 3
    stx np_div_lo ; store X into number-print work low byte

    ldy #UI_ROW_STATS ; load UI ROW STATS into Y
    lda mul40_lo,y ; load precomputed row*40 lookup into A
    clc ; clear carry before the next add
    adc #<SCREEN_BASE ; add screen RAM base into A
    sta ptr2_lo ; store A into secondary pointer low byte
    lda mul40_hi,y ; load precomputed row*40 lookup into A
    adc #>SCREEN_BASE ; add screen RAM base into A
    sta ptr2_hi ; store A into secondary pointer high byte
    lda ptr2_lo ; load secondary pointer low byte into A
    clc ; clear carry before the next add
    adc #37 ; add 37 into A
    sta ptr2_lo ; store A into secondary pointer low byte
    bcc @dcti_scr_ok ; if carry stayed clear, branch to dcti scr ok
    inc ptr2_hi ; advance the secondary pointer to the next page
; Continue with the dcti scr ok path.
; Branch target from @dcti_digits if carry stayed clear.
@dcti_scr_ok:

    ldy #UI_ROW_STATS ; load UI ROW STATS into Y
    lda mul40_lo,y ; load precomputed row*40 lookup into A
    clc ; clear carry before the next add
    adc #<COLOR_BASE ; add color RAM base into A
    sta ptr_lo ; store A into primary pointer low byte
    lda mul40_hi,y ; load precomputed row*40 lookup into A
    adc #>COLOR_BASE ; add color RAM base into A
    sta ptr_hi ; store A into primary pointer high byte
    lda ptr_lo ; load primary pointer low byte into A
    clc ; clear carry before the next add
    adc #37 ; add 37 into A
    sta ptr_lo ; store A into primary pointer low byte
    bcc @dcti_col_ok ; if carry stayed clear, branch to dcti col ok
    inc ptr_hi ; advance the primary pointer to the next page
; Continue with the dcti col ok path.
; Branch target from @dcti_scr_ok if carry stayed clear.
@dcti_col_ok:

    ldy #0 ; load 0 into Y
    lda tmp1 ; load temporary slot 1 into A
    sta (ptr2_lo),y ; store temporary slot 1 into secondary pointer low byte
    lda tmp2 ; load temporary slot 2 into A
    sta (ptr_lo),y ; store temporary slot 2 into primary pointer low byte
    iny ; advance Y to the next offset

    lda np_div_lo ; load number-print work low byte into A
    beq @dcti_blank_tens ; if the test matched, branch to dcti blank tens
    clc ; clear carry before the next add
    adc #$30 ; add $30 into A
    bne @dcti_store_tens ; if the test did not match, branch to dcti store tens
; Continue with the dcti blank tens path.
; Branch target from @dcti_col_ok if the test matched.
@dcti_blank_tens:
    lda #32 ; load 32 into A for secondary pointer low byte
; Continue with the dcti store tens path.
; Branch target from @dcti_col_ok if the test did not match.
@dcti_store_tens:
    sta (ptr2_lo),y ; store 32 into secondary pointer low byte
    lda tmp2 ; load temporary slot 2 into A
    sta (ptr_lo),y ; store temporary slot 2 into primary pointer low byte
    iny ; advance Y to the next offset

    lda tmp3 ; load temporary slot 3 into A
    clc ; clear carry before the next add
    adc #$30 ; add $30 into A
    sta (ptr2_lo),y ; store A into secondary pointer low byte
    lda tmp2 ; load temporary slot 2 into A
    sta (ptr_lo),y ; store temporary slot 2 into primary pointer low byte
    rts ; Return from subroutine

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
; Enter the menu entry col routine.
menu_entry_col:
    .byte 0, 5, 11, 17, 23, 29, 35     ; start cols for entries 1-7
; Enter the menu entry len routine.
menu_entry_len:
    .byte 4, 5,  5,  5,  5,  5,  5     ; char count for each entry
; Enter the menu icon col routine.
menu_icon_col:
    .byte 2, 7, 13, 19, 25, 31, 37
; Enter the menu icon color routine.
menu_icon_color:
    .byte MC_CHAR_FLAG + COLOR_WHITE
    .byte MC_CHAR_FLAG + COLOR_YELLOW
    .byte MC_CHAR_FLAG + COLOR_RED
    .byte MC_CHAR_FLAG + COLOR_GREEN
    .byte MC_CHAR_FLAG + COLOR_CYAN
    .byte MC_CHAR_FLAG + COLOR_BLUE
    .byte MC_CHAR_FLAG + COLOR_RED

    .segment "CODE"

; Enter the color menu icons routine.
color_menu_icons:
    ldy #UI_ROW_MENU ; load menu row into Y
    lda mul40_lo,y ; load precomputed row*40 lookup into A
    clc ; clear carry before the next add
    adc #<COLOR_BASE ; add color RAM base into A
    sta ptr2_lo ; store A into secondary pointer low byte
    lda mul40_hi,y ; load precomputed row*40 lookup into A
    adc #>COLOR_BASE ; add color RAM base into A
    sta ptr2_hi ; store A into secondary pointer high byte

    ldx #0 ; load 0 into X
; Repeat the current loop.
; Branch target from @cmi_store if the test did not match.
@cmi_loop:
    txa ; move X back into A
    clc ; clear carry before the next add
    adc #1 ; add 1 into A
    cmp sel_building ; selected building type
    bne @cmi_base ; if the test did not match, branch to base
    lda #(MC_CHAR_FLAG + COLOR_YELLOW) ; load (MC CHAR FLAG + COLOR YELLOW into A
    bne @cmi_store ; if the test did not match, branch to store
; Continue with the base path.
; Branch target from @cmi_loop if the test did not match.
@cmi_base:
    lda menu_icon_color,x ; load menu icon color into A
; Continue with the store path.
; Branch target from @cmi_loop if the test did not match.
@cmi_store:
    ldy menu_icon_col,x ; load menu icon col into Y
    sta (ptr2_lo),y ; store menu icon col into secondary pointer low byte
    inx ; advance X to the next index
    cpx #7 ; 7
    bne @cmi_loop ; if the test did not match, branch to loop
    rts ; Return from subroutine

; Enter the highlight selection building routine.
highlight_sel_building:
    lda sel_building ; load selected building type into A
    beq @hsel_done ; if the test matched, branch to hsel done
    cmp #8 ; 8
    bcs @hsel_done ; if carry was set, branch to hsel done

    ; Look up start column for this entry (sel_building is 1-7)
    tax ; move A into X for the upcoming table lookup
    dex                         ; 0-based index
    lda menu_entry_col,x ; load menu entry col into A
    sta tmp1                    ; start col
    lda menu_entry_len,x ; load menu entry len into A
    sta tmp2                    ; entry width

    ; Compute colour address: COLOR_BASE + UI_ROW_MENU*40 + col
    ldy #UI_ROW_MENU ; load menu row into Y
    lda mul40_lo,y ; load precomputed row*40 lookup into A
    clc ; clear carry before the next add
    adc #<COLOR_BASE ; add color RAM base into A
    sta ptr2_lo ; store A into secondary pointer low byte
    lda mul40_hi,y ; load precomputed row*40 lookup into A
    adc #>COLOR_BASE ; add color RAM base into A
    sta ptr2_hi ; store A into secondary pointer high byte

    lda tmp1 ; load temporary slot 1 into A
    clc ; clear carry before the next add
    adc ptr2_lo ; add secondary pointer low byte into A
    sta ptr2_lo ; store A into secondary pointer low byte
    bcc @hsel_nc ; if carry stayed clear, branch to hsel nc
    inc ptr2_hi ; advance the secondary pointer to the next page
; Continue with the hsel nc path.
; Branch target from highlight_sel_building if carry stayed clear.
@hsel_nc:

    ldy #0 ; load 0 into Y
    lda tmp2 ; load temporary slot 2 into A
    sta tmp3                    ; iteration count
    lda #COLOR_YELLOW ; load yellow into A for secondary pointer low byte
; Continue with the hsel loop path.
; Branch target from @hsel_loop if the test did not match.
@hsel_loop:
    sta (ptr2_lo),y ; store yellow into secondary pointer low byte
    iny ; advance Y to the next offset
    dec tmp3 ; decrement temporary slot 3
    bne @hsel_loop ; if the test did not match, branch to hsel loop
; Continue with the hsel completion path.
; Branch target from highlight_sel_building if the test matched.
; Branch target from highlight_sel_building if carry was set.
@hsel_done:
    rts ; Return from subroutine
