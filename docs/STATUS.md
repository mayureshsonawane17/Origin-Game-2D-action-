# Project Status

- **Current Milestone:** Milestone 4 (First Chapter: Prehistoric Era) - COMPLETED & VERIFIED
- **Engine Version:** Godot 4.7.2.stable.official.ed1daf0bf
- **Repository State:** Clean, modular, fully passing automated test suites across Milestones 1, 2, 3, and 4 (30/30 tests passing)

## What Works
- **Milestone 4 (First Chapter: Prehistoric Era Complete):**
  - **New Prehistoric Enemies:**
    - **Venom Pterosaur (`EnemyPterosaur`):** Flying aerial predator with sinusoidal wing flap hover, player tracking, telegraphed acid sac glow, and `VenomSpitProjectile` ranged spit attack.
    - **Tar Scuttler (`TarScuttler`):** Heavy armored prehistoric carapace brute with frontal damage deflection (light attacks clank and deflect), telegraphed `CarapaceSlam` ground lunge, and 1.5s parry stagger vulnerability exposing its glowing underside for double damage.
  - **Cinematic Story Dialogue System (`DialogueBox`):**
    - Viewport-scaled (480x270) retro dialogue window with speaker nameplates (Hero, The Gemstone).
    - Smooth typewriter letter advancement with fast-forward on press, pause management, and automatic unpause upon completion.
    - Story beats conform strictly to `docs/STORY.md` source of truth.
  - **Arena Gates (`ArenaGate`):**
    - Dynamic thorn/bone/stone barriers that raise with solid collision to lock combat arenas and lower upon boss defeat.
  - **Complete Chapter 1 Level (`Chapter1Prehistoric` - `scenes/levels/chapter1_prehistoric.tscn`):**
    - Unified 2650px wide prehistoric wilderness spanning 6 distinct zones:
      - Zone 1: Canopy Outskirts (Prowler encounters, intro dialogue, Checkpoint 1 `cp_zone1_canopy`).
      - Zone 2: Tar Pits & Raptor Cliffs (Pterosaur flyers, Scuttler tank, spike hazard pits, Checkpoint 2 `cp_zone2_tar_pits`).
      - Zone 3: Primal Clearing / Miniboss Arena (Locking arena gates, camera boundary clamp, Miniboss **Primal Stalker PRE-01** battle, Hunter Fang reward, mid-chapter dialogue).
      - Zone 4: Obsidian Caverns (Cavern descent, mixed enemy encounters, Checkpoint 3 `cp_zone4_caverns`).
      - Zone 5: Chamber of the Deep Earth / Era Boss Arena (Locking gates, camera boundary clamp, 3-Phase Era Boss **Titan of the Deep Earth PRE-ERA** battle, Prehistoric Remnant reward, post-battle dialogue).
      - Zone 6: Monolith Exit Gateway (Chapter victory panel, stats summary, +4 total Skill Points awarded and persisted).
- **Milestone 3 (Progression, Equipment & Save Systems):**
  - 6 skill branches (`SkillData`, `SkillTreeManager`), data-driven equipment (`EquipmentItem`), real-time weapon switching (`switch_weapon`), checkpoints (`Checkpoint`), and full disk persistence (`SaveManager`).
  - Progression and loadout overlay menu (`InventoryMenu`).
- **Milestone 2 (Combat Foundation & Boss Framework):**
  - Stance blocking (70% damage reduction) and timed parry window (0.15s, 100% negation, golden flash, attacker stagger, 3-damage counter-attack).
  - Data-driven `BossData` custom resource and `BossController` phase machine.
  - GBA Pokémon-style `BossTitleCard` sliding versus splash with typewriter quote.
- **Milestone 1 (Stable Prototype Foundation):**
  - 480x270 viewport, integer scaling, pixel snapping.
  - Player controller (run, variable jump, coyote time, buffer, 3-hit combo with 240 knockback finisher, magic projectile, dodge i-frames, healing).
  - Crested Prowler AI, Prehistoric Jungle level, HUD, single `ResetManager` loop pipeline.

## Automated Test Coverage (30/30 Tests Passing - 100%)
- `tests/test_runner.tscn` (Milestone 1): 9/9 tests pass.
- `tests/test_milestone2.tscn` (Milestone 2): 8/8 tests pass.
- `tests/test_milestone3.tscn` (Milestone 3): 6/6 tests pass.
- `tests/test_milestone4.tscn` (Milestone 4): 7/7 tests pass.

## Next 3 Tasks (Milestone 5: Era 2 - Medieval Era)
1. Design and build Medieval Era level architecture (`scenes/levels/chapter2_medieval.tscn`) featuring castle ramparts, drawbridges, and torture dungeons.
2. Build Medieval enemy roster (e.g. Ironclad Footman with shields, Crossbow Guard, Gargoyle Lurker).
3. Build Medieval Era Boss (MED-ERA: Lord Malakor of the Iron Bastion) with 3-phase siege mechanics.
