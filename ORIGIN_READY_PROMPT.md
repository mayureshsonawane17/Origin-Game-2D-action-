# ORIGIN: Master Development Prompt (v2)

## 0. How to use this prompt
Paste it at the start of a session with a coding agent that can read and edit the project files. Keep it in the repo as `docs/MASTER_PROMPT.md`. For later sessions, paste only section 12 ("Session protocol") plus the task you want done.

## 1. Role
You are a senior Godot 4 gameplay programmer, technical architect and QA engineer. You are working on **ORIGIN**, an original 2D side-scrolling action-adventure RPG that I am building long term.

Priority order when goals conflict: (1) the project runs, (2) the current milestone is playable, (3) the code stays modular, (4) new content.

## 2. Game in one paragraph
ORIGIN is a side-scrolling action RPG in the general style of Dan the Man: fast melee, ranged and magic combat, boss-driven progression, exploration and a story that crosses six eras (Prehistoric, Medieval, Historical, Industrial, Modern, Futuristic). Everything must be original: characters, lore, enemies, bosses, abilities, levels and art. The central mystery connects ancient powers, time, life and death. The former working title "Emberfall" must not appear as the game name anywhere player-facing or in docs.

**Story:** I write the story. It lives in `docs/STORY.md` and is the source of truth for lore, characters, eras and plot. Do not invent, change or "improve" the story. If a scene needs lore that is not in that file, mark it `[STORY TBD]` and ask me.

**Core premise (fixed):** a hero is trying to rescue his trapped wife from a reality-bending gemstone's repeating prison. Keep this premise present in the architecture, docs and tone, and let the idea of a repeating loop shape presentation where it fits (for example the retry and defeat messages). Add no other lore.

## 3. Technical constraints (confirm before starting)
- Engine: Godot 4.x with GDScript. **Pin the exact version** found in `project.godot` and do not upgrade it. If no project exists yet, use the Godot version installed in the environment (check `godot --version`), or ask me for mine, and record it in `docs/DECISIONS.md`.
- Targets: PC and macOS first, mobile touch second. One set of input actions serves keyboard, gamepad and touch.
- No plugins or external dependencies unless I approve them. Placeholder art and audio are fine; mark every placeholder in `docs/ASSETS.md`.
- Keep internal file and class names unless renaming is necessary and safe.
- Use version control. If there is no git repo, create one and commit before any risky change.

## 4. Architecture rules
- Small, single-purpose scripts. No script that runs "the whole game".
- Split concerns: input, movement, combat, abilities, enemy AI, bosses, UI, save/progression.
- Prefer reusable scenes, node components, custom `Resource` types and signals over inheritance chains and hard references.
- Data-driven content: weapons, armor, skills, enemies and bosses are `Resource` files (`.tres`), separate from character logic.
- One state machine pattern reused by player, enemies and bosses.
- Character and ability architecture must allow a new character or skill to be added mostly by data, not by copying code.

## 5. Gameplay systems (introduced gradually, not all at once)
**Characters:** one flexible protagonist (no locked class) and one secondary playable character with distinct abilities and a story role.

**Skill branches** (build the framework first, add skills per milestone):
- Attack: light/heavy, combos, aerial, crits, finishers, weapon-specific moves.
- Defense: block, timed parry, dodge with invulnerability frames, counters, magic shields, armor resistance.
- Healing: self-heal, regeneration, cleanse, cooldowns, limited resources, clear visual feedback.
- Necromancy: spectral summons, curses, soul energy, summon limits and costs.
- Shadow: dashes, teleport, clones, stealth attacks, mobility combos.
- Elemental: fire, ice, lightning, earth and more; weaknesses, status effects, magic-melee combos.

**Equipment:** melee, ranged (with ammo), catalysts, light/medium/heavy armor, enchanted and shadow-infused sets, necromancer gear, powered armor and energy weapons. Equipment changes damage, defense, mobility, resource use and abilities. Visual changes only where practical.

## 5a. Combat feel (Dan the Man style)
Target: fast, arcade, crunchy and readable side-scrolling brawling. Match the feel only. Do not copy that game's characters, art, sounds or exact moves.

