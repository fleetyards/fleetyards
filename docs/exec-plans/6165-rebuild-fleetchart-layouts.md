# Rebuild the fleetchart with layouts, free positioning and shareable saved layouts

Working plan for #6165. Decisions live in the issue body. Deleted before each PR merges and restored on the next branch.

## Goal

One fleetchart renderer with Columns, Classic and Free layouts, more options, and saved layouts a user can share, behind a flag until switch-over.

## Open questions

None blocking. The user has not yet confirmed the option list in the issue's acceptance criteria.

## What changed

### Phase 1 — Renderer at parity (PR 1)
1. Spike `html2canvas` with rotation and `drop-shadow`, before anything depends on it.
2. Add the `fleetchart_layouts` flag and read it through `FeatureFlagName`.
3. `geometry.ts`: one calculation of a ship's size in metres per viewpoint and state.
4. `layouts/columns.ts` and `layouts/classic.ts`: ships and sizes in, centre positions out.
5. `Fleetchart/Canvas`: panzoom, absolutely positioned items with an explicit bounding box, a world-anchored grid, export.
6. `App/index.vue` renders the canvas when the flag is on. Map persisted `panzoom` and `classic` to layouts.

### Phase 2 — Options (PR 2)
1. Settings popover replacing the extra buttons.
2. Sort, grouping, spacing, scale bar, export settings; labels in all 7 locales.

### Phase 3 — Free mode (PR 3)
1. Drag on mouse (`beforeMouseDown`), snap to the grid, 90° rotation, undo and reset.
2. Start from the layout showing. Load the whole fleet, not the current page.
3. Own hangar chart only.

### Phase 4 — Saved layouts (PR 4)
1. `FleetchartLayout` model, API, policy and components, following `HangarPlan`'s `share_token` pattern.
2. Save, open, update, delete, share; a read-only route for the link.
3. Unplaced tray; drop positions of ships that are gone. Public scope filter on the shared endpoint.

### Phase 5 — Switch-over (PR 5, needs the user's OK)
1. Remove the flag and delete `List`, `ListPanzoom` and `Slider`.

## Intent Verification

- [ ] **Flag off is unchanged** — old components render and no behaviour moves
- [ ] **Columns and Classic** — side-by-side screenshots against the old chart on a real hangar
- [ ] **Export** — a PNG from every layout, with and without the grid, on a large fleet
- [ ] **Free** — positions survive a change of scale, viewpoint and extended state
- [ ] **Sharing** — a private ship placed in a layout is absent from the shared response

## Key files

| File | Role |
|------|------|
| `app/frontend/frontend/components/Fleetchart/App/index.vue` | Entry point used by every page; keeps its props |
| `app/frontend/frontend/components/Fleetchart/ListPanzoom/layout.ts` | Column logic to reuse |
| `app/frontend/frontend/components/DownloadScreenshotBtn/index.vue` | Export |
| `app/frontend/shared/stores/fleetchart.ts` | Persisted settings |
| `app/controllers/api/v1/public/hangar_plans_controller.rb` | Share-token pattern |

## Not in scope (deferred)

- **Fleet-owned layouts** — needs edit rules. Becomes its own issue.
- **Touch dragging** — follows once mouse dragging has proven itself. Becomes its own issue.
- **Group by hangar group or squadron** — a vehicle can be in several hangar groups, so it needs a rule. Becomes its own issue.
- **Embed** — separate implementation; drop unless requested.

## Discovery Log

- **2026-11-04** Classic's item sizes the same way as Panzoom's apart from the scale slider, so one item component can serve both.
- **2026-11-04** The user's reason for Classic is its arrangement only, so its slider and wheel scrolling go.
- **2026-11-04** The `exec-plans` CI job fails a PR into `main` while a plan is tracked, so each PR deletes this file in its last commit.

- **2026-11-04** `html2canvas` spike: rotation at 90° and 45° and 1px grid lines export correctly; `drop-shadow` is dropped, as it already is today. The export approach stands.
- **2026-11-04** Browser check on 48 ships against the old chart: Columns differs only where the corrected height moves a wide ship to another column. A very long ship pushed every Classic row off the opening view until rows centred on the screen instead of the widest row.

- **2026-11-04** Rotation alone saved nothing: a ship's box is as tall as its tallest view, and straight columns leave the space under a large ship empty. Packed layout and tight boxes took the same 48 ships from 1713 to 686 (scene area, 10k px).
- **2026-11-04** Exports followed the zoom, so fit-to-screen produced a 170px PNG. Exports now ignore the transform and images never pick below full size.

## Progress

- [x] Phase 1
- [x] Phase 2
- [ ] Phase 3
- [ ] Phase 4
- [ ] Phase 5
