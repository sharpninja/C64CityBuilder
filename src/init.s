; ============================================================
; C64 City Builder - System Initialisation
; Included by main.s  (single-unit build).
; ============================================================

    .segment "CODE"

; ------------------------------------------------------------
; init_system
; Full machine setup: screen colours, zero-page variables, map.
; Trashes A, X, Y.
; ------------------------------------------------------------
init_system:
    sei                         ; disable IRQ while we poke hardware

    ; Force lowercase-capable character set during startup (POKE 53272,23 equivalent).
    lda VIC_VMEM_CTRL
    and #$F1                   ; clear charset bits 1-3
    ora #$06                   ; set charset bits for PETSCII set 2 (big/small chars)
    sta VIC_VMEM_CTRL

    ; VIC-II colours
    lda #COLOR_BLACK
    sta VIC_BORDER_CLR
    lda #COLOR_GREEN
    sta VIC_BKG_CLR0

    ; Clear screen + colour RAM
    jsr clear_screen
    jsr init_cursor_sprite

    ; ---- Zero-page variables --------------------------------
    lda #INITIAL_MONEY_LO
    sta money_lo
    lda #INITIAL_MONEY_HI
    sta money_hi

    lda #INITIAL_YEAR_LO
    sta year_lo
    lda #INITIAL_YEAR_HI
    sta year_hi

    lda #INITIAL_HAPPINESS
    sta happiness
    lda #INITIAL_CRIME
    sta crime

    lda #0
    sta population
    sta power_avail
    sta power_needed
    sta tick_count
    sta cnt_roads
    sta cnt_houses
    sta cnt_factories
    sta cnt_parks
    sta cnt_power
    sta cnt_police
    sta cnt_fire
    sta key_last
    sta msg_timer
    sta blink_state
    lda #COLOR_GREEN
    sta split_top_bg
    lda #0
    sta raster_phase

    ; Cursor at map centre
    lda #MAP_WIDTH / 2
    sta cursor_x
    lda #MAP_HEIGHT / 2
    sta cursor_y

    ; Default selection: Road
    lda #TILE_ROAD
    sta sel_building

    lda #MODE_BUILD
    sta game_mode

    ; Force first-frame full redraw
    lda #1
    sta dirty_map
    sta dirty_ui

    ; Timers
    lda #SIM_INTERVAL
    sta sim_counter
    lda #CURSOR_BLINK_RATE
    sta blink_timer

    ; Sync to jiffy clock
    lda JIFFY_LO
    sta last_jiffy

    jsr init_map
    jsr init_raster_split

    cli
    rts

; ------------------------------------------------------------
; init_cursor_sprite
; Copy the sprite pattern into RAM and configure sprite 0, but
; keep it hidden until gameplay starts.
; ------------------------------------------------------------
init_cursor_sprite:
    lda #<cursor_sprite_data
    sta ptr_lo
    lda #>cursor_sprite_data
    sta ptr_hi
    lda #<SPRITE0_DATA
    sta ptr2_lo
    lda #>SPRITE0_DATA
    sta ptr2_hi

    ldy #0
@ics_copy:
    lda (ptr_lo),y
    sta (ptr2_lo),y
    iny
    cpy #64
    bne @ics_copy

    lda #SPRITE0_PTR
    sta SPRITE0_PTR_LOC

    lda VIC_SPR_X_MSB
    and #$FE
    sta VIC_SPR_X_MSB

    lda VIC_SPR_EXP_X
    and #$FE
    sta VIC_SPR_EXP_X

    lda VIC_SPR_EXP_Y
    and #$FE
    sta VIC_SPR_EXP_Y

    lda VIC_SPR_MC
    and #$FE
    sta VIC_SPR_MC

    lda VIC_SPR_BG_PRIO
    and #$FE
    sta VIC_SPR_BG_PRIO

    lda #CURSOR_COLOR
    sta VIC_SPR0_COLOR

    jsr disable_cursor_sprite
    rts

; ------------------------------------------------------------
; enable_cursor_sprite / disable_cursor_sprite
; ------------------------------------------------------------
enable_cursor_sprite:
    jsr update_cursor_display
    lda VIC_SPRITE_EN
    ora #$01
    sta VIC_SPRITE_EN
    rts

disable_cursor_sprite:
    lda VIC_SPRITE_EN
    and #$FE
    sta VIC_SPRITE_EN
    rts

; ------------------------------------------------------------
; init_raster_split
; Install a raster IRQ that restores the playfield background
; at the top of the frame, then switches the lower 5 rows to
; black for the UI/status panel.
; ------------------------------------------------------------
init_raster_split:
    lda #<raster_irq
    sta IRQ_VECTOR_LO
    lda #>raster_irq
    sta IRQ_VECTOR_HI

    lda #0
    sta raster_phase

    lda VIC_CTRL1
    and #$7F
    sta VIC_CTRL1

    lda #RASTER_SPLIT_TOP
    sta VIC_RASTER

    lda #$01
    sta VIC_IRQ_STATUS

    lda VIC_IRQ_CTRL
    ora #$01
    sta VIC_IRQ_CTRL
    rts

