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
    bne @ri_process ; if the test did not match, branch to process
    rts                     ; nothing pressed
; Continue with the process path.
; Branch target from read_input if the test did not match.
@ri_process:

    ; Normalise: convert lowercase (a-z) to uppercase
    cmp #$61                ; 'a'
    bcc @ri_not_lc ; if carry stayed clear, branch to not lc
    cmp #$7B                ; past 'z'
    bcs @ri_not_lc ; if carry was set, branch to not lc
    and #$DF                ; clear bit 5 → uppercase
; Continue with the not lc path.
; Branch target from @ri_process if carry stayed clear.
; Branch target from @ri_process if carry was set.
@ri_not_lc:

    ; ---- Cursor movement (WASD + cursor keys) -------------
    cmp #KEY_CRSR_UP ; check for cursor up
    bne @ri_check_w ; if the test did not match, branch to check w
    jmp @ri_up ; continue at up
; Check w.
; Branch target from @ri_not_lc if the test did not match.
@ri_check_w:
    cmp #KEY_CHR_W ; check for the W key
    bne @ri_check_down ; if the test did not match, branch to check down
    jmp @ri_up ; continue at up
; Check downward.
; Branch target from @ri_check_w if the test did not match.
@ri_check_down:
    cmp #KEY_CRSR_DOWN ; check for cursor down
    bne @ri_check_s ; if the test did not match, branch to check s
    jmp @ri_down ; continue at down
; Check s.
; Branch target from @ri_check_down if the test did not match.
@ri_check_s:
    cmp #KEY_CHR_S ; check for the S key
    bne @ri_check_left ; if the test did not match, branch to check left
    jmp @ri_down ; continue at down
; Check leftward.
; Branch target from @ri_check_s if the test did not match.
@ri_check_left:
    cmp #KEY_CRSR_LEFT ; check for cursor left
    bne @ri_check_a ; if the test did not match, branch to check a
    jmp @ri_left ; continue at left
; Check a.
; Branch target from @ri_check_left if the test did not match.
@ri_check_a:
    cmp #KEY_CHR_A ; check for the A key
    bne @ri_check_right ; if the test did not match, branch to check right
    jmp @ri_left ; continue at left
; Check rightward.
; Branch target from @ri_check_a if the test did not match.
@ri_check_right:
    cmp #KEY_CRSR_RIGHT ; check for cursor right
    bne @ri_check_d ; if the test did not match, branch to check d
    jmp @ri_right ; continue at right
; Check d.
; Branch target from @ri_check_right if the test did not match.
@ri_check_d:
    cmp #KEY_CHR_D ; check for the D key
    bne @ri_check_1 ; if the test did not match, branch to check 1
    jmp @ri_right ; continue at right

    ; ---- Building selection (1-7) --------------------------
; Branch target from @ri_check_d if the test did not match.
@ri_check_1:
    cmp #KEY_CHR_1 ; KEY CHR 1
    bne @ri_check_2 ; if the test did not match, branch to check 2
    jmp @ri_sel1 ; continue at select 1
; Check 2.
; Branch target from @ri_check_1 if the test did not match.
@ri_check_2:
    cmp #KEY_CHR_2 ; KEY CHR 2
    bne @ri_check_3 ; if the test did not match, branch to check 3
    jmp @ri_sel2 ; continue at select 2
; Check 3.
; Branch target from @ri_check_2 if the test did not match.
@ri_check_3:
    cmp #KEY_CHR_3 ; KEY CHR 3
    bne @ri_check_4 ; if the test did not match, branch to check 4
    jmp @ri_sel3 ; continue at select 3
; Check 4.
; Branch target from @ri_check_3 if the test did not match.
@ri_check_4:
    cmp #KEY_CHR_4 ; KEY CHR 4
    bne @ri_check_5 ; if the test did not match, branch to check 5
    jmp @ri_sel4 ; continue at select 4
; Check 5.
; Branch target from @ri_check_4 if the test did not match.
@ri_check_5:
    cmp #KEY_CHR_5 ; KEY CHR 5
    bne @ri_check_6 ; if the test did not match, branch to check 6
    jmp @ri_sel5 ; continue at select 5
; Check 6.
; Branch target from @ri_check_5 if the test did not match.
@ri_check_6:
    cmp #KEY_CHR_6 ; KEY CHR 6
    bne @ri_check_7 ; if the test did not match, branch to check 7
    jmp @ri_sel6 ; continue at select 6
; Check 7.
; Branch target from @ri_check_6 if the test did not match.
@ri_check_7:
    cmp #KEY_CHR_7 ; KEY CHR 7
    bne @ri_check_action ; if the test did not match, branch to check action
    jmp @ri_sel7 ; continue at select 7

    ; ---- Action keys --------------------------------------
; Branch target from @ri_check_7 if the test did not match.
@ri_check_action:
    cmp #KEY_RETURN ; check for the Return key
    bne @ri_check_b ; if the test did not match, branch to check b
    jmp @ri_build ; continue at build
; Check b.
; Branch target from @ri_check_action if the test did not match.
@ri_check_b:
    cmp #KEY_CHR_B ; check for the B key
    bne @ri_check_x ; if the test did not match, branch to check x
    jmp @ri_build ; continue at build
; Check x.
; Branch target from @ri_check_b if the test did not match.
@ri_check_x:
    cmp #KEY_CHR_X ; check for the X key
    bne @ri_check_q ; if the test did not match, branch to check q
    jmp @ri_demo ; continue at demo
