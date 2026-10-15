# Development Log

## Session 4: Milestone 4 First Chapter (Prehistoric Era Complete)
- **Date:** 2026-10-15
- **Goal:** Build the complete Milestone 4 first chapter: one polished prehistoric level, several enemy types, miniboss encounter, 3-phase era boss encounter, story dialogue, rewards, and chapter clear flow ("Chapter playable start to finish").
- **Actions Taken:**
  - Expanded enemy roster with 2 new original prehistoric enemies:
    - `EnemyPterosaur` (`scenes/enemies/enemy_pterosaur.tscn` / `scripts/enemies/enemy_pterosaur.gd`): aerial flying predator with sinusoidal wing flap hovering, player detection, telegraphed acid sac illumination, and ranged `VenomSpitProjectile` attack.
    - `TarScuttler` (`scenes/enemies/enemy_scuttler.tscn` / `scripts/enemies/enemy_scuttler.gd`): heavy armored prehistoric carapace brute with frontal attack deflection (reduces light attacks to 1 damage), telegraphed `CarapaceSlam` ground lunge, and 1.5s parry stagger vulnerability exposing its soft glowing underbelly for double damage.
  - Implemented `VenomSpitProjectile` (`scenes/combat/venom_spit.tscn` / `scripts/combat/venom_spit.gd`): toxic green acid projectile dealing 1 damage to player with knockback and procedural splash particles.
  - Implemented `DialogueBox` (`scenes/ui/dialogue_box.tscn` / `scripts/ui/dialogue_box.gd`): retro pixel dialogue presentation with typewriter text, speaker nameplates (Hero, The Gemstone), modal game pausing, fast-forwarding, and input-driven advancement. Dialogue respects `docs/STORY.md` verbatim narrative constraints.
  - Implemented `ArenaGate` (`scenes/levels/arena_gate.tscn` / `scripts/levels/arena_gate.gd`): animated bone and stone barrier that dynamically locks arena boundaries and opens on boss defeat.
  - Built full Chapter 1 level `Chapter1Prehistoric` (`scenes/levels/chapter1_prehistoric.tscn` / `scripts/levels/chapter1_prehistoric.gd`) spanning 2650px across 6 distinct zones:
    - Zone 1: Canopy Outskirts (Prowler encounters, intro dialogue, Checkpoint 1 `cp_zone1_canopy`).
    - Zone 2: Tar Pits & Raptor Cliffs (Pterosaurs, Scuttler brute, spike pits, Checkpoint 2 `cp_zone2_tar_pits`).
    - Zone 3: Primal Clearing / Miniboss Arena (Locking gates, camera boundary locking, Miniboss **Primal Stalker PRE-01** battle, Hunter Fang reward, mid-chapter dialogue).
    - Zone 4: Obsidian Caverns (Cavern descent, mixed enemy encounters, Checkpoint 3 `cp_zone4_caverns`).
    - Zone 5: Chamber of the Deep Earth / Era Boss Arena (Locking gates, camera boundary locking, 3-Phase Era Boss **Titan of the Deep Earth PRE-ERA** battle, Prehistoric Remnant reward, post-battle dialogue).
    - Zone 6: Monolith Exit Gateway (Chapter victory panel, stats summary, +4 total Skill Points awarded and persisted to disk).
  - Authored automated integration test suite `tests/test_milestone4.tscn` verifying all 7 milestone systems (7/7 passing, 100%).
  - Ran full regression test suite across all 4 milestones (30/30 tests passing, 100%).

