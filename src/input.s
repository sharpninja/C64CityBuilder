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
    bne @ri_check_w
    jmp @ri_up
@ri_check_w:
    cmp #KEY_CHR_W
    bne @ri_check_down
    jmp @ri_up
@ri_check_down:
    cmp #KEY_CRSR_DOWN
    bne @ri_check_s
    jmp @ri_down
@ri_check_s:
    cmp #KEY_CHR_S
    bne @ri_check_left
    jmp @ri_down
@ri_check_left:
    cmp #KEY_CRSR_LEFT
    bne @ri_check_a
    jmp @ri_left
@ri_check_a:
    cmp #KEY_CHR_A
    bne @ri_check_right
    jmp @ri_left
@ri_check_right:
    cmp #KEY_CRSR_RIGHT
    bne @ri_check_d
    jmp @ri_right
@ri_check_d:
    cmp #KEY_CHR_D
    bne @ri_check_1
    jmp @ri_right

    ; ---- Building selection (1-7) --------------------------
@ri_check_1:
    cmp #KEY_CHR_1
    bne @ri_check_2
    jmp @ri_sel1
@ri_check_2:
    cmp #KEY_CHR_2
    bne @ri_check_3
    jmp @ri_sel2
@ri_check_3:
    cmp #KEY_CHR_3
    bne @ri_check_4
    jmp @ri_sel3
@ri_check_4:
    cmp #KEY_CHR_4
    bne @ri_check_5
    jmp @ri_sel4
@ri_check_5:
    cmp #KEY_CHR_5
    bne @ri_check_6
    jmp @ri_sel5
@ri_check_6:
    cmp #KEY_CHR_6
    bne @ri_check_7
    jmp @ri_sel6
@ri_check_7:
    cmp #KEY_CHR_7
    bne @ri_check_action
    jmp @ri_sel7

    ; ---- Action keys --------------------------------------
@ri_check_action:
    cmp #KEY_RETURN
    bne @ri_check_b
    jmp @ri_build
@ri_check_b:
    cmp #KEY_CHR_B
    bne @ri_check_x
    jmp @ri_build
@ri_check_x:
    cmp #KEY_CHR_X
    bne @ri_check_q
    jmp @ri_demo
@ri_check_q:
    cmp #KEY_CHR_Q
    bne @ri_unknown
    jmp @ri_quit

@ri_unknown:
    rts                     ; unrecognised key

    ; ---- Movement handlers --------------------------------
@ri_up:
    jsr restore_cursor_color
    lda cursor_y
    bne @ri_up_move
    jmp @ri_done
@ri_up_move:
    dec cursor_y
    jmp @ri_moved
@ri_down:
    jsr restore_cursor_color
    lda cursor_y
    cmp #MAP_HEIGHT - 1
    bne @ri_down_move
    jmp @ri_done
@ri_down_move:
    inc cursor_y
    jmp @ri_moved
@ri_left:
    jsr restore_cursor_color
    lda cursor_x
    bne @ri_left_move
    jmp @ri_done
@ri_left_move:
    dec cursor_x
    jmp @ri_moved
@ri_right:
    jsr restore_cursor_color
    lda cursor_x
    cmp #MAP_WIDTH - 1
    bne @ri_right_move
    jmp @ri_done
@ri_right_move:
    inc cursor_x
@ri_moved:
    lda #1
    sta dirty_map
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
    lda #MODE_BUILD
    sta game_mode
    jsr try_place_building
    rts

@ri_demo:
    lda #MODE_DEMO
    sta game_mode
    jsr try_demolish
    rts

@ri_quit:
    jsr show_title
    jsr clear_screen
    jsr render_map
    jsr draw_status_bar
    jsr enable_cursor_sprite
@ri_done:
    rts
