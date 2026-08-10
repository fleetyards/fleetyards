# Survivability → Defense + Hull panes (armor integration)

Branch: `feat/survivability-armor`

Split the single Survivability pane into an erkul-style **Defense** pane (shield +
armor) and a **Hull** pane, integrate the armor component data that already
reaches the frontend, and move the drill-downs into modals.

## Current state

`components/Models/SurvivabilityMetrics/index.vue` is one card holding: combined
HP / shield HP / hull HP tiles, a mirror-match TTK line, effective-HP by damage
type, shield resistance bars, a hull composition bar, and an inline
`Collapsed` hull-parts table. Armor is not used at all.

The effective-HP model today is:

```
EHP_type = hull + shield / (1 - shieldResistance_type)
```

This has **two defects**: it ignores armor damage multipliers, and it assumes
shields absorb 100% of incoming damage (see `absorption` below).

## Data availability (verified against the dev DB, 4.9.0-live)

### Armor — fully available, unused

Ship armor is a top-level `Hardpoint` with `category: 'armor'` (`Hardpoint`
model, `app/models/hardpoint.rb:66` — note this is *not* `ModelHardpoint`, whose
`category` enum has no armor member).

- **213 / 246 models** carry an armor hardpoint, all with a component attached
- **212** of those have complete `type_data`
- Serialized as `component.typeData` typed `ComponentArmor` (added in #4265)

Spread across the 212 ships:

| Field | Range | Verdict |
|---|---|---|
| `damagePhysical` | 0.6 – 0.85 | Use — 15–40% reduction |
| `damageEnergy` | 0.4 – 1.1 | Use — 60% reduction … 10% **amplification** |
| `damageThermal` | always 1.0 | Dead column, hide |
| `damageDistortion` | 0.95 / 1.0 | Near-dead |
| `deflection*` | 5 – 554 (flat) | Display only, see below |
| `selfResistance*` | varies | Only meaningful if armor HP is a modelled layer |
| `health` | 360 – 220,320 (median 4,352) | See open question |

### Shield `absorption` — available, and it changes the math

`ComponentShield` already exposes an `absorption` map alongside `resistance`
(`app/api_components/shared/v1/schemas/component_shield.rb:40`). Sample
(`shld_godi_s02_secureshield`):

```
resistance: physical max 0.25, energy 0, distortion max 0.95, thermal 0
absorption: physical max 0.45, energy 1.0, distortion 1.0, thermal 1.0
```

`absorption` is **shield penetration**: 1.0 means the shield soaks all of that
damage type; physical 0.45 means **55% of ballistic damage bleeds straight
through to the hull while shields are still up**. This is the mechanic behind
"ballistics pierce shields", and it is the missing half of a faithful EHP model.
No backend work needed — it is already in the payload.

### Armor penetration resistance — NOT parsed

The raw armor XML carries a parameter we drop on the floor:

```xml
<armorPenetrationResistance basePenetrationReduction="1">
  <penetrationAbsorptionForType DamagePhysical="1" DamageEnergy="1"
    DamageDistortion="0" DamageThermal="1" ... />
</armorPenetrationResistance>
```

Not in `items_parser.rb`, not in the `ComponentArmor` schema. Needed only for a
faithful penetration simulation — requires parser + schema + regen.

### "Armor reflection"

No `reflection` parameter exists anywhere in the armor XML. The closest is
`armorDeflection` (flat per-hit damage subtraction, already parsed). Assuming
erkul's "reflection" is our deflection — **worth confirming before building the
simulation modal**.

## Target structure

Each card holds one layer's own values. Anything that combines layers (effective
HP, time to kill) lives in the simulation modal, not on a card — that is what
keeps the panes from reading as a pile of mixed numbers.

### Pane 1 — Defense (shield + armor values only)

- Hero tiles: Shield HP (+ generator count), Regeneration
- Shield resistance bars
- Shield penetration bars (from `absorption`) + explanatory hint
- Armor section, headed with armor HP: damage reduction bars (negative when a
  type is amplified) with deflection alongside, self-resistance chips, signature
  modifier chips
- Button → simulation modal

No hull figure appears on this card.