## Session 3: Milestone 3 Progression, Equipment & Save Systems
- **Date:** 2026-10-15
- **Goal:** Build the complete Milestone 3 progression system: 6 skill branches, data-driven equipment resources, weapon switching, checkpoints, full disk persistence, and progression overlay UI ("Save, quit, load restores everything").
- **Actions Taken:**
  - Designed and implemented `SkillData` resource with branch classification (Attack, Defense, Healing, Necromancy, Shadow, Elemental), prerequisites, point costs, and stat modifiers.
  - Created 6 data-driven skill resources in `data/skills/`: `atk_finisher_mastery`, `def_fortified_parry`, `heal_vital_regen`, `necro_soul_siphon`, `shadow_phase_dash`, and `elem_spark_infusion`.
  - Implemented `SkillTreeManager` handling skill point currency, prerequisite checks, unlock transactions, aggregated stat modifier calculations, and JSON serialization.
  - Designed and implemented `EquipmentItem` resource supporting weapons (melee, ranged, catalyst) and armor with base damage, defense modifiers, mobility multipliers, knockback bonuses, and accent colors.
  - Created 6 equipment resources in `data/equipment/`: `primordial_blade`, `heavy_obsidian_cleaver`, `hunter_bone_bow`, `shaman_focus_catalyst`, `stalker_leather_armor`, and `titan_carapace_armor`.
  - Integrated equipment and skill bonuses into `Player`, `PlayerAttackState`, `PlayerRunState`, `PlayerJumpState`, and `PlayerFallState`:
    - Weapon base damage and skill tree bonuses scale combo damage.
    - Armor defense multipliers scale incoming hurtbox damage.
    - Mobility multipliers scale run and aerial horizontal speeds.
  - Implemented real-time weapon switching via `switch_weapon` action (`Q`/`E` on keyboard, `Select`/`Back`/`D-Pad Down` on gamepad, `Q` on touch) with visual accent spark feedback.
  - Created `Checkpoint` beacon system (`scenes/levels/checkpoint.tscn` and `scripts/systems/checkpoint.gd`) restoring player vitals and triggering automatic saves.
  - Created `SaveManager` autoload singleton managing comprehensive serialization to `user://origin_savegame.json`, restoring loop count, unlocked skills, skill points, equipment slots, player vitals, and checkpoint coordinates.
  - Built `InventoryMenu` progression overlay UI (`scenes/ui/inventory_menu.tscn` and `scripts/ui/inventory_menu.gd`) displaying equipped gear cards, 6-branch skill tree cards with interactive learning buttons, aggregated combat stats, and manual save triggers.
  - Integrated inventory menu and touch buttons (`BAG`, `Q`) into `scenes/ui/hud.tscn` and `scripts/systems/hud.gd`.
  - Authored automated test suite `tests/test_milestone3.tscn` validating all 6 core requirements (6/6 tests passing, 100%).
  - Ran regression test suites: `tests/test_milestone2.tscn` (8/8 passing) and `tests/test_runner.tscn` (9/9 passing). Total: 23/23 tests passing with 0 failures.

## Session 2: Milestone 2 Combat Foundation & Boss Framework
- **Date:** 2026-10-15
- **Goal:** Build the complete Milestone 2 combat foundation, defense/parry, BossData resource, phase-based boss framework, GBA title card intros, and two playable bosses (Primal Stalker and Titan of the Deep Earth).
- **Actions Taken:**
  - Expanded `CombatTuning` and `data/combat_tuning.tres` with defense parameters: block damage reduction (70%), timed parry window (0.15s), counter damage (3), and counter knockback (220 px/s).
  - Implemented `PlayerBlockState` and updated `Player` with stance blocking, parry window timing, 100% damage negation on parry, golden flash, attacker stagger, and counter-strike transition.
  - Added `block` action to `ResetManager` input map, `docs/CONTROLS.md`, and added `BlockBtn` touch button to `scenes/ui/hud.tscn`.
  - Created `BossData` custom resource holding identity, tier, intro quotes, accent colors, transition styles, phase thresholds, breakable armor, attacks, weaknesses, and rewards.
  - Implemented `BossTitleCard` GBA-Pokémon style battle intro (Section 6a) with diagonal wipe transition, sliding versus splash (Hero vs Boss), typewriter quote, and instant skip on any input.
  - Created reusable `BossController` phase-based state machine with telegraphs, vulnerability windows, breakable armor, parry stagger handling, and phase transition signals.
  - Built Basic Boss: **Primal Stalker (PRE-01)** with pounce strikes, parryable savage frenzy, and retreat leap.
  - Built 3-Phase Era Boss: **Titan of the Deep Earth (PRE-ERA)** with Phase 1 seismic shockwaves & earth cleave, Phase 2 breakable Geo-Armor & stalactite rain, Phase 3 magma frenzy.
  - Built `SeismicShockwave` and `FallingStalactite` hazard systems.
  - Created `BossHealthBar` with dynamic binding, breakable armor overlay, and phase pips.
  - Created `BossArena` (`scenes/levels/boss_arena.tscn`) with dynamic boss spawning, camera constraints, boundary barriers, victory reward screen, and instant retry routing via `ResetManager`.
  - Authored automated integration test suite (`tests/test_milestone2.tscn`) verifying block, parry/counter, title card, both boss encounters, phase transitions, and retries with 8/8 tests passing (100%).
  - Re-verified Milestone 1 regression test suite (`tests/test_runner.tscn`) with 9/9 tests passing (100%).

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
