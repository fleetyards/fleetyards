# Sustained DPS — weapon-capacitor / power-triangle sim

Date: 2026-08-06. Branch context: `feat/hardpoints-redesign` (or a fresh branch
off it). Follows `erkul-data-gaps.md §1` and supersedes the "sustained DPS"
slice in `loadout-dps-calculator.md`.

## Goal

Replace our current **best-case** sustained DPS (which equals the max-power
duty-cycle "efficiency", e.g. CF-337 = 51% of burst) with a **power-throttled**
sustained that matches erkul (CF-337 ≈ 37% of burst; Asgard ship total 1 835 vs
our 2 502).

## Background / root cause (from the §1 spike)

- SC energy weapons draw from a **shared ship weapon-capacitor / regen pool**.
  When it drains, sustained DPS falls to an uptime %, and the **regen rate is
  governed by the Power Triangle** (power distribution / pips).
- Our `useLoadoutStats.sustainedRatio()` models the per-weapon duty cycle at
  **max regen** (`maxRegenPerSec`): `firingTime / (firingTime + cooldown +
  regenTime)`. That equals erkul's *efficiency* label but overshoots its
  *sustained* number, because erkul assumes **default power**, not max.
- Numeric target (CF-337, `klwe_laserrepeater_s3`): burst ≈ 550 DPS/weapon,
  erkul sustained ≈ 204 → factor 0.374 → effective regen ≈ 8 shots/s vs the
  `maxRegenPerSec` 15 we use (≈ 0.54 power factor — not a clean constant, not in
  the per-weapon fields, hence the sim).

## Phase 0 — OUTCOME: scope was wrong; narrowed (ran 2026-08-06)

**Correction:** the initial premise ("our sustained is wrong / = burst") was
based on the **Asgard, a high-demand edge case**. A prior session already
validated our per-weapon duty-cycle formula **exact vs erkul** on normal ships
(Aurora MR 2× CF-117: 0.5117 vs 0.5126; Guardian QI 2× M7A: 0.6048 vs 0.6046 —
see memory `project_loadout_sustained_dps`). Our current
`useLoadoutStats.sustainedRatio` implements that validated formula.

So there is **no blanket bug**. The only gap is a **ship-wide throttle on
high-demand loadouts**: the Asgard's Pilot *and* turret groups both show erkul
factor 0.374 (vs our per-weapon 0.51) — a shared **power / weapon-capacitor
limit** that bites when total weapon regen demand exceeds what the ship can
supply at default power. Low/moderate-demand ships (the majority) already match
erkul. This makes the sim **narrow and low-priority**: it only corrects sustained
on heavily-armed ships, and only downward.

Keep the current sustained + shipped efficiency %. If pursued, the model is
"cap effective regen by the ship's weapon-power/pool budget when demand exceeds
it" (Phase 0 hypotheses #1/#2 below) — needs the ship pool/power budget, which
we don't parse yet. Not a blanket rewrite.

**What was gathered** (our side, from parsed JSONs):

| weapon | burst | our ratio (=efficiency) | maxAmmoLoad / maxRegen/s / cost | requestedAmmoLoad / requestedRegen/s |
|---|---|---|---|---|
| CF-337 (klwe_laserrepeater_s3) | 546 | 0.511 | 75 / 15 / 48.5 | 18187 / 3031 |
| CF-447 (klwe_laserrepeater_s4) | 818 | 0.507 | 75 / 15 / 72.7 | 27262 / 4544 |
| amrs_lasercannon_s3 | 547 | 0.531 | 25 / 3 / 202 | 20200 / 3375 |
| amrs_scattergun_s3 | 462 | 0.923 | 75 / 15 / 440 | 15400 / 2567 |
| ballistic gatling / massdriver | — | (heat, no regen parsed) | — | — |

**Field structure found:** `requestedAmmoLoad / cost` and `requestedRegenPerSec
/ cost` are constant per weapon family (CF-337 & CF-447 both → 375 shots &
62.5 shots/s), so `requested_*` are the real energy pool/regen and `max_*`
(75/15) are a smaller local capacitor. Our `sustainedRatio` uses `max_*` as
shots — which happens to equal erkul's **efficiency** (51%), but not its
**sustained**.