New composable `useArmorStats.ts`, mirroring `useShieldStats.ts`: walks the
hardpoint tree for `category === 'armor'`, returns typed multipliers, deflection,
self-resistance, signature modifiers and HP, plus a `hasData` flag for the 33
armor-less models.

### Pane 2 — Hull (hull only)

- Hero tiles: Hull HP, part count
- Composition bar
- Button → hull parts modal (replaces the inline `Collapsed` table)

### Corrected EHP model

There are two ways the hull dies, and the real figure is whichever comes first:

```
layered_type     = shield / (1 - resistance_type) + hull / armorMult_type
bleedThrough_type = hull / (armorMult_type * (1 - absorption_type))

EHP_type = min(layered, bleedThrough)     // bleedThrough only when absorption < 1
```

Absorption **cancels out of the layered term** — damage that leaks past the
shield isn't wasted, it lands on the hull, so it shortens both phases in equal
measure. It survives only as the bleed-through cap: on a shield-heavy ship,
enough physical damage skips the shield to destroy the hull before the shield
ever drops. That cap is the entire reason ballistics work, and it is flagged in
the modal.

Distortion stays out of the list — it downs shields rather than killing the hull.

### Modals

Existing pattern — `comlink.emit("open-modal", { component: () => import(...),
props: {...} })`, inner component wraps `@/shared/components/AppModal/Inner`.

1. **Hull parts** — the `Collapsed` table from the old pane, moved verbatim.
2. **Weapon damage drill-down** — the equivalent `Collapsed` block from
   `CombatMetrics`, moved.
3. **Survivability simulation** — shield/hull pools, TTK, and a per-damage-type
   table (shield resistance, penetration, armor reduction, resulting effective
   HP, bleed-through flag). Backed by `useSurvivabilitySim.ts`, which is where
   the cross-layer math lives.

### Layout

`Hardpoints/index.vue:170-181` currently renders Combat | Survivability at
`col-lg-6`. With drill-downs moved to modals all three cards get shorter, so:
`col-12 col-lg-6 col-xl-4` — 1-up mobile, 2-up lg, 3-up xl.

## Status — done

1. ✅ `useArmorStats` composable + unit coverage
2. ✅ Corrected EHP model in `useSurvivabilitySim` + unit coverage for the
   bleed-through cap
3. ✅ Split `SurvivabilityMetrics` → `DefenseMetrics` + `HullMetrics`; old
   component retired; grid now `col-12 col-lg-6 col-xl-4`
4. ✅ Hull-parts modal, weapon-damage modal, survivability simulation modal
5. ✅ i18n — only `en` carried these strings (the other six locales have no
   metrics-card keys and fall back), so `labels.defense.*` / `labels.hull.*` /
   `labels.simulation.*` replaced `labels.survivability.*` in `en` alone

6. ✅ Reworked against the real erkul UI (see below): chip rows instead of bars,
   `Absorption` shown as its own min–max range instead of an inverted
   "penetration" figure, deflection corrected to threshold semantics, weapon
   breakdown modal dropped, cards laid out in a 3-column grid with
   `align-items: start` so short cards no longer stretch

Verified: `pnpm lint` (eslint + prettier + vue-tsc + tsc) clean, 26 composable
tests passing. Not yet verified in a running browser.

The single-ship effective-HP modal built in an earlier pass was removed — erkul
has no equivalent, and its cross-layer numbers were what made the panes read as
mixed. The EHP model it used is preserved above and is recoverable from git if
it earns a place later.

## Decisions

1. **Armor HP is not part of the HP pool.** Armor's role is reflection /
   mitigation, not a health layer. `health` stays out of Total HP and out of EHP;
   it is shown as a stat inside the armor section, not as a hero tile alongside
   Shield HP and Hull HP (which would imply pooling).
2. **erkul's "reflection" is our `armorDeflection`** — flat per-hit damage
   subtraction, already parsed.

## erkul comparison (checked 2026-08-09, v4.9.0-LIVE)

Looked at the real Defense card and simulation modals rather than working from
notes. Corrections and gaps found:

### Deflection is a threshold, not a flat subtraction