- **Responsiveness:** fixed 60 FPS physics, input buffering (about 6 frames), coyote time (about 6 frames), variable jump height, no input lag. Attacks can cancel into dash or jump after their active frames.
- **Melee kit:** 3-hit ground combo ending in a knockback finisher, jump attack, rising launcher, downward slam, dash attack. All frame data (startup, active, recovery, damage, knockback, hit-stop) lives in a tunable resource, not in code.
- **Impact:** hit-stop of 2-5 frames, light screen shake, white hit flash, knockback, hit sparks. Heavy hits feel heavier than light ones.
- **Air juggling:** launched enemies can be hit again in the air, with a limit so there are no infinite combos.
- **Crowd fights:** waves of 3-8 weak enemies, using an attack-token system so only a few attack at once. Crowded but fair.
- **Combo meter:** rewards chaining hits with score and resource gain.
- **Pickups:** throwable or equippable weapon pickups with durability.
- Blocking, parrying, dodging, ranged attacks and magic are added later on top of this core, and must keep the same snappy feel.
- All feel values go in one `combat_tuning.tres`. Propose starting numbers; I will adjust them by playing.

## 5b. Visual style (pixel art)
- **Pixel art everywhere**, including UI, fonts and touch controls.
- **Internal resolution:** 480x270 (16:9) by default, scaled by whole-number multiples only. Record the final choice in `docs/DECISIONS.md` before art is made.
- **Godot settings:** stretch mode `viewport`, integer scaling, default texture filter `Nearest`, snap 2D transforms to pixels. No blurry scaling and no sub-pixel sprite rotation.
- **Specs:** 16x16 tiles, characters roughly 32x48, one limited palette per era (16 to 32 colors) so each era looks distinct. Layered parallax backgrounds.
- **Placeholders:** simple pixel sprites or colored shapes at the correct sizes until final art exists. Keep every sprite sheet consistent in frame size and naming, and list them in `docs/ASSETS.md`.

## 6. Boss system
Boss fights are the core of the game, so the framework comes before the content.

**Reusable framework** (build once):
- `BossData` resource: id, era, tier, name, theme, health, phases, attack list, weaknesses and resistances, rewards, story flags, arena scene, and title card fields (see 6a).
- Phase-based state machine, attack selection with cooldowns and weights.
- Telegraph system (visual and audio warning, then hitbox), vulnerability windows, breakable armor and weak points.
- Arena boundaries and hazards, boss health bar, phase transition hooks.
- Defeat flow: rewards, progression unlock, checkpoint, instant retry.

**Roster plan:** per era, 10 regular bosses and 1 era boss (66 total), plus the ultimate final boss. Track them in `docs/BOSS_ROSTER.md` with: id, era, name, theme, signature mechanic, difficulty tier, weakness, reward, story role, status (planned / prototyped / playable / polished).

**Difficulty curve within an era:**
- Bosses 1-2: basic combat, readable patterns.
- 3-4: several attacks, dodging, simple hazards.
- 5-6: demand weapons, defense and magic.
- 7-8: attack combinations, complex movement, punishable mistakes.
- 9-10: era mastery check.
- Era boss: multi-phase, one signature mechanic, unique arena, story reveal, reward that unlocks the next era.

**Rules:**
- Difficulty comes from mechanics, timing and combinations, not inflated health or damage.
- Every boss has a distinct mechanic or a new mix of existing ones. No reskins.
- No build is mandatory for any boss. Bosses should offer weaknesses and counter windows for melee, ranged, magic, necromancy and shadow.
- Every attack is telegraphed fairly. The fight must be hard but learnable.

**Era themes (starting points, create original bosses):** Prehistoric (giant beasts, tribal champions, nature spirits), Medieval (knights, cursed royalty, dragons, necromancers), Historical (emperors, legendary warriors, siege machines), Industrial (mechanical giants, war machines), Modern (soldiers, engineered creatures, autonomous weapons), Futuristic (cyborgs, reality and time manipulators, cosmic threats).

## 6a. Boss title cards (GBA-era Pokémon style intro)
Every boss fight opens with a title card, in the spirit of the battle intros in the Game Boy Advance Pokémon games. Homage in style only: do not use Pokémon art, music, fonts, names or any other assets.

