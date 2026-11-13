# Draw a ship's servicing areas in the loadout editor holo

Working plan for #6311. Decisions live in the issue body. Deleted before the PR merges.

## Goal
The loadout editor's holo can show the boxes where a ship repairs, rearms and refuels, named as on the ship page.

## What changed

### Phase 1 — API
1. `GET /models/{slug}/loadout-preview` returns `servicingAreas` from `hardpoint_transforms["servicing_areas"]`: key `container#name`, curated name, 1-based index in the ship page's order, position, rotation, size.

### Phase 2 — Holo
1. `HoloViewer` models take `boxes`, drawn as translucent boxes with edges in the export frame; one can be highlighted.
2. `LoadoutPreview` passes the areas through when asked to.

### Phase 3 — Editor
1. A toggle in the ship header shows the areas; a card in the figures lists each with name and size; hovering a row highlights its box.
2. Translations in all locales.

## Key files

| File | Role |
|------|------|
| `app/views/api/v1/models/loadout_preview.jbuilder` | Preview JSON |
| `app/api_components/v1/schemas/models/loadout_preview/` | Preview schema |
| `app/frontend/shared/components/HoloViewer/Model/index.vue` | Draws the hull and its parts |
| `app/frontend/frontend/components/Loadout/Preview/index.vue` | Preview wrapper |
| `app/frontend/frontend/components/Vehicles/LoadoutModal/index.vue` | Editor |

## Discovery Log

- **2026-11-13** Galaxy `flight_hardpoints.json` in the bucket has one area, `RepairZone` on `animated_body`, size [12, 12, 14] (x, up, depth). The Liberator's upload predates the areas.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