erkul's Deflection check shows, for the Gladius vs a Tigerstrike T-19P:
`Phys 9 (23 raw) vs 11 → DEFLECTED`. A shot whose post-mitigation damage lands
at or below the deflection value is turned away **entirely** — it is a gate, not
a subtraction. Earlier notes in this plan had it wrong.

### The damage pipeline, confirmed arithmetically

`23 raw × 0.55 × 0.75 = 9.49 ≈ 9`, where `0.55 = 1 - absorptionPhysical(0.45)`
and `0.75 = damagePhysical`. So:

```
effectivePerShot_type = raw_type × (1 - absorption_type) × armorDamageMult_type
deflected             = effectivePerShot_type <= deflection_type
```

This independently confirms the absorption reading used in this branch: the
shield soaks `absorption`, the remainder reaches armor, and armor's damage
multiplier applies to what gets through. Types with `absorption = 1` (energy,
distortion, thermal) never reach armor at all — erkul renders them `ABSORBED`.

### Card layout

erkul packs the Defense card as **label + chip rows**, not bars — the whole card
(shield HP/regen, resistance, absorption, armor HP, deflection, damage
reduction, self resistance, signature, countermeasures) fits in roughly the
height our bar-based version used for shields alone. They also label the raw
stat **Absorption** with its min–max range (`Phys 0 – 45%`) rather than
inverting it into a "penetration" figure. Both adopted.

### Still missing on our side

- **Face type** (`Bubble`) — not parsed.
- **Countermeasures** (`Decoy 48`, `Noise 5`) — the data exists (untyped
  `maxAmmo` on countermeasure hardpoints) but is not surfaced on the card.
- **Hull card**: erkul also shows dimensions + mass, and the part categories as
  inline tiles with count + HP.

### Cosmetic hull parts — fixed

`collect_hull_parts` required `damageMax.positive?`, which silently dropped every
zero-health part: doors, ladders, step plates, flaps. Those are exactly the
`COSMETIC · NO HP` rows erkul lists, and their absence is why our part count sat
at 26 against their 51. Zero-health parts are now kept and categorised
`cosmetic`; `hull_health` is unchanged because they contribute nothing.

After regenerating `data/sc_data/parsed`, the Gladius reports **51 parts, 25 of
them cosmetic** — an exact match for erkul on both counts.

Still divergent: the *other* category assignments. erkul splits the remaining 26
as Secondary 8 / Breakable 11 / Subpart 6; `part_category` gives 4 / 8 / 13. The
totals agree (6 110 hull HP) but the `DamageBehaviors`-based heuristic groups
parts differently from theirs, which is also why their Structural (4 590) and
Detachable (1 520) tiles are not derivable from our data. Separate follow-up.
- **No weapon breakdown modal** — their Damage card carries an inline
  Source × (Alpha/Sustained/Burst) table (Pilot / Manned turret / Remote turret
  / PDS) and the per-weapon detail lives in the Armament list below. Ours is
  removed accordingly.

## Next phase — the simulation modals

erkul has three, and they are **cross-entity comparison tools**, not single-ship
summaries. That is the substantive gap.

| Modal | Question | Data needed | Blocker |
|---|---|---|---|
| Deflection check | which guns pierce *this* ship? | every weapon's `damagePerShot` per type | `ComponentQuery` has no category filter, and `component_class` is `nil` on all 1604 weapon components — needs a `categoryIn` filter added |
| Penetration check | whose defenses can *my* weapons punch through? | all 213 ships' armor HP/deflection/reduction + shield HP/absorption | no endpoint exposes this — needs a lightweight `/models/defenses`-style index |
| Travel time | projectile flight | `speed`, `range`, `fullDamageRange`, `zeroDamageRange` on `ComponentWeapon` | none — frontend only |

Shared UI shape: a threshold-sorted list split at "THRESHOLD CROSSED", with
target/weapon health sliders, a size filter (S1–S10), a `n deflected · n pierce`
counter, and a detail bar for the hovered row.

`armorPenetrationResistance` remains unparsed; it is not needed for any of the
three above.

### Deflection check — backend done

