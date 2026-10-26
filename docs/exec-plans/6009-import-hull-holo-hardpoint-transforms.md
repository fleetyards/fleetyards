# Import the hull holo and hardpoint transforms for the loadout preview

Working plan for #6009. Decisions live in the issue body. Deleted before the PR merges.

## Goal
The ship views import attaches `flight_holo_hull.glb` and stores `flight_hardpoints.json`, and a public endpoint serves both to the loadout editor.

## What changed

### Phase 1 — Hull holo attachment
1. `hull` variant in the holo filename rule (Ruby `ShipViewFields` + admin `mapping.ts`), flight only like `textured`; shared fixture cases.
2. `has_one_attached :holo_hull` on Model, outside the media payload; admin update input + admin payload so the folder upload can set it; labels in all locales.

### Phase 2 — Port transforms
1. `models.hardpoint_transforms` jsonb column.
2. `ShipViewsImportJob` maps `flight_hardpoints.json` to it, md5-tracked in `ship_view_md5s` like a render; `RenderImport` learns to assign a non-attachment field.

### Phase 3 — Endpoint
1. `GET /api/v1/models/:slug/loadout-preview` → `{holoHull, ports}` with hand-written schemas (`ModelLoadoutPreview`, `ModelLoadoutPreviewPort`, `ModelLoadoutPreviewPortType`).
2. Integration test, schema + orval regen.

## Intent Verification

- [ ] Import of a listing with `flight_holo_hull.glb` attaches `holo_hull`; `landed_holo_hull.glb` is ignored
- [ ] Import stores the ports and skips them when the md5 is unchanged
- [ ] Endpoint returns the hull URL and ports; 404 for an unknown slug; empty ports without data

## Key files

| File | Role |
|------|------|
| `app/lib/sc_data/ship_view_fields.rb` | Filename → field rule |
| `app/frontend/admin/components/Models/ViewsFolderUpload/mapping.ts` | Same rule for the admin upload |
| `app/jobs/sc_data/ship_views_import_job.rb`, `app/jobs/concerns/.../render_import.rb` | Import |
| `app/controllers/api/v1/models_controller.rb` | Endpoint |

## Not in scope (deferred)
- **Loadout preview viewer** — three.js composition on the ship page / loadout editor.
- **Items' own hardpoints.json** — not published yet.

## Discovery Log

- **2026-10-26** Initial research and plan creation. The render pipeline exports flight only; port entries carry an optional `geometry: false` for undrawn default items.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