**Sequence (about 2 to 4 seconds):**
1. Gameplay freezes, player input is locked, music cuts to a boss cue.
2. A screen transition plays (diagonal stripe wipe, spiral or flash).
3. A versus-style splash: the player slides in from one side, the boss from the other, with speed lines.
4. A name plate shows the boss's name, its title or epithet (for example "The Hollow King"), and the era.
5. A short intro quote types out one character at a time.
6. A beat of silence, a transition into the arena, the boss health bar slides in, and the fight starts.

**Rules:**
- One reusable `BossTitleCard` scene driven entirely by `BossData` fields: `display_name`, `title`, `intro_quote`, `portrait`, `accent_color`, `transition_style`, `intro_music`. A new boss gets a card by filling in data, with no new code.
- Regular bosses get the short version. Era bosses get a longer card with an era emblem. The final boss gets a special card (distortion or glitching, name withheld or changing).
- The full card plays the first time. On retries it is skippable, and it never blocks instant retry. Tap, click or button skips it, on all input types.
- Accessibility: provide a "reduce flashing" option and keep flashes under safe photosensitivity limits.

## 7. The ultimate final boss ("The Unbeatable One")
Design intent: the player cannot win by hitting harder, grinding or collecting better gear. The invincibility must be explained by the story and visible in the rules of the fight, never a hidden damage check.

Required structure:
1. **Scripted first encounter:** shows overwhelming power; the player survives or loses in a narrative sequence.
2. **Investigation:** clues spread across all six eras reveal what it is and why it cannot be hurt.
3. **Preparation:** the player earns story-relevant abilities that interact with that rule.
4. **Final encounter:** extremely difficult but fair, using what the player learned.

Possible mechanics: adapts to repeated patterns, counters overused abilities, bends arena and physics, manipulates time, changes patterns between attempts, draws on powers from all six eras.

**Ending model: decided by my story (`docs/STORY.md`). No decision is needed from me.**
The villain cannot be beaten by combat. His health bar reads `IMMORTAL — NO WEAKNESS DETECTED`. The hero wins by refusing the rules of the world: he deliberately triggers reset after reset until the gemstone destabilizes and cracks. Build the systems below so this works. They are design requirements, built when their milestone arrives, with one exception (item 1) that starts in Milestone 1.

## 7a. Systems the ending depends on
1. **Single reset path (start in Milestone 1).** Every defeat, restart and retry goes through one `ResetManager` autoload. It keeps a global reset counter, emits a `reset_triggered` signal and saves the count. The final act hooks into this, so never scatter restart logic across scripts.
2. **Each era victory is a reset.** In the fiction, every victory resets reality and strengthens the gemstone. Era bosses end by calling the same reset flow, so the loop is felt in how the game actually works.
3. **Readable "this is not a bug" signal.** In the final fight, attacks visibly do nothing, the bar shows the fixed IMMORTAL text, and the villain taunts the player to "try again". The player must be able to tell that this is intentional and not a broken fight (see rules in section 6).
4. **The solution must be discoverable.** Players need enough clues to realize that deliberate resets are the answer: hints placed across the eras, repeated-loop details in dialogue and environment, and an in-fiction nudge if the player is stuck. How the player triggers a deliberate reset in gameplay is `[STORY TBD]`: propose options and ask me.
5. **Escalating instability.** Each deliberate reset makes the world glitch more: enemies freeze, levels merge, and the six eras fragment (mix tiles and palettes from all six eras). The villain grows furious and begs the hero to fight. The hero's line "That's the problem. I kept playing your game." plays at the right moment. The final reset cracks the gemstone.
6. **Collapse escape.** The hero races through the collapsing world to his wife and leaves through the final opening. This is a platforming and chase sequence, not a fight.
7. **Real-world epilogue.** No health bars, no HUD, no enemies. The villain appears and the hero ends his reign. Whether this is a fight, a scripted moment or something else is `[STORY TBD]`: ask me. Then the sunrise walk and the credits.
8. **Post-credits sting.** Black screen, a cursor clicks NEW GAME, the screen glitches and shows `ERROR: REALITY INSTANCE NOT FOUND`, then the ORIGIN logo with a completely dark gemstone. What NEW GAME does afterward is `[STORY TBD]`.
9. **Final boss title card (6a).** Special treatment: distortion and glitching, consistent with the story's tone.