`GET /components/weapons` (`operationId: componentWeapons`) returns every ship
gun in the current game version as a slim row: `id`, `name`, `slug`, `size`,
`manufacturerCode`, `damagePerShot` per type. 311 weapon components carry parsed
data; filtering to `component_sub_type: "Gun"` leaves ~207, matching the guns
erkul lists.

Deliberately a dedicated endpoint rather than a filter on `/components`:

- the full component serializer carries prices, media, manufacturer and
  hardpoints — far too heavy for a few hundred rows
- version scoping belongs on the server. Components are stored per game version
  (5 live in the dev DB), and `Component` has no default scope, so `/components`
  would return the same gun five times
- `ComponentQuery` has no category filter, and `component_class` is `nil` on all
  1604 weapon components, so no existing filter isolates guns

### Why our gun list was 42 longer than erkul's

erkul lists **133** guns; ours started at 175 armed non-beam guns. The gap is
entirely game-file-only variants that are not loadout options:

| Variant | Count |
|---|---|
| `_lowpoly` (LOD meshes) | 7 |
| `_ship-specific` (`_idris`, `_javelin`, `_bengal`, `_vng_`) | 10 |
| `_turret` / `automatedturret` | 6 |
| `_bespoke` | 6 |
| `_securitynetwork` (NPC copies) | 3 |
| `_collector` | 2 |
| `_weak` | 1 |
| `_shark` (cosmetic skin editions) | 3 |

Excluding them by `sc_key` leaves **138 against their 133** — the last five are
likely further edge cases or a slight data-version difference, and are not worth
chasing. The filter lives in the controller (`WEAPON_VARIANT_KEYS`) and is
null-safe, since `NOT (NULL ~ regex)` is `NULL` and would otherwise drop every
row whose `sc_key` is unset.

Of the rows served, some carry an all-zero `damagePerShot`; those are skipped
client-side rather than filtered server-side, so the endpoint stays generally
useful.

### Weapon class — for erkul's Type filter

erkul groups guns as "Ballistic Gatling", "Laser Repeater", "Tachyon Cannon" and
so on. We had nothing equivalent: `component_type` is the coarse `WeaponGun` and
`component_sub_type` is just `Gun`.

The classification is in the game files after all, on the `AttachDef` element:

```xml
<AttachDef Type="WeaponGun" SubType="Gun" Size="3"
  Tags="GATS BallisticGatling flightReady weaponMountUsable" ... />
```

`Tags` mixes manufacturer codes, engine flags and the weapon class. The parser
now pulls the class out (longest-match first, so `DistortionScatterGun` is not
read as `ScatterGun`, and vendor-prefixed forms like `BANU_TachyonCannon` still
match) along with the `weaponMountUsable` flag, and stores both in the weapon's
`type_data`.

Deliberately in `type_data` rather than new columns: `Component` already has an
`item_class` **integer enum**, so a parsed `item_class` string would collide, and
`type_data` is already the per-component blob the endpoint reads. Avoids a
migration for what is effectively weapon-specific metadata.

Of the 138 guns the endpoint serves, **123 carry a class** across 14 values; the
15 without are mining/utility mounts that have no class tag. The Type select is
built from whatever classes are actually present, so it stays correct as the
game data changes.

### Deflection check — frontend done

`useDeflectionCheck` scores every weapon against the ship's own defenses:

```
alpha_type      = damagePerShot_type / pelletsPerShot
absorption_type = absMin + (absMax - absMin) × shieldHealth   // 0 when shields are down
resistance_type = resMin + (resMax - resMin) × shieldHealth   // 0 when shields are down
deflection_type = deflectionBase_type × armorHealth

effective_type  = alpha_type × (1 - absorption_type) × (1 - resistance_type)
deflected       = effective_type <= deflection_type
```

**The armor's own damage reduction is deliberately absent**, and getting this
wrong is easy: on the Gladius, armor `damagePhysical` (0.75) and
`1 - shieldResistancePhysical` (1 − 0.25) are *the same number*, so its eight
rows validate either formula. The Asgard separates them — at 0% shields erkul
reports effective damage equal to raw alpha across nine weapons, which a 30%
physical armor reduction would rule out. Shield resistance it is. Both ships are
now regression-tested precisely because one of them alone is not enough.

