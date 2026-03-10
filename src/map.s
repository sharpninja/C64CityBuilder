; ============================================================
; C64 City Builder - Map Data and Rendering
; Included by main.s.
; ============================================================

; ------------------------------------------------------------
; BSS: 800-byte city map (one byte per tile, row-major order)
; ------------------------------------------------------------
    .segment "BSS"
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
    lda #<city_map
    sta ptr_lo
    lda #>city_map
    sta ptr_hi

    lda #<SCREEN_BASE
    sta ptr2_lo
    lda #>SCREEN_BASE
    sta ptr2_hi

    lda #<COLOR_BASE
    sta tmp1
    lda #>COLOR_BASE
    sta tmp2

    ; Three full 256-byte pages. Keep the page counter out of X because
    ; X is reused below as the tile-table index for each map byte.
    lda #3
    sta tmp4
@rm_pg:
    ldy #0
@rm_byte:
    lda (ptr_lo),y      ; tile type
    tax
    lda tile_char,x
    sta (ptr2_lo),y     ; → screen RAM
    lda tile_color,x
    sta (tmp1),y        ; → colour RAM
    iny
    bne @rm_byte
    inc ptr_hi
    inc ptr2_hi
    inc tmp2
    dec tmp4
    bne @rm_pg

    ; Remaining 32 bytes  (800 - 768 = 32)
    ldy #0
@rm_rem:
    lda (ptr_lo),y
    tax
    lda tile_char,x
    sta (ptr2_lo),y
    lda tile_color,x
    sta (tmp1),y
    iny
    cpy #(MAP_SIZE - 768)   ; 32
    bne @rm_rem

    lda #0
    sta dirty_map
    rts

; ------------------------------------------------------------
; render_tile
; Redraw a single tile at (tmp1=col, tmp2=row).
; Trashes A, X, Y, ptr_lo/hi, ptr2_lo/hi.
; ------------------------------------------------------------
render_tile:
    ; Compute map byte offset = row*40 + col
    ldy tmp2
    lda mul40_lo,y
    clc
    adc tmp1
    sta ptr_lo
    lda mul40_hi,y
    adc #0
    sta ptr_hi          ; ptr = row*40 + col  (this is just the OFFSET)

    ; Read tile from city_map
    lda ptr_lo
    clc
    adc #<city_map
    sta ptr2_lo
    lda ptr_hi
    adc #>city_map
    sta ptr2_hi
    ldy #0
    lda (ptr2_lo),y     ; tile type
    tax

    ; Write char to SCREEN_BASE + offset
    lda tile_char,x
    pha
    lda ptr_lo
    clc
    adc #<SCREEN_BASE
    sta ptr2_lo
    lda ptr_hi
    adc #>SCREEN_BASE
    sta ptr2_hi
    pla
    sta (ptr2_lo),y     ; Y still 0

    ; Write colour to COLOR_BASE + offset
    lda tile_color,x
    pha
    lda ptr_lo
    clc
    adc #<COLOR_BASE
    sta ptr2_lo
    lda ptr_hi
    adc #>COLOR_BASE
    sta ptr2_hi
    pla
    sta (ptr2_lo),y
    rts

; ------------------------------------------------------------
; get_tile (col in A, row in X) → tile type in A
; ------------------------------------------------------------
get_tile:
    ; offset = row*40 + col
    sta tmp3            ; save col
    txa                 ; A = row
    tay                 ; Y = row (for table)
    lda mul40_lo,y
    clc
    adc tmp3            ; + col
    sta ptr_lo
    lda mul40_hi,y
    adc #0
    sta ptr_hi
    ; Add city_map base
    lda ptr_lo
    clc
    adc #<city_map
    sta ptr_lo
    lda ptr_hi
    adc #>city_map
    sta ptr_hi
    ldy #0
    lda (ptr_lo),y
    rts

; ------------------------------------------------------------
; set_tile (col in A, row in X, tile in Y)
; Writes tile Y into city_map at position (col, row).
; ------------------------------------------------------------
set_tile:
    sta tmp3            ; col
    txa                 ; row
    tax                 ; X = row
    tya                 ; A = tile (we'll push it)
    pha
    txa                 ; row back to A
    tay                 ; Y = row
    lda mul40_lo,y
    clc
    adc tmp3            ; + col
    sta ptr_lo
    lda mul40_hi,y
    adc #0
    sta ptr_hi
    lda ptr_lo
    clc
    adc #<city_map
    sta ptr_lo
    lda ptr_hi
    adc #>city_map
    sta ptr_hi
    pla                 ; tile type
    ldy #0
    sta (ptr_lo),y
    rts

; ------------------------------------------------------------
; update_cursor_display
; Blink the cursor by toggling the colour of the current tile.
; ------------------------------------------------------------
update_cursor_display:
    dec blink_timer
    bne @ucd_done

    lda #CURSOR_BLINK_RATE
    sta blink_timer
    lda blink_state
    eor #1
    sta blink_state

    ; Compute colour RAM address for cursor
    ldy cursor_y
    lda mul40_lo,y
    clc
    adc cursor_x
    sta ptr_lo
    lda mul40_hi,y
    adc #0
    sta ptr_hi
    lda ptr_lo
    clc
    adc #<COLOR_BASE
    sta ptr_lo
    lda ptr_hi
    adc #>COLOR_BASE
    sta ptr_hi

    ldy #0
    lda blink_state
    beq @ucd_restore

    ; Cursor ON: save current colour, write cursor highlight
    lda (ptr_lo),y
    sta cur_save_col
    lda #CURSOR_COLOR
    sta (ptr_lo),y
    rts

@ucd_restore:
    ; Cursor OFF: get tile's proper colour and restore it
    lda cursor_x
    ldx cursor_y
    jsr get_tile
    tax
    lda tile_color,x
    sta (ptr_lo),y
@ucd_done:
    rts

; ------------------------------------------------------------
; restore_cursor_color
; Restore the colour RAM byte under the cursor to the tile's base colour.
; ------------------------------------------------------------
restore_cursor_color:
    lda cursor_x
    ldx cursor_y
    jsr get_tile
    tax

    ldy cursor_y
    lda mul40_lo,y
    clc
    adc #<COLOR_BASE
    sta ptr_lo
    lda mul40_hi,y
    adc #>COLOR_BASE
    sta ptr_hi

    lda cursor_x
    clc
    adc ptr_lo
    sta ptr_lo
    bcc @rcc_no_carry
    inc ptr_hi
@rcc_no_carry:

    ldy #0
    lda tile_color,x
    sta (ptr_lo),y
    rts
