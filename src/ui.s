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

    ; Base colour address = COLOR_BASE + row*40
    ldx tmp2
    lda mul40_lo,x
    clc
    adc #<COLOR_BASE
    sta np_div_lo
    lda mul40_hi,x
    adc #>COLOR_BASE
    sta np_div_hi

    ; Add column offset
    lda tmp1
    clc
    adc np_div_lo
    sta np_div_lo
    bcc @psc_nc2
    inc np_div_hi
@psc_nc2:

    ; Print characters until null terminator
    ldy #0
@psc_loop:
    lda (ptr_lo),y
    beq @psc_done
    sta (ptr2_lo),y         ; write screen char
    lda tmp3
    sta (np_div_lo),y       ; write colour
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

    ; Compute colour destination: COLOR_BASE + row*40 + col
    ldx tmp2
    lda mul40_lo,x
    clc
    adc #<COLOR_BASE
    sta tmp4
    lda mul40_hi,x
    adc #>COLOR_BASE
    sta np_val_hi       ; reuse np_val as colour pointer (value already saved)
    lda tmp4
    clc
    adc tmp1
    sta np_val_lo
    bcc @pd_nc2
    inc np_val_hi
@pd_nc2:

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
    adc #48             ; → screen code for '0'-'9'  (C=0 here from bcc)
    sta (ptr2_lo),y

    lda #COLOR_WHITE
    sta (np_val_lo),y

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
    ; ---- Row 20: power/happiness/crime (compact stats) ----
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
    lda #COLOR_ORANGE
    jsr print_str_col

    lda power_avail
    sta np_val_lo
    lda #0
    sta np_val_hi
    ldx #4
    ldy #UI_ROW_SEP
    jsr print_dec16

    ; HAP:
    lda #<str_hap
    sta ptr_lo
    lda #>str_hap
    sta ptr_hi
    ldx #10
    ldy #UI_ROW_SEP
    lda #COLOR_ORANGE
    jsr print_str_col

    lda happiness
    sta np_val_lo
    lda #0
    sta np_val_hi
    ldx #15
    ldy #UI_ROW_SEP
    jsr print_dec16

    ; CRM:
    lda #<str_crm
    sta ptr_lo
    lda #>str_crm
    sta ptr_hi
    ldx #19
    ldy #UI_ROW_SEP
    lda #COLOR_ORANGE
    jsr print_str_col

    lda crime
    sta np_val_lo
    lda #0
    sta np_val_hi
    ldx #24
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
    beq @dm_done
    dec msg_timer
    bne @dm_done
    ; Timer expired: clear message area
    lda #<str_msg_empty
    sta ptr_lo
    lda #>str_msg_empty
    sta ptr_hi
    ldx #11
    ldy #UI_ROW_MSG
    lda #COLOR_WHITE
    jsr print_str_col
@dm_done:
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
