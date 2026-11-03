# Paint booth: ship textured holo on a turntable with all paints

Working plan for #6144. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A tools page where a picked ship's textured holo turns on a pedestal and every paint it has is one click away, with the view carried in the URL only.

## What changed

### Phase 1 — Filter
1. `Model.with_textured_holo` scope on the textured-holo attachments
2. `withTexturedHolo` on the public `ModelQuery`, honoured by `/models` and `/filters/models/options`

### Phase 2 — Page
1. `PaintBooth` component: turntable `HoloViewer` in the backdrop room, landed pose, paint grid, built on `useModelHolo`
2. `pages/tools/paint-booth.vue`: unlabelled ship picker narrowed to textured ships, `ship`/`paint` in the query
3. Backdrop room scaled to models larger than a figure, so zoom works on ships
4. Route and nav entry gated on `HOLO_TEXTURED`; labels in all seven locales

## Intent Verification

- [x] **Picker offers only ships with a textured holo** — filter test + picker query spec
- [x] **Every paint with maps listed; picking one repaints** — component spec
- [x] **Landed pose where exported, flight otherwise** — component spec
- [x] **View reproducible from the URL, nothing persisted** — page spec
- [x] **Looks right on a real ship** — tuned live with the user on the Gladius

## Key files

| File | Role |
|------|------|
| `app/models/model.rb` | `with_textured_holo` scope |
| `app/frontend/frontend/components/PaintBooth/index.vue` | Stage and paint grid |
| `app/frontend/frontend/pages/tools/paint-booth.vue` | URL state and ship picker |
| `app/frontend/frontend/composables/useModelHolo.ts` | Existing repaint logic, reused unchanged |

## Discovery Log

- **2026-11-03** A liveried variant carries its own copy of the base ship's `holo_textured`, so the attachment alone decides the filter.
- **2026-11-03** The backdrop room is a 9m sphere sized for a figure and capped zoom at 6.3m; a ship's camera starts outside it. Scaled by the model's longest side over 2.5m, so figures keep scale 1.

## Progress
- [x] Phase 1
- [x] Phase 2
