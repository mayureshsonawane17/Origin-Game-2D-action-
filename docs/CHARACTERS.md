# ORIGIN: Character Design & Specifications

## 1. Overview & Canon Rule
Per `docs/MASTER_PROMPT.md` and `docs/STORY.md`, story and character lore remain strictly governed by the creator. Text from concept art is treated as concept notes until approved. Anything unconfirmed is marked `[STORY TBD]`.

---

## 2. Riya, "The Radiant Mage"

### 2.1 Character Identity
- **Name:** Riya
- **Title:** The Radiant Mage
- **Role:** Mage / Support (Playable Character)
- **Primary Weapon:** Ancient Magic (Emerald Radiant Arts)
- **Secondary Weapon:** Short Blade / Concealed Dagger
- **Combat Style:** Ranged / Agile / Versatile
- **Story Status:** `[STORY TBD]` (Defined in data as a playable character; relationship to the hero and the loop remains unconfirmed in canon).

---

### 2.2 Visual Appearance & Reference Analysis
*Source reference: `docs/reference/riya_character_sheet.png`*

- **Head & Hair:** Medium-length, wavy, tousled chestnut-brown hair with side-swept bangs and soft volume. Large, expressive emerald-green eyes with delicate lashes and warm golden undertones.
- **Jewelry:** Emerald teardrop pendant earrings on gold hooks.
- **Upper Garment:** Muted forest-green hooded mantle/cape lined with gold embroidery. On the back of the cape is a sacred gold four-pointed star sigil. Underneath is a cream/ivory ruffled blouse with roll-up sleeves and dark collar trim.
- **Torso & Harness:** Dark brown leather underbust corset/harness secured with dual brass-buckled utility belts. Fastened to the belt is a leather pouch adorned with an emerald cut-gem talisman.
- **Lower Garment:** Charcoal-brown fitted leather shorts with a buckled holster strap wrapping around the left thigh.
- **Footwear:** Dark espresso thigh-high fitted leather boots with folded cuffs, knee buckles, and reinforced soles over dark tights.

---

### 2.3 Sampled Color Palette
Directly sampled from `riya_character_sheet.png`:

| Swatch Name | Hex Code | RGBA (0.0 - 1.0) | Usage |
|---|---|---|---|
| **Emerald Magic** | `#5CE6A1` | `Color(0.36, 0.90, 0.63)` | Radiant magic projectiles, energy orbs, barrier |
| **Mint Highlight** | `#A8F8D0` | `Color(0.66, 0.97, 0.82)` | Spell cores, lens flares, glow speculars |
| **Forest Cape Outer** | `#3B5848` | `Color(0.23, 0.35, 0.28)` | Hooded mantle body, cape folds |
| **Forest Cape Mid** | `#5D7F6E` | `Color(0.36, 0.50, 0.43)` | Cape highlights and trim background |
| **Gold Embroidery** | `#D4AF37` | `Color(0.83, 0.69, 0.22)` | Star insignia, hem filigree, buckle hardware |
| **Blouse Cream** | `#F4E9D8` | `Color(0.96, 0.91, 0.85)` | Ruffled shirt, cuffs |
| **Skin Tone Base** | `#E8B896` | `Color(0.91, 0.72, 0.59)` | Face, legs, arms |
| **Skin Shadow** | `#C78D6A` | `Color(0.78, 0.55, 0.42)` | Jaw shadow, collarbone contours |
| **Hair Chestnut** | `#4A2E1F` | `Color(0.29, 0.18, 0.12)` | Hair shadows, boot soles |
| **Hair Highlight** | `#754E35` | `Color(0.46, 0.31, 0.21)` | Hair volume strands |
| **Leather Harness** | `#452C20` | `Color(0.27, 0.17, 0.13)` | Corset, holster straps, belts |
| **Charcoal Shorts** | `#26201E` | `Color(0.15, 0.13, 0.12)` | Leather shorts, belt linings |
| **Dark Outline** | `#1A1412` | `Color(0.10, 0.08, 0.07)` | 1px pixel-art silhouette boundaries |

---

### 2.4 UI Portrait Grid (8 Expressions)
Cropped from the 2x4 grid in `docs/reference/riya_character_sheet.png` for dialogue and UI:

1. `portrait_neutral`: Confident, calm, gentle smile. Default expression.
2. `portrait_happy`: Playful wink, joyful closed-eye laugh.
3. `portrait_shocked`: Open mouth, wide alert eyes, battle reaction.
4. `portrait_thoughtful`: Contemplative, looking slightly off-camera.
5. `portrait_determined`: Furrowed brow, focused combat resolve.
6. `portrait_concerned`: Soft downturned gaze, empathetic / worried.
7. `portrait_warm`: Compassionate smile, conversational intimacy.
8. `portrait_disappointed`: Sighing, looking back over shoulder.

---

### 2.5 Action Poses & Combat Moveset
Mapped to existing tuning and ability systems:

1. **Ranged Radiant Spell (`cast` / `magic`):**
   - Casts twin emerald-green radiant orbs rotating in an accelerating forward trajectory.
   - Pierces weak enemies, costs 12 Mana, mint highlight trail.
2. **Short-Blade Dash Attack (`attack1` / `dash_attack`):**
   - Forward lunge with reverse-grip silver short blade followed by emerald slash arc.
   - Quick startup, low recovery.
3. **Radiant Barrier (`block` / `defensive_magic`):**
   - Spherical emerald crystalline ward deflecting incoming projectiles and absorbing heavy physical hits.
   - Timed parry reflects energy back at the attacker.
4. **Piercing Radiant Lance (`finisher` / `attack3`):**
   - Powerful forward palm strike projecting a spiraling vortex beam of mint-green energy.
   - Multi-hit pierce with heavy knockback.

---

### 2.6 Pixel-Art Adaptation Specifications (480x270 Viewport)
- **Canvas Size:** 64x64 pixels.
- **Character Bounding Box:** Approximately 32x48 pixels (consistent with Hero).
- **Outlines:** 1px dark outline (`#1A1412`) for readability against multi-era backgrounds.
- **Cape Physics:** Dynamic procedural 2-frame secondary sway on the green cape in `idle`, `run`, and `fall`.
- **Animation Names:** `idle`, `run`, `jump`, `fall`, `attack1`, `attack2`, `attack3`, `cast`, `dodge`, `heal`, `hurt`, `die`.
- **Style Constraint:** Strict integer pixel art; no vector smoothing, no sub-pixel rotation.
