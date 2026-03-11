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

    ; Copy the lowercase/uppercase ROM charset into RAM, patch in our
    ; custom map icons, and point the VIC-II at the RAM charset.
    jsr init_custom_charset ; copy and patch the custom charset

    ; VIC-II colours
    lda #COLOR_BLACK ; load black into A for border color register
    sta VIC_BORDER_CLR ; store black into border color register
    lda #COLOR_GREEN ; load green into A for main background color register
    sta VIC_BKG_CLR0 ; store green into main background color register
    sta VIC_BKG_CLR1 ; store A into shared multicolor register 1
    lda #COLOR_DKGRAY ; load COLOR DKGRAY into A for shared multicolor register 2
    sta VIC_BKG_CLR2 ; store COLOR DKGRAY into shared multicolor register 2

    lda VIC_CTRL2 ; load VIC control register 2 into A
    ora #$10 ; set the bits from $10
    sta VIC_CTRL2 ; store A into VIC control register 2

    ; Clear screen + colour RAM
    jsr clear_screen ; clear the whole visible screen
    jsr init_cursor_sprite ; upload the cursor sprite data

    ; ---- Zero-page variables --------------------------------
    lda #INITIAL_MONEY_LO ; load INITIAL MONEY LO into A for cash low byte
    sta money_lo ; store INITIAL MONEY LO into cash low byte
    lda #INITIAL_MONEY_HI ; load INITIAL MONEY HI into A for cash high byte
    sta money_hi ; store INITIAL MONEY HI into cash high byte

    lda #INITIAL_YEAR_LO ; load INITIAL YEAR LO into A for year low byte
    sta year_lo ; store INITIAL YEAR LO into year low byte
    lda #INITIAL_YEAR_HI ; load INITIAL YEAR HI into A for year high byte
    sta year_hi ; store INITIAL YEAR HI into year high byte

    lda #INITIAL_HAPPINESS ; load INITIAL HAPPINESS into A for happiness
    sta happiness ; store INITIAL HAPPINESS into happiness
    lda #INITIAL_CRIME ; load INITIAL CRIME into A for crime
    sta crime ; store INITIAL CRIME into crime

    lda #0 ; load 0 into A for population counter
    sta population ; store 0 into population counter
    sta power_avail ; store A into available power total
    sta power_needed ; store A into power demand total
    sta jobs_total ; store A into jobs total
    sta employed_pop ; store A into worker supply total
    sta rev_lo ; store A into revenue low byte
    sta rev_hi ; store A into revenue high byte
    sta cost_lo ; store A into cost low byte
    sta cost_hi ; store A into cost high byte
    sta tick_count ; store A into tick count
    sta cnt_roads ; store A into roads
    sta cnt_houses ; store A into houses
    sta cnt_factories ; store A into factories
    sta cnt_parks ; store A into parks
    sta cnt_power ; store A into power
    sta cnt_police ; store A into police
    sta cnt_fire ; store A into fire
    sta key_last ; store A into last
    sta msg_timer ; store A into message timer
    sta blink_state ; store A into cursor blink state
    lda #COLOR_GREEN ; load green into A for playfield background color
    sta split_top_bg ; store green into playfield background color
    lda #0 ; load 0 into A for raster split phase
    sta raster_phase ; store 0 into raster split phase
    sta cursor_aoe_radius ; store A into cursor area radius
    sta cursor_aoe_active ; store A into cursor area flag
    lda #COLOR_GREEN ; load green into A for cursor highlight color
    sta cursor_aoe_color ; store green into cursor highlight color

    ; Cursor at map centre
    lda #MAP_WIDTH / 2 ; load MAP WIDTH / 2 into A for cursor column
    sta cursor_x ; store MAP WIDTH / 2 into cursor column
    lda #MAP_HEIGHT / 2 ; load MAP HEIGHT / 2 into A for cursor row
    sta cursor_y ; store MAP HEIGHT / 2 into cursor row

    ; Default selection: Road
    lda #TILE_ROAD ; load check for a road tile into A for selected building type
    sta sel_building ; store check for a road tile into selected building type

    lda #MODE_BUILD ; load build mode into A for current tool mode
    sta game_mode ; store build mode into current tool mode

    ; Force first-frame full redraw
    lda #1 ; prepare to mark the map as needing a redraw
    sta dirty_map ; mark the map as needing a redraw
    sta dirty_ui ; store A into UI redraw flag

    ; Timers
    lda #SIM_INTERVAL ; load simulation interval into A for simulation countdown
    sta sim_counter ; store simulation interval into simulation countdown
    lda #CURSOR_BLINK_RATE ; load cursor blink interval into A for cursor blink timer
    sta blink_timer ; store cursor blink interval into cursor blink timer

    ; Sync to jiffy clock
    lda JIFFY_LO ; load JIFFY LO into A
    sta last_jiffy ; store JIFFY LO into last jiffy snapshot

    jsr init_map ; initialize the starting city map
    jsr clear_road_segment_state ; reset cached road segment data
    jsr init_raster_split ; install the raster split IRQ

    cli ; re-enable IRQ handling
    rts ; Return from subroutine

