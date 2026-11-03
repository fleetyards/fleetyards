# Paint booth: ship textured holo on a turntable with all paints

Working plan for #6144. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A tools page where a picked ship's textured holo turns on a pedestal and every paint it has is one click away, with the view carried in the URL only.

## What changed

### Phase 1 — Filter
1. `Model.with_textured_holo` scope on the textured-holo attachments
2. `withTexturedHolo` on the public `ModelQuery`, honoured by `/models` and `/filters/models/options`

### Phase 2 — Page
1. `PaintBooth` component: turntable `HoloViewer`, pose switch, paint grid, built on `useModelHolo`
2. `pages/tools/paint-booth.vue`: ship picker narrowed to textured ships, `ship`/`paint`/`pose` in the query
3. Route and nav entry gated on `HOLO_TEXTURED`; labels in all seven locales

## Intent Verification

- [x] **Picker offers only ships with a textured holo** — filter test + picker query spec
- [x] **Every paint with maps listed; picking one repaints** — component spec
- [x] **Flight/landed switch where both are exported** — component spec
- [x] **View reproducible from the URL, nothing persisted** — page spec
- [ ] **Looks right on a real ship** — needs a running dev server

## Key files

| File | Role |
|------|------|
| `app/models/model.rb` | `with_textured_holo` scope |
| `app/frontend/frontend/components/PaintBooth/index.vue` | Stage and paint grid |
| `app/frontend/frontend/pages/tools/paint-booth.vue` | URL state and ship picker |
| `app/frontend/frontend/composables/useModelHolo.ts` | Existing repaint logic, reused unchanged |

## Discovery Log

- **2026-11-03** A liveried variant carries its own copy of the base ship's `holo_textured`, so the attachment alone decides the filter.

## Progress
- [x] Phase 1
- [x] Phase 2
