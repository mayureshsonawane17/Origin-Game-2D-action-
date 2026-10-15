# Project Status

- **Current Milestone:** Milestone 1 (Playable Foundation) - COMPLETED & VERIFIED
- **Engine Version:** Godot 4.7.2.stable.official.ed1daf0bf
- **Repository State:** Clean, modular, fully passing headless test suite

## What Works
- **Display & Pixel Rendering:** 480x270 viewport, integer scaling, nearest filter, pixel transform and vertex snapping.
- **Unified Input Mapping:** Standard actions (`move_left`, `move_right`, `jump`, `attack`, `magic`, `dodge`, `heal`, `pause`, `debug_hitbox`) across keyboard, gamepad, and touch controls.
- **Player Controller & Movement:** Run (110 px/s), variable-height jump (-300 px/s with 0.5 cut multiplier), snappy fall gravity (1.3x), coyote time (~6 frames), and jump input buffering (~6 frames).
- **Combat Feel (Dan-the-Man style):**
  - Tunable 3-hit combo (`data/combat_tuning.tres`) with startup, active, and recovery phases.
  - Third hit acts as a launch/knockback finisher (2 damage, 240 knockback, 5 frames hit-stop).
  - Hit-stop, white hit flash, directional knockback, and procedural pixel hit sparks.
  - Debug hitbox view toggled with F1 (`debug_hitbox`).
  - Dodge with invulnerability frames (0.2s i-frames, 0.25s duration, 0.6s cooldown).
  - Healing with limited charges (3 charges, restores 2 HP with green spiral pulse).
  - Magic projectile (costs 15 mana, 220 px/s, deals 2 damage, explodes on wall/enemy impact).
  - Animation structure with exact names (`idle`, `run`, `jump`, `fall`, `attack1`, `attack2`, `attack3`, `cast`, `dodge`, `hurt`, `die`).
- **Original Enemy Type (Crested Prowler):**
  - State machine: Patrol (ledge/wall turning), Detect (alert telegraph), Chase, Attack (telegraphed crouch & lunge bite), Hurt, and Die.
  - Attack token system (`AttackTokenManager`) for fair crowd combat.
  - Air juggle limit (prevents infinite combos).
- **Prehistoric Jungle Test Level:**
  - Layered parallax background (volcanic silhouettes, giant tree trunks and fern canopies).
  - Earthen mossy platforms, spike hazards, bottom kill-plane.
  - 5 enemy encounters across the level including a dual crowd encounter.
  - Ancient stone monolith level goal triggering clear screen.
- **HUD & Loop Persistence:**
  - Health pips, Mana bar, Heal charges, Dodge cooldown bar, and Loop counter.
  - Defeat screen routing through single `ResetManager` autoload singleton displaying "The loop begins again." and tracking loops.
  - Level complete screen with replay option.
  - On-screen touch buttons for mobile/touch targets.

## Known Bugs & Limitations
- None. All 9 automated integration tests pass with 0 errors.

## Next 3 Tasks (Milestone 2: Combat Foundation & Boss Framework)
1. Build combos expansion and defense mechanics (block, timed parry, counters).
2. Build `BossData` custom resource and phase-based boss state machine.
3. Build `BossTitleCard` GBA-intro scene (Section 6a) and test with one basic boss and one 3-phase era boss.
