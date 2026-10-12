# Dedication plaque styles and the supporter perk

Working plan for #5637 (second, stacked PR). Decisions live in the issue body. Deleted before the PR merges.

## Goal
A supporter picks one of nine general plaque styles or the ship's manufacturer style; only a supporter can create or edit a plaque, and a lapsed supporter's plaque renders in Brass.

## Open questions
- None. The approved designs live in the session's design baseline (`plaque-design/makers.py`, `build.py`).

## What changed

### Phase 1 — Backend
1. Migration: `plaque_style` (string) on `vehicles`. A new migration, never a rollback: the worktree DB holds the user's test plaques.
2. `Vehicle::PLAQUE_STYLES` (brass hud gunmetal blueprint salvage glass carbon walnut neon manufacturer); `effective_plaque_style` = the stored style while the owner is a supporter, else `brass`.
3. Supporter gate on create/update: any plaque param from a non-supporter is a 403 `supporter_required`; `messages.supporter_required` in 7 locales.
4. Payloads render `plaque_style` as the effective style, plus the manufacturer `code` the frontend keys its maker styles on. Cache keys carry the effective style.
5. Schemas, schema/asyncapi/client regeneration, request tests (supporter / non-supporter / lapsed / public payload).

### Phase 2 — Frontend
1. Bundled emblem assets under `app/frontend/images/plaque/` (trimmed icons; logos for Drake, MISC, Kruger, Vanduul) and the MISC interlocking pattern. The CDN answers with `Access-Control-Allow-Origin: *`, so masks and the PNG download can read them.
2. `Plaque` component: markup aligned with the mockups (class line, registry, lines, credits, quote, decoration spans); style class from `plaqueStyle`, maker class from the manufacturer code; emblem sized optically (aspect^-0.35 × per-maker factor).
3. Style sheets ported from the mockups: `styles/general.scss`, `styles/makers.scss`.
4. PNG download: html2canvas cannot draw clip-path, masks or conic gradients; switch the plaque download to a foreignObject renderer (`dom-to-image` is already a dependency).
5. Edit modal: style picker (general styles + "Manufacturer style" when the ship's maker has one).
6. Supporter gate UI: a non-supporter's create/edit opens a become-a-supporter modal linking to the support page.
7. Translations in 7 locales; specs.

## Intent Verification
- [ ] **Gate** — a non-supporter gets 403 on any plaque field and sees the supporter modal; a supporter saves
- [ ] **Styles** — each of the 9 general and 19 maker styles renders like the approved mockups
- [ ] **Lapse** — a plaque whose owner stopped supporting renders as Brass, owner and public alike
- [ ] **Download** — the PNG keeps shapes, masks and patterns

## Key files

| File | Role |
|------|------|
| `app/models/vehicle.rb` | Styles, effective style |
| `app/controllers/api/v1/vehicles_controller.rb` | Supporter gate |
| `app/views/api/v1/vehicles/_dedication_plaque.jbuilder` | Payload |
| `app/frontend/frontend/components/Vehicles/Plaque/` | Component, styles, makers config |
| `app/frontend/frontend/components/Vehicles/PlaqueEditModal/index.vue` | Style picker |

## Not in scope (deferred)
- **Vanduul's game-file icon** — CIG's export points Vanduul at `esperia_256.tif`, so the app shows Esperia's lion for Vanduul everywhere. A loader or override fix of its own.

## Discovery Log
- **2026-10-12** Production CDN sends `Access-Control-Allow-Origin: *` for assets; uploaded blob URLs redirect to object storage with unverified CORS, so plaque emblems ship as bundled assets.
- **2026-10-12** Vanduul's `vnc.json` in the parsed tree carries `ui/sharedassets/manufacturerlogos/esperia_256.tif`.

## Progress
- [ ] Phase 1
- [ ] Phase 2
- [ ] Review
