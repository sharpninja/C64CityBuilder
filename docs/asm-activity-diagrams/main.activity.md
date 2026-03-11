# Assembly activity/state documentation

## Diagram
```mermaid
stateDiagram-v2
    state "game_start" as main_game_start
    state "game_loop" as main_game_loop
    state "@wait_jiffy" as main__wait_jiffy
    state "@no_sim" as main__no_sim
    state "@no_map_redraw" as main__no_map_redraw
    state "@no_ui_redraw" as main__no_ui_redraw

    [*] --> main_game_start
    main_game_start --> init_init_system : Call init_system
    main_game_start --> title_show_title : Call show_title
    main_game_start --> init_clear_screen : Call clear_screen
    main_game_start --> map_render_map : Call render_map
    main_game_start --> ui_draw_status_bar : Call draw_status_bar
    main_game_start --> init_enable_cursor_sprite : Call enable_cursor_sprite
    main_game_start --> main_game_loop : fallthrough
    main_game_loop --> main__wait_jiffy : fallthrough
    main__wait_jiffy --> main__wait_jiffy : Branch BEQ
    main__wait_jiffy --> input_read_input : Call read_input
    main__wait_jiffy --> main__no_sim : Branch BNE
    main__wait_jiffy --> simulation_run_simulation : Call run_simulation
    main__wait_jiffy --> main__no_sim : fallthrough
    main__no_sim --> main__no_map_redraw : Branch BEQ
    main__no_sim --> map_render_map : Call render_map
    main__no_sim --> main__no_map_redraw : fallthrough
    main__no_map_redraw --> map_update_cursor_display : Call update_cursor_display
    main__no_map_redraw --> main__no_ui_redraw : Branch BEQ
    main__no_map_redraw --> ui_draw_status_bar : Call draw_status_bar
    main__no_map_redraw --> main__no_ui_redraw : fallthrough
    main__no_ui_redraw --> main_game_loop : Jmp JMP
```

## Rendered Mermaid diagram
![Activity diagram](main.activity.svg)

## State and transition documentation

### State: game_start
- Mermaid state id: `main_game_start`
- Assembly body:
```asm
jsr init_system
jsr show_title
jsr clear_screen
jsr render_map
jsr draw_status_bar
jsr enable_cursor_sprite
```
- Mermaid state:
```mermaid
stateDiagram-v2
state "game_start" as main_game_start
```
- State transitions:
```mermaid
stateDiagram-v2
    state "game_start" as main_game_start
    main_game_start --> init_init_system : Call init_system
    main_game_start --> title_show_title : Call show_title
    main_game_start --> init_clear_screen : Call clear_screen
    main_game_start --> map_render_map : Call render_map
    main_game_start --> ui_draw_status_bar : Call draw_status_bar
    main_game_start --> init_enable_cursor_sprite : Call enable_cursor_sprite
    main_game_start --> main_game_loop : fallthrough
```

### State: game_loop
- Mermaid state id: `main_game_loop`
- Assembly body:
```asm
; (empty)
```
- Mermaid state:
```mermaid
stateDiagram-v2
state "game_loop" as main_game_loop
```
- State transitions:
```mermaid
stateDiagram-v2
    state "game_loop" as main_game_loop
    main_game_loop --> main__wait_jiffy : fallthrough
```

### State: @wait_jiffy
- Mermaid state id: `main__wait_jiffy`
- Assembly body:
```asm
lda JIFFY_LO
cmp last_jiffy
beq @wait_jiffy
sta last_jiffy
jsr read_input
dec sim_counter
bne @no_sim
jsr run_simulation
```
- Mermaid state:
```mermaid
stateDiagram-v2
state "@wait_jiffy" as main__wait_jiffy
```
- State transitions:
```mermaid
stateDiagram-v2
    state "@wait_jiffy" as main__wait_jiffy
    main__wait_jiffy --> main__wait_jiffy : Branch BEQ
    main__wait_jiffy --> input_read_input : Call read_input
    main__wait_jiffy --> main__no_sim : Branch BNE
    main__wait_jiffy --> simulation_run_simulation : Call run_simulation
    main__wait_jiffy --> main__no_sim : fallthrough
```

### State: @no_sim
- Mermaid state id: `main__no_sim`
- Assembly body:
```asm
lda dirty_map
beq @no_map_redraw
jsr render_map
```
- Mermaid state:
```mermaid
stateDiagram-v2
state "@no_sim" as main__no_sim
```
- State transitions:
```mermaid
stateDiagram-v2
    state "@no_sim" as main__no_sim
    main__no_sim --> main__no_map_redraw : Branch BEQ
    main__no_sim --> map_render_map : Call render_map
    main__no_sim --> main__no_map_redraw : fallthrough
```

### State: @no_map_redraw
- Mermaid state id: `main__no_map_redraw`
- Assembly body:
```asm
jsr update_cursor_display
lda dirty_ui
beq @no_ui_redraw
jsr draw_status_bar
```
- Mermaid state:
```mermaid
stateDiagram-v2
state "@no_map_redraw" as main__no_map_redraw
```
- State transitions:
```mermaid
stateDiagram-v2
    state "@no_map_redraw" as main__no_map_redraw
    main__no_map_redraw --> map_update_cursor_display : Call update_cursor_display
    main__no_map_redraw --> main__no_ui_redraw : Branch BEQ
    main__no_map_redraw --> ui_draw_status_bar : Call draw_status_bar
    main__no_map_redraw --> main__no_ui_redraw : fallthrough
```

### State: @no_ui_redraw
- Mermaid state id: `main__no_ui_redraw`
- Assembly body:
```asm
jmp game_loop
.include "init.s"
.include "title.s"
.include "input.s"
.include "map.s"
.include "buildings.s"
.include "simulation.s"
.include "ui.s"
.include "data.s"
```
- Mermaid state:
```mermaid
stateDiagram-v2
state "@no_ui_redraw" as main__no_ui_redraw
```
- State transitions:
```mermaid
stateDiagram-v2
    state "@no_ui_redraw" as main__no_ui_redraw
    main__no_ui_redraw --> main_game_loop : Jmp JMP
```

