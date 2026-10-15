# Development Log

## Session 1: Milestone 1 Foundation
- **Date:** 2026-10-15
- **Goal:** Build the complete Milestone 1 playable foundation from zero.
- **Actions Taken:**
  - Initialized git repository and verified Godot 4.7.2 CLI environment.
  - Setup core documentation (`docs/MASTER_PROMPT.md`, `docs/STORY.md`, `docs/DECISIONS.md`, `docs/CONTROLS.md`, `docs/ASSETS.md`, `docs/BOSS_ROSTER.md`, `docs/STATUS.md`, `docs/DEVELOPMENT_LOG.md`).
  - Configured `project.godot` with 480x270 viewport resolution, nearest texture filtering, 2D pixel snapping, and unified input map (keyboard, gamepad, touch).
  - Built `ResetManager` autoload singleton managing authoritative single reset pipeline, loop counts, and loop persistence (Section 7a).
  - Created `CombatTuning` (`data/combat_tuning.tres`) centralizing all movement parameters, combo frame data, hit-stop, dodge i-frames, and magic cooldowns.
  - Implemented modular `StateMachine` and `State` architecture.
  - Built `Player` entity with 11 standard animation states (`idle`, `run`, `jump`, `fall`, `attack1`, `attack2`, `attack3`, `cast`, `dodge`, `hurt`, `die`), variable jump height, coyote time, input buffering, camera shake, white hit flash, and procedural pixel hit sparks.
  - Implemented Dan-the-Man 3-hit melee combo with startup/active/recovery windows, forward step impulses, finisher launch knockback (240 px/s), and debug hitbox drawing (F1).
  - Implemented `MagicProjectile` with wall and enemy collision, damage, and mana cost.
  - Implemented `EnemyProwler` (Crested Prowler original prehistoric beast) with Patrol, Detect, Chase, telegraphed Lunge Attack, Hurt, Die, air juggle limits, and `AttackTokenManager` crowd coordination.
  - Created Prehistoric Jungle test level with layered parallax background, earthen rock/moss platforms, spike hazards, 5 enemy encounters, and monolith exit goal.
  - Built `GameHUD` with Health pips, Mana bar, Heal charges, Dodge cooldown, Loop counter, on-screen touch buttons, Defeat screen ("The loop begins again."), and Victory screen.
  - Authored automated integration test suite (`tests/test_runner.tscn`) validating 9 core milestone systems headless with 100% pass rate.
