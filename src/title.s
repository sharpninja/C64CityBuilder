; ============================================================
; C64 City Builder - Title Screen
; Included by main.s.
; ============================================================

    .segment "CODE"

; --- Colour constants for title layout ---
TITLE_BG_COLOR  = COLOR_BLUE
TITLE_BORDER    = COLOR_LTBLUE
TITLE_TEXT_CLR  = COLOR_YELLOW
TITLE_SUB_CLR   = COLOR_WHITE
TITLE_CTRL_CLR  = COLOR_LTGREEN

; ------------------------------------------------------------
; show_title
; Displays the title screen and waits for a keypress.
; Trashes A, X, Y.
; ------------------------------------------------------------
show_title:
    jsr disable_cursor_sprite
    lda #TITLE_BG_COLOR
    sta split_top_bg

    ; Set title colours
    lda #TITLE_BORDER
    sta VIC_BORDER_CLR
    lda #TITLE_BG_COLOR
    sta VIC_BKG_CLR0

    ; Clear screen
    jsr clear_screen

    ; ---- Paint title box area (rows 2-5 in cyan) ----------
    ldx #2
@box_row:
    lda mul40_lo,x
    clc
    adc #<COLOR_BASE
    sta ptr2_lo
    lda mul40_hi,x
    adc #>COLOR_BASE
    sta ptr2_hi
    lda #COLOR_CYAN
    ldy #0
@box_col:
    sta (ptr2_lo),y
    iny
    cpy #SCREEN_COLS
    bne @box_col
    inx
    cpx #6
    bne @box_row

    ; ---- Row 2 border line --------------------------------
    ldx #2
    lda #0              ; colour black for border row
    jsr set_row_color

    ; ---- Row 5 border line --------------------------------
    ldx #5
    jsr set_row_color

    ; ---- Title text row 3 ---------------------------------
    lda #<str_title1
    sta ptr_lo
    lda #>str_title1
    sta ptr_hi
    ldx #8              ; col 8
    ldy #3              ; row 3
    lda #TITLE_TEXT_CLR
    jsr print_str_col

    ; ---- Subtitle row 4 -----------------------------------
    lda #<str_title2
    sta ptr_lo
    lda #>str_title2
    sta ptr_hi
    ldx #7
    ldy #4
    lda #TITLE_SUB_CLR
    jsr print_str_col

    ; ---- Version row 5 ------------------------------------
    lda #<str_title3
    sta ptr_lo
    lda #>str_title3
    sta ptr_hi
    ldx #7
    ldy #5
    lda #COLOR_WHITE
    jsr print_str_col

    ; ---- Controls heading row 8 ---------------------------
    lda #<str_title_key
    sta ptr_lo
    lda #>str_title_key
    sta ptr_hi
    ldx #2
    ldy #8
    lda #TITLE_CTRL_CLR
    jsr print_str_col

    ; ---- Control lines rows 9-13 --------------------------
    lda #<str_title_c1
    sta ptr_lo
    lda #>str_title_c1
    sta ptr_hi
    ldx #4
    ldy #9
    lda #COLOR_WHITE
    jsr print_str_col

    lda #<str_title_c2
    sta ptr_lo
    lda #>str_title_c2
    sta ptr_hi
    ldx #4
    ldy #10
    lda #COLOR_WHITE
    jsr print_str_col

    lda #<str_title_c3
    sta ptr_lo
    lda #>str_title_c3
    sta ptr_hi
    ldx #4
    ldy #11
    lda #COLOR_WHITE
    jsr print_str_col

    lda #<str_title_c4
    sta ptr_lo
    lda #>str_title_c4
    sta ptr_hi
    ldx #4
    ldy #12
    lda #COLOR_WHITE
    jsr print_str_col

    lda #<str_title_c5
    sta ptr_lo
    lda #>str_title_c5
    sta ptr_hi
    ldx #4
    ldy #13
    lda #COLOR_WHITE
    jsr print_str_col

    ; ---- "Press any key" row 20 ---------------------------
    lda #<str_title4
    sta ptr_lo
    lda #>str_title4
    sta ptr_hi
    ldx #6
    ldy #20
    lda #COLOR_YELLOW
    jsr print_str_col

    ; ---- Wait for keypress --------------------------------
    ; Flush keyboard buffer first
@flush:
    jsr KERNAL_GETIN
    bne @flush

@wait_key:
    jsr KERNAL_GETIN
    beq @wait_key       ; A=0 means empty

    ; Restore game colours
    lda #COLOR_GREEN
    sta split_top_bg
    lda #COLOR_BLACK
    sta VIC_BORDER_CLR
    lda #COLOR_GREEN
    sta VIC_BKG_CLR0

    jsr clear_screen
    rts

; ------------------------------------------------------------
; set_row_color
; Fill one entire screen row in color RAM with black.
; X = row (0-24), trashes A, Y.
; ------------------------------------------------------------
set_row_color:
    lda mul40_lo,x
    clc
    adc #<COLOR_BASE
    sta ptr2_lo
    lda mul40_hi,x
    adc #>COLOR_BASE
    sta ptr2_hi
    lda #COLOR_BLACK
    ldy #0
@src_loop:
    sta (ptr2_lo),y
    iny
    cpy #SCREEN_COLS
    bne @src_loop
    rts