; ------------------------------------------------------------
; raster_irq
; Two-phase raster IRQ. This handler is reached through the
; KERNAL RAM IRQ vector, so A/X/Y are already saved on the
; stack before we enter. The top-of-frame IRQ restores the
; active background colour, and the lower IRQ switches the
; status area background to black.
; ------------------------------------------------------------
raster_irq:
    lda VIC_IRQ_STATUS
    and #$01
    beq @chain_kernal

    lda raster_phase
    beq @top_phase

@lower_phase:
    lda #COLOR_BLACK
    sta VIC_BKG_CLR0
    lda #0
    sta raster_phase
    lda #RASTER_SPLIT_TOP
    sta VIC_RASTER
    lda VIC_CTRL1
    and #$7F
    sta VIC_CTRL1
    lda #$01
    sta VIC_IRQ_STATUS
    jmp @irq_done

@top_phase:
    lda split_top_bg
    sta VIC_BKG_CLR0
    lda #1
    sta raster_phase
    lda #RASTER_SPLIT_LOWER
    sta VIC_RASTER
    lda VIC_CTRL1
    and #$7F
    sta VIC_CTRL1
    lda #$01
    sta VIC_IRQ_STATUS

@irq_done:
    pla
    tay
    pla
    tax
    pla
    rti

@chain_kernal:
    jmp KERNAL_IRQ

; ------------------------------------------------------------
; clear_screen
; Fill screen RAM ($0400) with spaces and colour RAM ($D800)
; with COLOR_GREEN.  800 bytes (map area) get green; all 1000
; bytes are written so the UI area starts clean.
; ------------------------------------------------------------
clear_screen:
    lda #<SCREEN_BASE
    sta ptr_lo
    lda #>SCREEN_BASE
    sta ptr_hi
    lda #<COLOR_BASE
    sta ptr2_lo
    lda #>COLOR_BASE
    sta ptr2_hi

    ; Write 3 full pages (768 bytes)
    ldx #3
@pg_loop:
    ldy #0
@byte_loop:
    lda #32                 ; space
    sta (ptr_lo),y
    lda #COLOR_GREEN
    sta (ptr2_lo),y
    iny
    bne @byte_loop
    inc ptr_hi
    inc ptr2_hi
    dex
    bne @pg_loop

    ; Write remaining 232 bytes (768+232=1000)
    ldy #0
@rem_loop:
    lda #32
    sta (ptr_lo),y
    lda #COLOR_GREEN
    sta (ptr2_lo),y
    iny
    cpy #(SCREEN_SIZE - 768)
    bne @rem_loop
    rts

; ------------------------------------------------------------
; init_map
; Fill the 800-byte city_map with TILE_EMPTY, then add a
; river across row 10 and scatter trees in rows 0-2 and 19.
; ------------------------------------------------------------
init_map:
    lda #<city_map
    sta ptr_lo
    lda #>city_map
    sta ptr_hi

    ; --- 3 full 256-byte pages (768 bytes) -----------------
    lda #TILE_EMPTY
    ldx #3
@im_pg:
    ldy #0
@im_inner:
    sta (ptr_lo),y
    iny
    bne @im_inner
    inc ptr_hi
    dex
    bne @im_pg

    ; --- Remaining 32 bytes (800 - 768 = 32) ---------------
    ldy #0
@im_rem:
    lda #TILE_EMPTY
    sta (ptr_lo),y
    iny
    cpy #(MAP_SIZE - 768)
    bne @im_rem

    ; --- River: row 10 (offset 400 = $190) -----------------
    lda #<(city_map + 10 * MAP_WIDTH)
    sta ptr_lo
    lda #>(city_map + 10 * MAP_WIDTH)
    sta ptr_hi
    lda #TILE_WATER
    ldy #0
@river:
    sta (ptr_lo),y
    iny
    cpy #MAP_WIDTH
    bne @river

    ; --- Trees: rows 0-2 (every 4th tile) ------------------
    lda #<city_map
    sta ptr_lo
    lda #>city_map
    sta ptr_hi
    ldy #0
@trees1:
    tya
    and #$03
    bne @t1_skip
    lda #TILE_TREE
    sta (ptr_lo),y
@t1_skip:
    iny
    cpy #(MAP_WIDTH * 3)
    bne @trees1

    ; --- Trees: row 19 (every other tile) ------------------
    lda #<(city_map + 19 * MAP_WIDTH)
    sta ptr_lo
    lda #>(city_map + 19 * MAP_WIDTH)
    sta ptr_hi
    ldy #0
@trees2:
    tya
    and #$01
    bne @t2_skip
    lda #TILE_TREE
    sta (ptr_lo),y
@t2_skip:
    iny
    cpy #MAP_WIDTH
    bne @trees2

    rts