**Blocker (why STOP):** erkul's CF-337 sustained (0.374 of burst) needs an
effective regen of ~4.6 shots/s. None of our fields yield that: `maxRegenPerSec`
→ 0.31 shots/s (÷cost), `requestedRegenPerSec` → 62.5 shots/s, `maxRegen` raw →
15. The real number sits between and is set by the **default power-triangle**
state + a **two-stage capacitor** (local + ship pool) whose ship-pool regen at
default power we do **not** parse. erkul's Component Finder carries no DPS/
sustained data, and its calculator's sustained is ship-power-context dependent.
Reproducing 0.374 from our data would require an unexplained magic constant
(~0.73 × efficiency), not a principled formula.

**To unblock later:** parse the ship weapon-capacitor pool + default power
allocation (models/ship XML), and/or obtain erkul's sustained methodology.
Then the matrix above is the validation set.

---

## Phase 0 — Formula gate (RESEARCH — original plan, blocked above)

**This phase decides whether the rest is worth building.** Reverse-engineer /
confirm the exact sustained formula and validate it against erkul before writing
any product code.

- Pull erkul burst + sustained + efficiency for a **matrix**: ≥5 weapons across
  types (energy repeater, energy cannon, ballistic, scattergun, beam) × ≥3 ships
  with different power-plant sizes (small fighter, the Asgard, a large multicrew).
- For each, capture our parsed inputs: `regen.{maxAmmoLoad, maxRegenPerSec,
  regenerationCostPerBullet, regenerationCooldown, requestedRegenPerSec,
  requestedAmmoLoad}`, weapon `power_base`/`power_draw`, `fireRate`,
  `damagePerShot`, and the ship power-plant `powerBase`.
- Derive the relationship that reproduces erkul's sustained across the matrix.
  Hypotheses to test, in order:
  1. **Default-power regen fraction** — sustained uses a regen rate below
     `maxRegenPerSec` set by the default weapon-power pip allocation. Find
     whether `requestedRegenPerSec`/`requestedAmmoLoad` encode it, or whether it
     is a fixed default-triangle fraction.
  2. **Shared-pool contention** — total ship capacitor drained by all weapons
     firing at once; per-weapon sustained = its share of pool regen. (erkul's
     linear scaling on the Asgard suggests the pool was *not* the bottleneck
     there, but larger loadouts may hit it — the matrix must include one.)
  3. **Continuous regen-limited rate** — once drained, fire at
     `regenPerSec / costPerBullet` shots/s.
- **Exit criteria:** a documented formula that reproduces erkul within ~±5%
  across the matrix. **If none does, STOP** — keep the best-case sustained,
  record the finding, and close this plan. (erkul's exact default-power
  assumption may be undocumented; parity is not guaranteed.)

## Phase 1 — Data (only if Phase 0 passes)

Expose whatever inputs the validated formula needs but we don't yet surface:

- Weapon `powerBase` / `powerDraw` on `ComponentWeapon` (parsed generally via
  `EntityComponentPowerConnection` — confirm it reaches the weapon api_component
  + schema).
- Ship-level weapon-capacitor pool total, if the shared-pool hypothesis wins
  (source TBD from Phase 0; may need a models-parser addition).
- Default power-triangle allocation constant(s) if fixed.
- Regenerate schema + orval client (`./bin/generate-schema`), format + lint.

## Phase 2 — Model

- Implement the validated sim in `useLoadoutStats` (new helper alongside
  `sustainedRatio`, e.g. `sustainedDpsThrottled`). Keep `sustainedRatio` as the
  **efficiency** (max-power uptime) — it is correct and already shipped in the
  weapon rows.
- Sum per-ship under the default power triangle; handle beam vs projectile vs
  scattergun; exclude missiles.

## Phase 3 — Integrate + verify

- Point the Combat card **Sustained DPS** tile at the throttled value; leave the
  per-weapon **Efficiency** stat as the duty-cycle %. Consider a short sublabel
  clarifying "default power".
- Unit tests in `useLoadoutStats.spec.ts` pinned to the Phase-0 matrix values.
- Browser-verify the Asgard combat card reads ≈ erkul (1 835) within tolerance.

## Risks / open questions

- erkul's default-power assumption is not documented; the formula may only be
  approximate. Phase 0 is the gate precisely for this.
- MasterModes (SCM vs NAV) and future power reworks can change the numbers;
  pin the data version.
- Interactive power-pip adjustment UI is a **non-goal** here (future work); this
  plan models a single default power state only.
