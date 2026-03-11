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
    jsr disable_cursor_sprite ; hide the cursor sprite
    lda #TITLE_BG_COLOR ; load TITLE BG COLOR into A for playfield background color
    sta split_top_bg ; store TITLE BG COLOR into playfield background color

    ; Set title colours
    lda #TITLE_BORDER ; load TITLE BORDER into A for border color register
    sta VIC_BORDER_CLR ; store TITLE BORDER into border color register
    lda #TITLE_BG_COLOR ; load TITLE BG COLOR into A for main background color register
    sta VIC_BKG_CLR0 ; store TITLE BG COLOR into main background color register

    ; Clear screen
    jsr clear_screen ; clear the whole visible screen

    ; ---- Paint title box area (rows 2-5 in cyan) ----------
    ldx #2 ; load 2 into X
; Continue with the row path.
; Branch target from @box_col if the test did not match.
@box_row:
    lda mul40_lo,x ; load precomputed row*40 lookup into A
    clc ; clear carry before the next add
    adc #<COLOR_BASE ; add color RAM base into A
    sta ptr2_lo ; store A into secondary pointer low byte
    lda mul40_hi,x ; load precomputed row*40 lookup into A
    adc #>COLOR_BASE ; add color RAM base into A
    sta ptr2_hi ; store A into secondary pointer high byte
    lda #COLOR_CYAN ; load cyan into A
    ldy #0 ; load 0 into Y for secondary pointer low byte
; Continue with the col path.
; Branch target from @box_col if the test did not match.
@box_col:
    sta (ptr2_lo),y ; store 0 into secondary pointer low byte
    iny ; advance Y to the next offset
    cpy #SCREEN_COLS ; check whether the whole row has been filled
    bne @box_col ; if the test did not match, branch to col
    inx ; advance X to the next index
    cpx #6 ; 6
    bne @box_row ; if the test did not match, branch to row

    ; ---- Row 2 border line --------------------------------
    ldx #2 ; load 2 into X
    lda #0              ; colour black for border row
    jsr set_row_color ; call row color

    ; ---- Row 5 border line --------------------------------
    ldx #5 ; load 5 into X
    jsr set_row_color ; call row color

    ; ---- Title text row 3 ---------------------------------
    lda #<str_title1 ; load title1 string into A for primary pointer low byte
    sta ptr_lo ; store title1 string into primary pointer low byte
    lda #>str_title1 ; load title1 string into A for primary pointer high byte
    sta ptr_hi ; store title1 string into primary pointer high byte
    ldx #8              ; col 8
    ldy #3              ; row 3
    lda #TITLE_TEXT_CLR ; load TITLE TEXT CLR into A
    jsr print_str_col ; draw the prepared string at the requested position

    ; ---- Subtitle row 4 -----------------------------------
    lda #<str_title2 ; load title2 string into A for primary pointer low byte
    sta ptr_lo ; store title2 string into primary pointer low byte
    lda #>str_title2 ; load title2 string into A for primary pointer high byte
    sta ptr_hi ; store title2 string into primary pointer high byte
    ldx #7 ; load 7 into X
    ldy #4 ; load 4 into Y
    lda #TITLE_SUB_CLR ; load TITLE SUB CLR into A
    jsr print_str_col ; draw the prepared string at the requested position

    ; ---- Version row 5 ------------------------------------
    lda #<str_title3 ; load title3 string into A for primary pointer low byte
    sta ptr_lo ; store title3 string into primary pointer low byte
    lda #>str_title3 ; load title3 string into A for primary pointer high byte
    sta ptr_hi ; store title3 string into primary pointer high byte
    ldx #7 ; load 7 into X
    ldy #5 ; load 5 into Y
    lda #COLOR_WHITE ; load white into A
    jsr print_str_col ; draw the prepared string at the requested position

    ; ---- Controls heading row 8 ---------------------------
    lda #<str_title_key ; load title key string into A for primary pointer low byte
    sta ptr_lo ; store title key string into primary pointer low byte
    lda #>str_title_key ; load title key string into A for primary pointer high byte
    sta ptr_hi ; store title key string into primary pointer high byte
    ldx #2 ; load 2 into X
    ldy #8 ; load 8 into Y
    lda #TITLE_CTRL_CLR ; load TITLE CTRL CLR into A
    jsr print_str_col ; draw the prepared string at the requested position

    ; ---- Control lines rows 9-13 --------------------------
    lda #<str_title_c1 ; load title c1 string into A for primary pointer low byte
    sta ptr_lo ; store title c1 string into primary pointer low byte
    lda #>str_title_c1 ; load title c1 string into A for primary pointer high byte
    sta ptr_hi ; store title c1 string into primary pointer high byte
    ldx #4 ; load 4 into X
    ldy #9 ; load 9 into Y
    lda #COLOR_WHITE ; load white into A
    jsr print_str_col ; draw the prepared string at the requested position

    lda #<str_title_c2 ; load title c2 string into A for primary pointer low byte
    sta ptr_lo ; store title c2 string into primary pointer low byte
    lda #>str_title_c2 ; load title c2 string into A for primary pointer high byte
    sta ptr_hi ; store title c2 string into primary pointer high byte
    ldx #4 ; load 4 into X
    ldy #10 ; load 10 into Y
    lda #COLOR_WHITE ; load white into A
    jsr print_str_col ; draw the prepared string at the requested position

    lda #<str_title_c3 ; load title c3 string into A for primary pointer low byte
    sta ptr_lo ; store title c3 string into primary pointer low byte
    lda #>str_title_c3 ; load title c3 string into A for primary pointer high byte
    sta ptr_hi ; store title c3 string into primary pointer high byte
    ldx #4 ; load 4 into X
    ldy #11 ; load 11 into Y
    lda #COLOR_WHITE ; load white into A
    jsr print_str_col ; draw the prepared string at the requested position

    lda #<str_title_c4 ; load title c4 string into A for primary pointer low byte
    sta ptr_lo ; store title c4 string into primary pointer low byte
    lda #>str_title_c4 ; load title c4 string into A for primary pointer high byte
    sta ptr_hi ; store title c4 string into primary pointer high byte
    ldx #4 ; load 4 into X
    ldy #12 ; load 12 into Y
    lda #COLOR_WHITE ; load white into A
    jsr print_str_col ; draw the prepared string at the requested position

    lda #<str_title_c5 ; load title c5 string into A for primary pointer low byte
    sta ptr_lo ; store title c5 string into primary pointer low byte
    lda #>str_title_c5 ; load title c5 string into A for primary pointer high byte
    sta ptr_hi ; store title c5 string into primary pointer high byte
    ldx #4 ; load 4 into X
    ldy #13 ; load 13 into Y
    lda #COLOR_WHITE ; load white into A
    jsr print_str_col ; draw the prepared string at the requested position

    ; ---- "Press any key" row 20 ---------------------------
    lda #<str_title4 ; load title4 string into A for primary pointer low byte
    sta ptr_lo ; store title4 string into primary pointer low byte
    lda #>str_title4 ; load title4 string into A for primary pointer high byte
    sta ptr_hi ; store title4 string into primary pointer high byte
    ldx #6 ; load 6 into X
    ldy #20 ; load 20 into Y
    lda #COLOR_YELLOW ; load yellow into A
    jsr print_str_col ; draw the prepared string at the requested position

    ; ---- Wait for keypress --------------------------------
    ; Flush keyboard buffer first
