# Project Status

- **Current Milestone:** Milestone 3 (Progression, Equipment & Save Systems) - COMPLETED & VERIFIED
- **Engine Version:** Godot 4.7.2.stable.official.ed1daf0bf
- **Repository State:** Clean, modular, fully passing automated test suites across Milestones 1, 2, and 3 (23/23 tests passing)

## What Works
- **Milestone 3 (Progression, Equipment & Save Systems):**
  - **Skill Tree Architecture (`SkillData`, `SkillTreeManager`):**
    - 6 skill branches implemented: Attack, Defense, Healing, Necromancy, Shadow, Elemental.
    - Modular `.tres` data definitions with prerequisites, point costs, and stat modifiers.
    - Initial skills: `atk_finisher_mastery`, `def_fortified_parry`, `heal_vital_regen`, `necro_soul_siphon`, `shadow_phase_dash`, `elem_spark_infusion`.
    - Dynamic point spending, prerequisite enforcement, and aggregated stat modifier calculation.
  - **Data-Driven Equipment System (`EquipmentItem`):**
    - Weapons, armor, and catalysts defined as custom `.tres` resources.
    - Initial equipment: `primordial_blade` (melee), `heavy_obsidian_cleaver` (heavy melee), `hunter_bone_bow` (ranged), `shaman_focus_catalyst` (catalyst), `stalker_leather_armor` (light armor), `titan_carapace_armor` (heavy defense armor).
    - Dynamic stat scaling: base damage scaling into combo finishers, armor defense multipliers reducing damage taken, mobility multipliers modifying horizontal move speed across ground and air.
  - **Real-Time Weapon Switching:**
    - Dual weapon loadout (Primary & Secondary slots).
    - Quick swap via `switch_weapon` input (`Q`/`E` on keyboard, `Select`/`Back`/`D-Pad Down` on gamepad, `Q` on touch screen).
    - Seamless weapon change with elemental/accent particle burst.
  - **Checkpoint & Persistence System (`Checkpoint`, `SaveManager`):**
    - Animated ancient stone pillar checkpoint restoring player health and heal charges upon entry.
    - Disk persistence to `user://origin_savegame.json`.
    - Restores entire world and character state: reset loop count, unlocked skill IDs, available skill points, equipped weapon IDs, active weapon slot, equipped armor, player vitals (health, mana, charges), and exact checkpoint world coordinates.
    - "Save, quit, load restores everything" verified 100%.
  - **Progression & Inventory UI (`InventoryMenu`):**
    - Viewport-scaled modal overlay (480x270).
    - Toggled via `toggle_inventory` (`Tab`/`U` on keyboard, `Touchpad`/`Guide` on gamepad, `BAG` touch button).
    - Pauses game tree while open.
    - Displays active gear cards with dynamic stats, 6-branch skill tree with interactive learn buttons, and manual save trigger.
- **Milestone 2 Systems (Intact & Regression Verified):**
  - Stance blocking (70% damage reduction) and timed parry window (0.15s, 100% negation, golden flash, attacker stagger, 3-damage counter-attack).
  - Data-driven `BossData` custom resource and `BossController` phase machine.
  - GBA Pokémon-style `BossTitleCard` sliding versus splash with typewriter quote.
  - Basic Boss: `BossPrimalStalker` (PRE-01) and 3-Phase Era Boss: `BossTitanDeepEarth` (PRE-ERA).
  - `BossArena` with health bar, armor overlays, and instant loop retry.
- **Milestone 1 Systems (Intact & Regression Verified):**
  - 480x270 viewport, integer scaling, pixel snapping.
  - Player controller (run, variable jump, coyote time, buffer, 3-hit combo with 240 knockback finisher, magic projectile, dodge i-frames, healing).
  - Crested Prowler AI, Prehistoric Jungle level, HUD, single `ResetManager` loop pipeline.

## Automated Test Coverage (23/23 Tests Passing - 100%)
- `tests/test_runner.tscn` (Milestone 1): 9/9 tests pass.
- `tests/test_milestone2.tscn` (Milestone 2): 8/8 tests pass.
- `tests/test_milestone3.tscn` (Milestone 3): 6/6 tests pass.

## Next 3 Tasks (Milestone 4: Era Progression & Monolith Transitions)
1. Build Era Monolith / Warp Gate system routing player transitions between distinct historical eras.
2. Build Medieval Era level (`scenes/levels/medieval_castle.tscn`) with distinct architecture, hazards, and enemy roster.
3. Implement Era transition narrative sequences linking the gemstone prison lore across eras.
