; ============================================================
; C64 City Builder - Keyboard Input Handler
; Included by main.s.
; ============================================================

    .segment "CODE"

; ------------------------------------------------------------
; read_input
; Poll GETIN once.  Processes movement, building selection,
; build, demolish, and quit actions.
; Returns immediately if the keyboard buffer is empty.
; ------------------------------------------------------------
read_input:
    jsr KERNAL_GETIN        ; A = PETSCII char; 0 if buffer empty
    bne @ri_process
    rts                     ; nothing pressed
@ri_process:

    ; Normalise: convert lowercase (a-z) to uppercase
    cmp #$61                ; 'a'
    bcc @ri_not_lc
    cmp #$7B                ; past 'z'
    bcs @ri_not_lc
    and #$DF                ; clear bit 5 → uppercase
@ri_not_lc:

    ; ---- Cursor movement (WASD + cursor keys) -------------
    cmp #KEY_CRSR_UP
    beq @ri_up
    cmp #KEY_CHR_W
    beq @ri_up
    cmp #KEY_CRSR_DOWN
    beq @ri_down
    cmp #KEY_CHR_S
    beq @ri_down
    cmp #KEY_CRSR_LEFT
    beq @ri_left
    cmp #KEY_CHR_A
    beq @ri_left
    cmp #KEY_CRSR_RIGHT
    beq @ri_right
    cmp #KEY_CHR_D
    beq @ri_right

    ; ---- Building selection (1-7) --------------------------
    cmp #KEY_CHR_1
    beq @ri_sel1
    cmp #KEY_CHR_2
    beq @ri_sel2
    cmp #KEY_CHR_3
    beq @ri_sel3
    cmp #KEY_CHR_4
    beq @ri_sel4
    cmp #KEY_CHR_5
    beq @ri_sel5
    cmp #KEY_CHR_6
    beq @ri_sel6
    cmp #KEY_CHR_7
    beq @ri_sel7

    ; ---- Action keys --------------------------------------
    cmp #KEY_RETURN
    beq @ri_build
    cmp #KEY_CHR_B
    beq @ri_build
    cmp #KEY_CHR_X
    beq @ri_demo
    cmp #KEY_CHR_Q
    beq @ri_quit

    rts                     ; unrecognised key

    ; ---- Movement handlers --------------------------------
@ri_up:
    lda cursor_y
    beq @ri_done
    dec cursor_y
    jmp @ri_moved
@ri_down:
    lda cursor_y
    cmp #MAP_HEIGHT - 1
    beq @ri_done
    inc cursor_y
    jmp @ri_moved
@ri_left:
    lda cursor_x
    beq @ri_done
    dec cursor_x
    jmp @ri_moved
@ri_right:
    lda cursor_x
    cmp #MAP_WIDTH - 1
    beq @ri_done
    inc cursor_x
@ri_moved:
    lda #1
    sta dirty_ui
    rts

    ; ---- Building selection handlers ----------------------
@ri_sel1:
    lda #TILE_ROAD
    bne @ri_setsel
@ri_sel2:
    lda #TILE_HOUSE
    bne @ri_setsel
@ri_sel3:
    lda #TILE_FACTORY
    bne @ri_setsel
@ri_sel4:
    lda #TILE_PARK
    bne @ri_setsel
@ri_sel5:
    lda #TILE_POWER
    bne @ri_setsel
@ri_sel6:
    lda #TILE_POLICE
    bne @ri_setsel
@ri_sel7:
    lda #TILE_FIRE
@ri_setsel:
    sta sel_building
    lda #MODE_BUILD
    sta game_mode
    lda #1
    sta dirty_ui
    jsr show_building_name
    rts

    ; ---- Build / demolish / quit --------------------------
@ri_build:
    jsr try_place_building
    rts

@ri_demo:
    jsr try_demolish
    rts

@ri_quit:
    jsr show_title
    jsr init_system
    jsr render_map
    jsr draw_status_bar
@ri_done:
    rts
