# Hangar guide as a step-by-step tour, and a redesigned hangar / fleet preview

Working plan for #5496. Decisions live in the issue body. Deleted before the PR merges.

## Goal
Replace the stale hangar guide modal with a tour that spotlights the real controls on `/hangar`, and move the hangar and fleet preview pages onto one shared, rewritten layout.

## Open questions
- None.

## Phases

### Phase 1 — Tour component
1. `shared/components/Tour`: dimmed page with a spotlight cut out around the target (the hole's own box-shadow is the dimming), a dialog card placed with `placeFloating`, Back / Next / Skip, a step counter.
2. Steps with `requiresTarget` and nothing rendered are dropped when the tour starts; other steps without a target show a centred card.
3. Keyboard: focus moves into the card, Esc skips, ←/→ step, Tab cycles inside the card, focus returns to the trigger. The rest of `body` is `inert` while it runs.
4. Follows its target on scroll, window resize and body resize; z-index 2150 (above dropdowns at 2100, below PhotoSwipe / Loader / notifications).

### Phase 2 — Hangar tour
1. `Hangar/Tour` defines the steps: welcome, add, sync, display options (cards vs list), groups, a ship’s menu, wishlist, fleetchart, stats, share, the "…" menu. Targets are `data-tour` attributes on the hangar page, `VehiclePanel` and `PrimaryAction`.
2. `hangarStore.tourSeenBy` (persisted, per account) replaces `starterGuideVisible`, which was set on account confirmation and never read.
3. Auto-starts once for accounts under 30 days old when the hangar is empty, unfiltered, the stats are not refetching and the groups request has settled; a click or key press first cancels it. It is marked seen as soon as it opens. "Show Guide" and the empty state's button (only on the owner's hangar, grid or table) replay it.
4. `Hangar/GuideModal`, its YouTube embeds and the `hangarGuide` keys are gone.

### Phase 3 — Preview pages
1. `FeaturePreview`: hero heading with lead, a feature grid (1 / 2 / 3 columns at the tablet / desktop breakpoints), sign-up and log-in.
2. `hangar/preview.vue` and `fleets/preview.vue` render it with six features each; their page stylesheets and the extra `section.container` are gone.

### Phase 4 — Copy
All new strings in de, en, es, fr, it, zh-CN, zh-TW; the replaced keys are removed from all seven.

## Intent Verification

- [x] **Tour replaces the modal** — both guide buttons start it; `GuideModal` deleted.
- [x] **Spotlights real controls** — steps target `data-tour` attributes on the live page.
- [x] **Missing targets skipped** — `Tour/index.spec.ts`, and the e2e walk asserts `vehicle` / `share` are absent on an empty hangar without a public hangar.
- [x] **Keyboard and focus** — `Tour/index.spec.ts`.
- [x] **Auto-start once** — `HangarTour.spec.ts` (skip, reload, replay from the menu).
- [x] **Shared preview layout** — `FeaturePreview/index.spec.ts`; existing `Hangar.spec.ts` / `Fleet.spec.ts` preview flows unchanged.
- [x] **Translations** — de, en, es, fr, it, zh-CN, zh-TW.

## Key files

| File | Role |
|------|------|
| `app/frontend/shared/components/Tour/index.vue` | overlay, spotlight, card, keyboard |
| `app/frontend/frontend/components/Hangar/Tour/index.vue` | hangar steps, seen state |
| `app/frontend/frontend/pages/hangar/index.vue` | targets, auto-start, guide button |
| `app/frontend/frontend/components/FeaturePreview/index.vue` | shared preview layout |
| `test/playwright/e2e/HangarTour.spec.ts` | auto-start, skip, replay, full walk |

## Not in scope (deferred)
- None.

## Discovery Log

- **2026-10-08** The guide's wishlist section embedded the *edit* video; every instruction predated the context menu, the group edit mode and the share button.
- **2026-10-08** `hangarStore.starterGuideVisible` was written on account confirmation and never read anywhere.
- **2026-10-08** No e2e spec opens an empty `/hangar` (the chips scenario seeds vehicles), so the auto-starting tour cannot cover another spec's clicks.
- **2026-10-08** Review: abandoned starts could leave a page inert, the table view had no tour wiring, events and contracts are flag-gated so the fleet preview advertises allies instead, and a new user's hangar is public by default.
- **2026-10-08** `headlines.json` carries a duplicate `missions` key in every locale; edited as text so a JSON round-trip does not drop it.
