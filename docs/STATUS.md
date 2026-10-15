# Project Status

- **Current Milestone:** Milestone 2 (Combat Foundation & Boss Framework) - COMPLETED & VERIFIED
- **Engine Version:** Godot 4.7.2.stable.official.ed1daf0bf
- **Repository State:** Clean, modular, fully passing automated test suites (Milestone 1 & 2)

## What Works
- **Combat Defense & Parry (Milestone 2):**
  - Stance blocking (`block` action: `I`/`S`/`Down` on keyboard, `Left Shoulder` on gamepad, `BLK` on touch) reducing incoming damage by 70%.
  - Timed Parry window (0.15s / ~9 frames): negates 100% of incoming damage, causes golden spark & screen shake, staggers attackers, and triggers a devastating Counter Attack (3 dmg, 220 launch knockback, 6 frames hit-stop).
- **Data-Driven Boss Framework (Milestone 2):**
  - `BossData` custom resource holding identity, era, tier, quotes, colors, transition styles, phase thresholds, breakable armor, attacks, weaknesses, and rewards.
  - Phase-based `BossController` state machine managing telegraphs, vulnerability windows, breakable armor, staggers, and defeat callbacks.
- **Boss Title Card (Section 6a):**
  - Reusable GBA-style Pokémon battle intro: screen wipe transition, sliding versus splash (Hero vs Boss with speed lines), nameplate with era badge, typewriter quote, and instant skip on any key/tap.
- **Milestone 2 Bosses:**
  - **Primal Stalker (PRE-01, Tier 1 Basic Boss):** Pounce Strike with red telegraph, parryable Savage Frenzy flurry (staggers on parry), and retreat leaps.
  - **Titan of the Deep Earth (PRE-ERA, Tier 11 3-Phase Era Boss):**
    - Phase 1: Seismic stomps sending travelling floor shockwaves + heavy Earth Cleave punch.
    - Phase 2: Envelopes body in breakable Geo-Armor (8 HP); stalactite rain from ceiling; shattering armor causes 2.0s stagger.
    - Phase 3: Magma Cataclysm frenzy with speed boost, molten veins, and cascading shockwaves.
- **Boss Arena & Retry Pipeline:**
  - `scenes/levels/boss_arena.tscn` with dynamic boss spawning, camera constraints, boundary walls, boss health bar with armor overlays and phase pips, victory panel with reward displays, and instant retry through `ResetManager`.
- **Milestone 1 Core Systems (Intact & Regression Verified):**
  - 480x270 integer scaling viewport, nearest filtering, pixel transform/vertex snapping.
  - Dan-the-Man 3-hit combo, magic projectile, dodge i-frames, healing charges, Crested Prowler AI, Prehistoric Jungle level, HUD.

## Known Bugs & Limitations
- None. All 17 automated tests (9 Milestone 1 + 8 Milestone 2) pass with 0 errors.

## Next 3 Tasks (Milestone 3: Progression, Equipment & Save Systems)
1. Build progression and skill branch framework (Attack, Defense, Healing, Necromancy, Shadow, Elemental).
2. Build data-driven equipment architecture (weapons, armor, catalysts as `.tres` resources with stat and mobility modifiers).
3. Build comprehensive save/load and checkpoint persistence restoring inventory, unlocked skills, and era progression.
