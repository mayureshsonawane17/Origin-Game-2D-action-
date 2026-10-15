# Technical & Design Decisions

## 1. Engine & Environment
- **Godot Version:** 4.7.2.stable.official.ed1daf0bf
- **Language:** GDScript
- **Version Control:** Git

## 2. Display & Pixel Art Standards (Section 5b)
- **Base Resolution:** 480x270 (16:9 native aspect ratio)
- **Stretch Mode:** `viewport`
- **Stretch Aspect:** `keep`
- **Texture Filter:** `Nearest` (default_texture_filter = 0)
- **Snap 2D Transforms:** `snap_2d_transforms_to_pixel = true`
- **Snap 2D Vertices:** `snap_2d_vertices_to_pixel = true`
- **Grid Tile Size:** 16x16 pixels
- **Character Sizing:** roughly 32x48 pixels (placeholder shapes use this bounding box)

## 3. Architecture Decisions
- **Autoloads:**
  - `ResetManager`: The single authoritative pipeline for resets, retries, and defeat counting. Hooks into the reality-loop premise (Section 7a).
- **Data-Driven Combat:**
  - `CombatTuning` (`data/combat_tuning.tres`): Centralized tuning resource for player movement, frame data, damage, hit-stop, dodge i-frames, and magic cooldowns.
- **State Machine:**
  - Lightweight, modular node-based state machine pattern (`StateMachine`, `State`) shared by player and enemy entities.
- **Input System:**
  - Shared actions (`move_left`, `move_right`, `jump`, `attack`, `magic`, `dodge`, `heal`, `pause`) across keyboard, gamepad, and touch controls.

## 4. Narrative / Ending Architecture Integration
- In accordance with `docs/STORY.md` and Master Prompt Section 7a, defeat/retry flows route through `ResetManager`.
- Defeat presentation reflects the looping reality ("The loop begins again.").