; Check q.
; Branch target from @ri_check_x if the test did not match.
@ri_check_q:
    cmp #KEY_CHR_Q ; check for the Q key
    bne @ri_unknown ; if the test did not match, branch to unknown
    jmp @ri_quit ; continue at quit

; Handle an unrecognized input path.
; Branch target from @ri_check_q if the test did not match.
@ri_unknown:
    rts                     ; unrecognised key

    ; ---- Movement handlers --------------------------------
@ri_up:
    jsr restore_cursor_color ; restore the tile color under the cursor
    lda cursor_y ; load cursor row into A
    bne @ri_up_move ; if the test did not match, branch to up move
    jmp @ri_done ; continue at done
; Handle the upward movement path.
; Branch target from @ri_up if the test did not match.
@ri_up_move:
    dec cursor_y ; move the cursor one tile up
    jmp @ri_moved ; continue at moved
; Handle the downward movement path.
@ri_down:
    jsr restore_cursor_color ; restore the tile color under the cursor
    lda cursor_y ; load cursor row into A
    cmp #MAP_HEIGHT - 1 ; check whether we are already on the last row
    bne @ri_down_move ; if the test did not match, branch to down move
    jmp @ri_done ; continue at done
; Handle the downward movement path.
; Branch target from @ri_down if the test did not match.
@ri_down_move:
    inc cursor_y ; move the cursor one tile down
    jmp @ri_moved ; continue at moved
; Handle the leftward movement path.
@ri_left:
    jsr restore_cursor_color ; restore the tile color under the cursor
    lda cursor_x ; load cursor column into A
    bne @ri_left_move ; if the test did not match, branch to left move
    jmp @ri_done ; continue at done
; Handle the leftward movement path.
; Branch target from @ri_left if the test did not match.
@ri_left_move:
    dec cursor_x ; move the cursor one tile left
    jmp @ri_moved ; continue at moved
; Handle the rightward movement path.
@ri_right:
    jsr restore_cursor_color ; restore the tile color under the cursor
    lda cursor_x ; load cursor column into A
    cmp #MAP_WIDTH - 1 ; check whether we are already on the last column
    bne @ri_right_move ; if the test did not match, branch to right move
    jmp @ri_done ; continue at done
; Handle the rightward movement path.
; Branch target from @ri_right if the test did not match.
@ri_right_move:
    inc cursor_x ; move the cursor one tile right
; Continue with the moved path.
@ri_moved:
    lda #1 ; prepare to mark the map as needing a redraw
    sta dirty_map ; mark the map as needing a redraw
    sta dirty_ui ; store A into UI redraw flag
    rts ; Return from subroutine

    ; ---- Building selection handlers ----------------------
@ri_sel1:
    lda #TILE_ROAD ; load check for a road tile into A
    bne @ri_setsel ; if the test did not match, branch to setsel
; Continue with the sel2 path.
@ri_sel2:
    lda #TILE_HOUSE ; load house tile type into A
    bne @ri_setsel ; if the test did not match, branch to setsel
; Continue with the sel3 path.
@ri_sel3:
    lda #TILE_FACTORY ; load factory tile type into A
    bne @ri_setsel ; if the test did not match, branch to setsel
; Continue with the sel4 path.
@ri_sel4:
    lda #TILE_PARK ; load park tile type into A
    bne @ri_setsel ; if the test did not match, branch to setsel
; Continue with the sel5 path.
@ri_sel5:
    lda #TILE_POWER ; load power-plant tile type into A
    bne @ri_setsel ; if the test did not match, branch to setsel
; Continue with the sel6 path.
@ri_sel6:
    lda #TILE_POLICE ; load police tile type into A
    bne @ri_setsel ; if the test did not match, branch to setsel
; Continue with the sel7 path.
@ri_sel7:
    lda #TILE_FIRE ; load fire-station tile type into A for selected building type
; Commit the newly selected building and switch back to build mode.
; Branch target from @ri_sel1 if the test did not match.
; Branch target from @ri_sel2 if the test did not match.
; Branch target from @ri_sel3 if the test did not match.
; Branch target from @ri_sel4 if the test did not match.
; Branch target from @ri_sel5 if the test did not match.
; Branch target from @ri_sel6 if the test did not match.
@ri_setsel:
    sta sel_building ; store fire-station tile type into selected building type
    lda #MODE_BUILD ; load build mode into A for current tool mode
    sta game_mode ; store build mode into current tool mode
    lda #1 ; prepare to mark the UI as needing a redraw
    sta dirty_ui ; mark the UI as needing a redraw
    jsr show_building_name ; show the selected building name
    rts ; Return from subroutine

    ; ---- Build / demolish / quit --------------------------
@ri_build:
    lda #MODE_BUILD ; load build mode into A for current tool mode
    sta game_mode ; store build mode into current tool mode
    jsr try_place_building ; attempt to place the selected building
    rts ; Return from subroutine

; Continue with the demolition path.
@ri_demo:
    lda #MODE_DEMO ; load demolish mode into A for current tool mode
    sta game_mode ; store demolish mode into current tool mode
    jsr try_demolish ; attempt to demolish the current tile
    rts ; Return from subroutine

; Continue with the quit path.
@ri_quit:
    jsr show_title ; display the title screen
    jsr clear_screen ; clear the whole visible screen
    jsr render_map ; redraw the full city map
    jsr draw_status_bar ; redraw the status bar
    jsr enable_cursor_sprite ; show the cursor sprite
; Finish this local path and fall back to the caller or shared exit.
@ri_done:
    rts ; Return from subroutine