; Branch target from @flush if the test did not match.
@flush:
    jsr KERNAL_GETIN ; poll the keyboard buffer once
    bne @flush ; if the test did not match, branch to flush

; Continue with the wait key path.
; Branch target from @wait_key when A=0 means empty.
@wait_key:
    jsr KERNAL_GETIN ; poll the keyboard buffer once
    beq @wait_key       ; A=0 means empty

    ; Restore game colours
    lda #COLOR_GREEN ; load green into A for playfield background color
    sta split_top_bg ; store green into playfield background color
    lda #COLOR_BLACK ; load black into A for border color register
    sta VIC_BORDER_CLR ; store black into border color register
    lda #COLOR_GREEN ; load green into A for main background color register
    sta VIC_BKG_CLR0 ; store green into main background color register

    jsr clear_screen ; clear the whole visible screen
    rts ; Return from subroutine

; ------------------------------------------------------------
; set_row_color
; Fill one entire screen row in color RAM with black.
; X = row (0-24), trashes A, Y.
; ------------------------------------------------------------
set_row_color:
    lda mul40_lo,x ; load precomputed row*40 lookup into A
    clc ; clear carry before the next add
    adc #<COLOR_BASE ; add color RAM base into A
    sta ptr2_lo ; store A into secondary pointer low byte
    lda mul40_hi,x ; load precomputed row*40 lookup into A
    adc #>COLOR_BASE ; add color RAM base into A
    sta ptr2_hi ; store A into secondary pointer high byte
    lda #COLOR_BLACK ; load black into A
    ldy #0 ; load 0 into Y for secondary pointer low byte
; Repeat the current loop.
; Branch target from @src_loop if the test did not match.
@src_loop:
    sta (ptr2_lo),y ; store 0 into secondary pointer low byte
    iny ; advance Y to the next offset
    cpy #SCREEN_COLS ; check whether the whole row has been filled
    bne @src_loop ; if the test did not match, branch to loop
    rts ; Return from subroutine