; ------------------------------------------------------------
; init_custom_charset
; Copy the lowercase/uppercase ROM charset to RAM, patch the
; map icon glyphs, and switch the VIC-II to use the RAM copy.
; ------------------------------------------------------------
init_custom_charset:
    ; VIC bank 1 so SCREEN_BASE=$6800 and CHARSET_RAM=$7000 are visible
    ; well above the growing program/BSS region.
    lda CIA2_PRA ; load CIA2 port A / VIC bank register into A
    and #$FC ; mask A with $FC
    ora #$02 ; set the bits from $02
    sta CIA2_PRA ; store A into CIA2 port A / VIC bank register

    ; Expose character ROM at $D000-$DFFF while keeping BASIC/KERNAL on.
    lda CPU_PORT ; load 6510 memory configuration port into A
    pha ; save A on the stack
    and #$FB ; mask A with $FB
    sta CPU_PORT ; store A into 6510 memory configuration port

    lda #<CHARSET_ROM ; load CHARSET ROM into A for primary pointer low byte
    sta ptr_lo ; store CHARSET ROM into primary pointer low byte
    lda #>CHARSET_ROM ; load CHARSET ROM into A for primary pointer high byte
    sta ptr_hi ; store CHARSET ROM into primary pointer high byte
    lda #<CHARSET_RAM ; load CHARSET RAM into A for secondary pointer low byte
    sta ptr2_lo ; store CHARSET RAM into secondary pointer low byte
    lda #>CHARSET_RAM ; load CHARSET RAM into A for secondary pointer high byte
    sta ptr2_hi ; store CHARSET RAM into secondary pointer high byte
    lda #8 ; load 8 into A for temporary slot 4
    sta tmp4 ; store 8 into temporary slot 4
; Process the next page chunk.
; Branch target from @icc_byte if the test did not match.
@icc_page:
    ldy #0 ; load 0 into Y