A weapon pierces if **any single** damage type clears its threshold; results are
sorted by margin so the deflected/piercing split is contiguous and the
"threshold crossed" divider lands in one place. Types with `absorption = 1`
never reach armor and render as `ABSORBED`.

`DeflectionCheckModal` mirrors erkul's layout: shields-up toggle, size filter,
`n deflected · n pierce` tally, margin bars growing out from a centre threshold
line, and a detail bar with the per-type breakdown for the hovered weapon.

**Three outcomes, not two.** An early version counted a fully shielded weapon as
"deflected", which claimed a 9-point armor threshold turned away a size 10
energy cannon. Absorbed, deflected and pierces are now distinct: a shot the
shield soaks never meets the armor, so armor deflection has no say in it. The
tally reads `n absorbed · n deflected · n pierce`, and absorbed rows show no
margin because there is no threshold to measure against.

**Both pools are sliders, and both scalings were measured, not guessed.** Driving
erkul's own sliders on the Asgard settled two things the game files do not state:

- **Shield absorption** = `min + (max - min) × health`. At 26% shield health
  they report 12% physical absorption, at 40% they report 18% — against a 0–45%
  published range that is `0.45 × health`, while energy (range 1–1) stays at
  100% throughout. Both fit the interpolation; neither fits `max × health`.
- **Armor deflection scales linearly with armor health.** At 51% armor the
  Asgard reports 71 physical / 45 energy against 139 / 88 at full health. Worth
  recording because all 209 armor files carry an empty
  `<healthCurve useLUT="0" />` with no curve points — the scaling is simply not
  in the data, so this is measured behaviour.

The modal mirrors erkul's two panels: each slider shows the scaled pool HP and
the live per-type figures (Absorb % for shields, Defl value for armor).

**The shield slider looks inert above 0%, and that is correct.** 118 of the 179
non-beam guns are energy-only, and energy absorption has no range — it is a flat
`1.0`, so it cannot taper. Those weapons stay absorbed at any shield health
above zero and all flip at once when the shield drops. Sweeping our own data
gives `absorbed 118 / deflected 39 / pierce 22` at full shields against
`118 / 36 / 25` at 1%, then `4 / 102 / 73` at zero. erkul behaves identically:
energy reads `100%` absorbed at 50% and 26% shield health, and only at 0% do
its energy weapons enter the deflection ranking. The cliff is the mechanic
("energy and distortion are fully absorbed **while shields hold**"), not a bug.

**Two rules read off erkul's own footnote**, both of which we had wrong:

- **Alpha is compared per pellet.** A scattergun's shot is split across its
  pellets and each pellet meets the threshold alone. 14 guns carry
  `pelletsPerShot > 1`; treating their full shot damage as one hit made them
  pierce far too easily.
- **Laser beams are excluded.** They deal continuous damage, so there is no
  per-shot alpha to test against a threshold. 28 of the 207 guns are beams.

`pelletsPerShot` and `beam` are now on the weapons endpoint; the beam filter is
applied client-side so the endpoint stays generally useful.

**Verified against erkul.** All eight physical rows they publish for the Gladius
reproduce exactly, margins and list order both:

| Weapon | Alpha | Effective | Margin | erkul |
|---|---|---|---|---|
| SW16BR1 "Buzzsaw" Repeater | 18 | 7.43 | −4 | −4 |
| Mantis GT-220 Gatling | 19 | 7.84 | −3 | −3 |
| Tigerstrike T-19P | 23 | 9.49 | −2 | −2 |
| SW16BR2 "Sawbuck" Repeater | 24 | 9.90 | −1 | −1 |
| SW16BR3 "Shredder" Repeater | 45 | 18.56 | +8 | +8 |
| Havoc Scattergun | 47 | 19.39 | +8 | +8 |
| 9-Series Longsword Cannon | 49 | 20.21 | +9 | +9 |
| Breakneck S4 Gatling | 52 | 21.45 | +10 | +10 |

Locked in as a table-driven spec so a formula regression fails loudly.
