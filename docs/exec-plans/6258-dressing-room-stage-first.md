# Redesign the dressing room with the figure filling the page

Working plan for #6258. Decisions live in the issue body. Deleted before the PR merges.

Mockups: https://claude.ai/artifact/6GGZ8NU2cMAh5JdPoiQq6C (boards "B · Stage first", "B · Supplies tab open", "B · Phone").

## Goal

The dressing room is one stage the figure fills, with the loadout, character, storage and outfits in translucent framed panels over it and every viewer control in one bar on the stage.

## Open questions

- Phone loadout: a fixed panel overlapping the stage's foot (planned), or a sheet the user can drag up? Dragging adds gesture handling for little gain.

## What changed

### Phase 1 — Stage and layout
1. `pages/tools/dressing-room.vue`: the stage becomes the page's backdrop on desktop (`$desktop-breakpoint` and up): full width below the heading, `100dvh` minus the header; the side columns become absolutely placed overlays (left loadout, right column) with their own scroll.
2. Panels: `Panel` with `translucent` (plus a backdrop blur) for each overlay, so the end-caps and frame match the rest of the app.
3. Heading row: title, then Armour sets, Copy link and Save outfit on the right. Lead text goes.

### Phase 2 — Loadout tabs
1. New `DressingRoom/Loadout` component: tabs Armour, Weapons, Gear, Supplies as a segmented `BtnGroup` with `role="tablist"`; the active tab kept in the component (not the URL).
2. `SlotRow` gains a slot icon and an empty state ("Add a helmet") in place of italic "Choose…".
3. Supplies: the current `gearColumns` (ammo, grenades, medpens, oxypens) as slot grids with "n of m" counts, replacing `.dressing-room__gear` below the stage.
4. The gear hint (no gear provider worn) moves into the Gear tab.

### Phase 3 — Stage control bar
1. One bar at the stage's foot: body (segmented), pose select, reset, full screen. Copy link moves to the heading.
2. Drop the hover/tap reveal of `.dressing-room__actions`: the bar is always shown.

### Phase 4 — Right column
1. Characters, WornStorage and Outfits each in their own translucent panel.
2. Save outfit: Outfits exposes its save so the heading's button triggers it; the name input stays in the Outfits panel.

### Phase 5 — Phone
1. Below `$desktop-breakpoint`: heading, stage with its control bar over the figure's feet, then the loadout panel overlapping the stage's foot, Armour sets and Save outfit at its end, then the right column panels.
2. Fix the stage floor blowing out white on phones (check the backdrop's floor material and the low-power path).

### Phase 6 — Strings and checks
1. New strings (tab names, empty slot labels, counts) in every locale.
2. Update `dressing-room.spec.ts` and component specs; screenshots at 1440, 2560 and 390.

## Intent Verification

- [ ] **Stage fills the page** — on desktop the figure's stage spans the full width below the heading, panels float over it.
- [ ] **Loadout tabs** — Armour, Weapons, Gear, Supplies; empty slots read "Add …" with a slot icon.
- [ ] **Supplies in the loadout** — no slot rows below the stage; supplies show "n of m".
- [ ] **One control bar** — body, pose, reset and full screen on the stage.
- [ ] **Heading actions** — Armour sets, Copy link, Save outfit.
- [ ] **Phone** — stage on top, loadout panel with tabs below, no white floor.
- [ ] **Nothing lost** — pickers, links, outfits, storage, characters and share links behave as before (existing specs pass).
- [ ] **Locales** — every new key in en, de, es, fr, it, zh-CN, zh-TW.

## Key files

| File | Role |
|------|------|
| `app/frontend/frontend/pages/tools/dressing-room.vue` | Page layout, slot groups, gear columns, actions |
| `app/frontend/frontend/components/DressingRoom/SlotRow/index.vue` | One slot row |
| `app/frontend/frontend/components/DressingRoom/Characters/index.vue` | Character panel |
| `app/frontend/frontend/components/DressingRoom/Outfits/index.vue` | Saved outfits and save |
| `app/frontend/frontend/components/DressingRoom/WornStorage/index.vue` | Storage |
| `app/frontend/shared/components/base/Panel/index.vue` | Framed panel, `translucent` |
| `app/frontend/shared/components/HoloViewer/backdrop.ts` | Stage room and floor |
| `app/frontend/frontend/pages/tools/dressing-room.spec.ts` | Page spec |

## Not in scope (deferred)

- **Item thumbnails in slots** — needs a small render per item; slot icons stand in.

## Discovery Log

- **2026-11-09** Initial research and plan creation. Branch stacks on `feat/6123-dressing-room-chf-character-head` (#6236).

## Progress
- [ ] Phase 1
- [ ] Phase 2
- [ ] Phase 3
- [ ] Phase 4
- [ ] Phase 5
- [ ] Phase 6