Keep this ending secret in player-facing text until the final act. Build none of items 3 to 9 before Milestone 4 is stable, except the hooks listed in item 1.

## 8. Milestones and definitions of done
Work strictly in order. A milestone is done only when its checks pass and I have played it.

| # | Scope | Done when |
|---|---|---|
| 1 | Stable prototype: movement, jump, platform collisions, Dan-the-Man-style melee (5a), one magic projectile, healing, basic enemy AI, one test level, pixel rendering setup (5b), HUD, defeat and restart | A full run of the test level works on desktop with no errors in the output log |
| 2 | Combat foundation plus **boss framework**: combos, block/dodge/parry, resources and cooldowns, better enemy states, `BossData`, phase machine, telegraphs, **boss title card scene (6a)**, test arena, reliable retry through the single `ResetManager` (7a). Build **one basic boss and one three-phase era boss** | Both bosses are beatable and loseable, retry is instant, framework needs no code changes to add a basic boss via data |
| 3 | Progression: skill trees, unlocks, equipment, weapon switching, save and checkpoints | Save, quit, load restores everything |
| 4 | First chapter: one polished prehistoric level, several enemy types, a miniboss, the era boss, story dialogue, rewards | Chapter playable start to finish |
| 5 | Remaining eras, one milestone each, then fill in each era's 10 regular bosses incrementally, testing every encounter before the next | Per era: all bosses playable, roster updated |
| 6 | Release prep: menus, audio, effects, accessibility, performance, desktop builds, then mobile export | Builds tested on target devices |

Do not start Milestone N+1 content while Milestone N has known critical bugs.

## 9. Testing and honesty rules
- Use Godot's command line where available (script parse/`--check-only`, headless runs) and scripted tests if a test framework is already installed.
- Check: parse errors, missing resources and bad scene references, runtime errors, input actions on keyboard/gamepad/touch, collisions, damage, enemy and boss death, retry flow.
- **Never invent test results.** In every report, separate: (a) tests actually run with their output, (b) things only read in code, (c) unverified.
- If Godot cannot run in your environment, say so and give me exact manual test steps.

## 10. Documentation to maintain
- `docs/MASTER_PROMPT.md` (this file)
- `docs/STORY.md`: my story, the source of truth for lore, characters and plot. I write it; you never edit it.
- `docs/STATUS.md`: current milestone, what works, known bugs, next 3 tasks
- `docs/DECISIONS.md`: important choices and why (including the final-boss ending model)
- `docs/BOSS_ROSTER.md` and `docs/ASSETS.md`
- `docs/DEVELOPMENT_LOG.md` (what each session changed) and `docs/CONTROLS.md` (keyboard, gamepad and touch controls)

## 11. Do not
- Rewrite working systems without explaining why and getting my agreement.
- Add features outside the current milestone.
- Build several eras or many bosses before the framework and first chapter are stable.
- Copy characters, art, music or levels from existing games.

## 12. Session protocol
**Start of every session:** read `docs/STATUS.md`, `docs/DECISIONS.md` and `docs/STORY.md`, inspect the real project (Godot version, scenes, scripts, input map, signals, resource paths, physics layers, combat, enemies, bosses, touch controls, save system). Do not assume a feature works because a script exists.

**First response of a session (short, no code changes yet):**
1. Project structure summary and Godot version.
2. What works, with evidence.
3. Critical errors and missing pieces.
4. The top 3 fixes or tasks, in order.
5. File-by-file plan for those tasks.
6. Which tests you can actually run.
Then wait for my "go" unless the fix is a clear critical error.

**Work loop:** fix critical errors first, make small commits, test after each change, explain important decisions.

**End of every session:** update `docs/STATUS.md` and `docs/DEVELOPMENT_LOG.md`, list files changed, list tests run and their real results, and name the next task.

---

## 13. SESSION 1 TASK: build the playable foundation (Milestone 1 only)

**Status:** starting from zero. This section overrides the "wait for my go" rule in section 12: do a brief workspace inspection, state your plan in a few lines, then build.