; Process the next byte.
; Branch target from @icc_byte if the test did not match.
@icc_byte:
    lda (ptr_lo),y ; load primary pointer low byte into A
    sta (ptr2_lo),y ; store primary pointer low byte into secondary pointer low byte
    iny ; advance Y to the next offset
    bne @icc_byte ; if the test did not match, branch to byte
    inc ptr_hi ; advance the primary pointer to the next page
    inc ptr2_hi ; advance the secondary pointer to the next page
    dec tmp4 ; count one page chunk down
    bne @icc_page ; if the test did not match, branch to page

    pla ; restore the saved A value
    sta CPU_PORT ; store A into 6510 memory configuration port

    ; Overwrite contiguous screen codes with custom multicolor city + HUD glyphs.
    lda #<custom_char_glyphs ; load custom char glyphs into A for primary pointer low byte
    sta ptr_lo ; store custom char glyphs into primary pointer low byte
    lda #>custom_char_glyphs ; load custom char glyphs into A for primary pointer high byte
    sta ptr_hi ; store custom char glyphs into primary pointer high byte
    lda #<(CHARSET_RAM + MAP_GLYPH_EMPTY * 8) ; load (CHARSET RAM + MAP GLYPH EMPTY * 8 into A for secondary pointer low byte
    sta ptr2_lo ; store (CHARSET RAM + MAP GLYPH EMPTY * 8 into secondary pointer low byte
    lda #>(CHARSET_RAM + MAP_GLYPH_EMPTY * 8) ; load (CHARSET RAM + MAP GLYPH EMPTY * 8 into A for secondary pointer high byte
    sta ptr2_hi ; store (CHARSET RAM + MAP GLYPH EMPTY * 8 into secondary pointer high byte
    lda #2 ; load 2 into A for temporary slot 4
    sta tmp4 ; store 2 into temporary slot 4
; Continue with the custom glyph page path.
; Branch target from @icc_custom if the test did not match.
@icc_custom_page:
    ldy #0 ; load 0 into Y
; Continue with the custom glyph path.
; Branch target from @icc_custom if the test did not match.
@icc_custom:
    lda (ptr_lo),y ; load primary pointer low byte into A
    sta (ptr2_lo),y ; store primary pointer low byte into secondary pointer low byte
    iny ; advance Y to the next offset
    bne @icc_custom ; if the test did not match, branch to custom
    inc ptr_hi ; advance the primary pointer to the next page
    inc ptr2_hi ; advance the secondary pointer to the next page
    dec tmp4 ; count one page chunk down
    bne @icc_custom_page ; if the test did not match, branch to custom page

    ; Screen at $6800, charset at $7000 inside VIC bank 1.
    lda #$AC ; load $AC into A for video memory control register
    sta VIC_VMEM_CTRL ; store $AC into video memory control register
    rts ; Return from subroutine

; ------------------------------------------------------------
; init_cursor_sprite
; Copy the sprite pattern into RAM and configure sprite 0, but
; keep it hidden until gameplay starts.
; ------------------------------------------------------------
init_cursor_sprite:
    lda #<cursor_sprite_data ; load cursor sprite data into A for primary pointer low byte
    sta ptr_lo ; store cursor sprite data into primary pointer low byte
    lda #>cursor_sprite_data ; load cursor sprite data into A for primary pointer high byte
    sta ptr_hi ; store cursor sprite data into primary pointer high byte
    lda #<SPRITE0_DATA ; load SPRITE0 DATA into A for secondary pointer low byte
    sta ptr2_lo ; store SPRITE0 DATA into secondary pointer low byte
    lda #>SPRITE0_DATA ; load SPRITE0 DATA into A for secondary pointer high byte
    sta ptr2_hi ; store SPRITE0 DATA into secondary pointer high byte

    ldy #0 ; load 0 into Y
; Continue with the copy path.
; Branch target from @ics_copy if the test did not match.
@ics_copy:
    lda (ptr_lo),y ; load primary pointer low byte into A
    sta (ptr2_lo),y ; store primary pointer low byte into secondary pointer low byte
    iny ; advance Y to the next offset
    cpy #64 ; 64
    bne @ics_copy ; if the test did not match, branch to copy

    lda #SPRITE0_PTR ; load SPRITE0 PTR into A for SPRITE0 PTR LOC
    sta SPRITE0_PTR_LOC ; store SPRITE0 PTR into SPRITE0 PTR LOC

    lda VIC_SPR_X_MSB ; load sprite X high-bit register into A
    and #$FE ; mask A with $FE
    sta VIC_SPR_X_MSB ; store A into sprite X high-bit register

    lda VIC_SPR_EXP_X ; load sprite X expansion register into A
    and #$FE ; mask A with $FE
    sta VIC_SPR_EXP_X ; store A into sprite X expansion register

    lda VIC_SPR_EXP_Y ; load sprite Y expansion register into A
    and #$FE ; mask A with $FE
    sta VIC_SPR_EXP_Y ; store A into sprite Y expansion register

    lda VIC_SPR_MC ; load sprite multicolor register into A
    and #$FE ; mask A with $FE
    sta VIC_SPR_MC ; store A into sprite multicolor register

    lda VIC_SPR_BG_PRIO ; load sprite/background priority register into A
    and #$FE ; mask A with $FE
    sta VIC_SPR_BG_PRIO ; store A into sprite/background priority register

    lda #CURSOR_COLOR ; load CURSOR COLOR into A for sprite 0 color register
    sta VIC_SPR0_COLOR ; store CURSOR COLOR into sprite 0 color register

    jsr disable_cursor_sprite ; hide the cursor sprite
    rts ; Return from subroutine

; ------------------------------------------------------------
; enable_cursor_sprite / disable_cursor_sprite
; ------------------------------------------------------------
enable_cursor_sprite:
    jsr update_cursor_display ; refresh cursor visibility and blink state
    lda VIC_SPRITE_EN ; load sprite enable register into A
    ora #$01 ; set the bits from $01
    sta VIC_SPRITE_EN ; store A into sprite enable register
    rts ; Return from subroutine

; Hide the cursor sprite without disturbing its saved state.
disable_cursor_sprite:
    lda VIC_SPRITE_EN ; load sprite enable register into A
    and #$FE ; mask A with $FE
    sta VIC_SPRITE_EN ; store A into sprite enable register
    rts ; Return from subroutine

; ------------------------------------------------------------
; init_raster_split
; Install a raster IRQ that restores the playfield background
; at the top of the frame, then switches the lower 5 rows to
; black for the UI/status panel.
; ------------------------------------------------------------
init_raster_split:
    lda #<raster_irq ; load raster irq into A for IRQ vector low byte
    sta IRQ_VECTOR_LO ; store raster irq into IRQ vector low byte
    lda #>raster_irq ; load raster irq into A for IRQ vector high byte
    sta IRQ_VECTOR_HI ; store raster irq into IRQ vector high byte

    lda #0 ; load 0 into A for raster split phase
    sta raster_phase ; store 0 into raster split phase

    lda VIC_CTRL1 ; load VIC control register 1 into A
    and #$7F ; mask A with $7F
    sta VIC_CTRL1 ; store A into VIC control register 1

    lda #RASTER_SPLIT_TOP ; load RASTER SPLIT TOP into A for raster compare register
    sta VIC_RASTER ; store RASTER SPLIT TOP into raster compare register

    lda #$01 ; load $01 into A for VIC IRQ status register
    sta VIC_IRQ_STATUS ; store $01 into VIC IRQ status register

    lda VIC_IRQ_CTRL ; load VIC IRQ enable register into A
    ora #$01 ; set the bits from $01
    sta VIC_IRQ_CTRL ; store A into VIC IRQ enable register
    rts ; Return from subroutine

; ------------------------------------------------------------
; raster_irq
; Two-phase raster IRQ. This handler is reached through the
; KERNAL RAM IRQ vector, so A/X/Y are already saved on the
; stack before we enter. The top-of-frame IRQ restores the
; active background colour, and the lower IRQ switches the
; status area background to black.
; ------------------------------------------------------------
raster_irq:
    lda VIC_IRQ_STATUS ; load VIC IRQ status register into A
    and #$01 ; mask A with $01
    beq @chain_kernal ; if the test matched, branch to chain kernal

    lda raster_phase ; load raster split phase into A
    beq @top_phase ; if the test matched, branch to phase

; Continue with the lower phase path.
@lower_phase:
    lda #COLOR_BLACK ; load black into A for main background color register
    sta VIC_BKG_CLR0 ; store black into main background color register
    lda VIC_CTRL2 ; load VIC control register 2 into A
    and #$EF ; mask A with $EF
    sta VIC_CTRL2 ; store A into VIC control register 2
    lda #0 ; load 0 into A for raster split phase
    sta raster_phase ; store 0 into raster split phase
    lda #RASTER_SPLIT_TOP ; load RASTER SPLIT TOP into A for raster compare register
    sta VIC_RASTER ; store RASTER SPLIT TOP into raster compare register
    lda VIC_CTRL1 ; load VIC control register 1 into A
    and #$7F ; mask A with $7F
    sta VIC_CTRL1 ; store A into VIC control register 1
    lda #$01 ; load $01 into A for VIC IRQ status register
    sta VIC_IRQ_STATUS ; store $01 into VIC IRQ status register
    jmp @irq_done ; continue at done

; Continue with the phase path.
; Branch target from raster_irq if the test matched.
@top_phase:
    lda split_top_bg ; load playfield background color into A
    sta VIC_BKG_CLR0 ; store playfield background color into main background color register
    lda VIC_CTRL2 ; load VIC control register 2 into A
    ora #$10 ; set the bits from $10
    sta VIC_CTRL2 ; store A into VIC control register 2
    lda #1 ; load 1 into A for raster split phase
    sta raster_phase ; store 1 into raster split phase
    lda #RASTER_SPLIT_LOWER ; load RASTER SPLIT LOWER into A for raster compare register
    sta VIC_RASTER ; store RASTER SPLIT LOWER into raster compare register
    lda VIC_CTRL1 ; load VIC control register 1 into A
    and #$7F ; mask A with $7F
    sta VIC_CTRL1 ; store A into VIC control register 1
    lda #$01 ; load $01 into A for VIC IRQ status register
    sta VIC_IRQ_STATUS ; store $01 into VIC IRQ status register

; Finish this local path and fall back to the caller or shared exit.
@irq_done:
    pla ; restore the saved A value
    tay ; move A into Y for the upcoming indexed access
    pla ; restore the saved A value
    tax ; move A into X for the upcoming table lookup
    pla ; restore the saved A value
    rti ; Return from interrupt

; Continue with the chain kernal path.
; Branch target from raster_irq if the test matched.
@chain_kernal:
    jmp KERNAL_IRQ ; continue at KERNAL IRQ

; ------------------------------------------------------------
; clear_screen
; Fill screen RAM ($0400) with spaces and colour RAM ($D800)
; with COLOR_GREEN.  800 bytes (map area) get green; all 1000
; bytes are written so the UI area starts clean.
; ------------------------------------------------------------
clear_screen:
    lda #<SCREEN_BASE ; load screen RAM base into A for primary pointer low byte
    sta ptr_lo ; store screen RAM base into primary pointer low byte
    lda #>SCREEN_BASE ; load screen RAM base into A for primary pointer high byte
    sta ptr_hi ; store screen RAM base into primary pointer high byte
    lda #<COLOR_BASE ; load color RAM base into A for secondary pointer low byte
    sta ptr2_lo ; store color RAM base into secondary pointer low byte
    lda #>COLOR_BASE ; load color RAM base into A for secondary pointer high byte
    sta ptr2_hi ; store color RAM base into secondary pointer high byte

    ; Write 3 full pages (768 bytes)
    ldx #3 ; load 3 into X
; Repeat the current loop.
; Branch target from @byte_loop if the test did not match.
@pg_loop:
    ldy #0 ; load 0 into Y
; Process the next loop.
; Branch target from @byte_loop if the test did not match.
@byte_loop:
    lda #32                 ; space
    sta (ptr_lo),y ; store 32 into primary pointer low byte
    lda #COLOR_GREEN ; load green into A for secondary pointer low byte
    sta (ptr2_lo),y ; store green into secondary pointer low byte
    iny ; advance Y to the next offset
    bne @byte_loop ; if the test did not match, branch to byte loop
    inc ptr_hi ; advance the primary pointer to the next page
    inc ptr2_hi ; advance the secondary pointer to the next page
    dex ; step X back one slot
    bne @pg_loop ; if the test did not match, branch to loop

    ; Write remaining 232 bytes (768+232=1000)
    ldy #0 ; load 0 into Y
; Repeat the current loop.
; Branch target from @rem_loop if the test did not match.
@rem_loop:
    lda #32 ; load 32 into A for primary pointer low byte
    sta (ptr_lo),y ; store 32 into primary pointer low byte
    lda #COLOR_GREEN ; load green into A for secondary pointer low byte
    sta (ptr2_lo),y ; store green into secondary pointer low byte
    iny ; advance Y to the next offset
    cpy #(SCREEN_SIZE - 768) ; (SCREEN SIZE - 768
    bne @rem_loop ; if the test did not match, branch to loop
    rts ; Return from subroutine

; ------------------------------------------------------------
; init_map
; Fill the 800-byte city_map with TILE_EMPTY, then add a
; river across row 10 and leave the remaining land empty.
; ------------------------------------------------------------
init_map:
    lda #<city_map ; load city map buffer into A for primary pointer low byte
    sta ptr_lo ; store city map buffer into primary pointer low byte
    lda #>city_map ; load city map buffer into A for primary pointer high byte
    sta ptr_hi ; store city map buffer into primary pointer high byte

    ; --- 3 full 256-byte pages (768 bytes) -----------------
    lda #TILE_EMPTY ; load check for empty land into A
    ldx #3 ; load 3 into X
; Process the next chunk.
; Branch target from @im_inner if the test did not match.
@im_pg:
    ldy #0 ; load 0 into Y for primary pointer low byte
; Continue with the inner path.
; Branch target from @im_inner if the test did not match.
@im_inner:
    sta (ptr_lo),y ; store 0 into primary pointer low byte
    iny ; advance Y to the next offset
    bne @im_inner ; if the test did not match, branch to inner
    inc ptr_hi ; advance the primary pointer to the next page
    dex ; step X back one slot
    bne @im_pg ; if the test did not match, branch to pg

    ; --- Remaining 32 bytes (800 - 768 = 32) ---------------
    ldy #0 ; load 0 into Y
; Continue with the remainder bytes path.
; Branch target from @im_rem if the test did not match.
@im_rem:
    lda #TILE_EMPTY ; load check for empty land into A for primary pointer low byte
    sta (ptr_lo),y ; store check for empty land into primary pointer low byte
    iny ; advance Y to the next offset
    cpy #(MAP_SIZE - 768) ; (MAP SIZE - 768
    bne @im_rem ; if the test did not match, branch to rem

    ; --- River: row 10 (offset 400 = $190) -----------------
    lda #<(city_map + 10 * MAP_WIDTH) ; load (city map + 10 * MAP WIDTH into A for primary pointer low byte
    sta ptr_lo ; store (city map + 10 * MAP WIDTH into primary pointer low byte
    lda #>(city_map + 10 * MAP_WIDTH) ; load (city map + 10 * MAP WIDTH into A for primary pointer high byte
    sta ptr_hi ; store (city map + 10 * MAP WIDTH into primary pointer high byte
    lda #TILE_WATER ; load check for water into A
    ldy #0 ; load 0 into Y for primary pointer low byte
; Continue with the river row path.
; Branch target from @river if the test did not match.
@river:
    sta (ptr_lo),y ; store 0 into primary pointer low byte
    iny ; advance Y to the next offset
    cpy #MAP_WIDTH ; check for the end of the row
    bne @river ; if the test did not match, branch to river

    rts ; Return from subroutine