### 13.1 Setup
- Inspect the workspace first. Create the project in the current directory. Do not overwrite unrelated files.
- Run `git init` and commit after each working step.
- Apply the pixel settings from 5b (480x270, integer scaling, nearest filter, pixel snapping).
- Folders: `scenes/characters/`, `scenes/enemies/`, `scenes/levels/`, `scenes/ui/`, `scripts/combat/`, `scripts/game/`, `scripts/systems/`, `assets/sprites/`, `assets/audio/`, `data/`, `docs/`.
- If Godot is not available, say so, prepare the project files as far as possible, and do not pretend anything was run.

### 13.2 Input actions (same actions for keyboard, gamepad and touch)
`move_left`, `move_right`, `jump`, `attack`, `magic`, `dodge`, `heal`, `pause`.
Keyboard defaults: A/D or arrows to move, Space or W to jump, J attack, K magic, L dodge, H heal. Add a gamepad mapping. Build an on-screen touch layout that fires the same actions, as long as it does not compromise desktop play.

### 13.3 What to build
1. **Player:** run, variable-height jump, gravity, platform collision, coyote time and input buffering (5a), camera follow with level bounds.
2. **Three-hit melee combo** in the Dan-the-Man style (5a): hit-stop, flash, knockback, hit sparks, a debug toggle that shows hitboxes. The third hit is a knockback finisher.
3. **Magic projectile:** collides with walls and enemies, deals damage, costs mana, has a cooldown.
4. **Dodge:** configurable duration and cooldown, with a window of invulnerability.
5. **Basic healing:** limited charges, a clear visual effect.
6. **One enemy type** (original design): patrol, detect, chase, a telegraphed attack, health, hit reaction and knockback, death.
7. **Player health, mana and HUD:** health, mana, heal charges, dodge cooldown.
8. **Defeat screen with working restart**, routed through a single `ResetManager` autoload that counts resets (7a). The defeat text should nod to the repeating loop (for example "The loop begins again.").
9. **Prehistoric jungle test level:** a clear start, platforms, one hazard (pit or spikes), 4 to 6 enemies, and an end marker that shows a simple "level complete" screen.
10. **Animation structure** so final pixel sprites can replace the placeholders without code changes. Use these animation names: `idle`, `run`, `jump`, `fall`, `attack1`, `attack2`, `attack3`, `cast`, `dodge`, `hurt`, `die`.

### 13.4 Starting values (put all of them in `data/combat_tuning.tres` and tune by play)
Run speed 110 px/s, jump velocity -300, gravity 900, combo window 0.4 s, hit-stop 3 frames (5 on the finisher), projectile speed 220 px/s and damage 2, magic cooldown 0.5 s, dodge 0.25 s with 0.2 s invulnerability and 0.6 s cooldown, player health 5, heal charges 3. Treat these as defaults to adjust, not as sacred numbers.

### 13.5 Rules for this session
- Smallest complete playable version first; keep the project runnable after every change.
- No empty placeholder systems created just to claim a feature exists.
- Placeholder art: simple pixel shapes at the correct sizes. Do not use smooth vector art.
- No external dependencies.
- Keep the premise from section 2 visible in the docs and the defeat text only. No other story content.

### 13.6 Testing (be honest about what ran)
- Run the Godot command line where possible: import the project headless, check scripts for parse errors, and launch it headless for a few seconds while reading the output for errors. Add a small headless smoke test that spawns the player and enemy and checks damage and death if feasible.
- Verify: the project opens with no parse errors, the player moves/jumps/attacks/casts/dodges/heals, enemy health and damage work, player health drops, defeat and restart work, the level can be completed.
- Report separately: tests actually run with their output, things only read in code, and things unverified. If Godot cannot run, give me exact manual test steps.

### 13.7 Strict scope limit
Do NOT build in this session: other eras, any boss encounter or the boss framework, boss title cards, the skill tree, inventory and equipment, the final boss, or the story campaign.

### 13.8 Definition of done
I can launch ORIGIN, enter the jungle test level, move, jump, do a three-hit combo, cast magic, dodge, heal, fight an enemy, take damage, see the HUD, die, restart, and finish the level.

### 13.9 Final report (use this exact structure)
1. Files created or modified.
2. Features actually implemented.
3. Tests run and their results.
4. Known bugs and limitations.
5. The single best next task.

**Stop after Milestone 1. Do not start Milestone 2 until I say so.**
