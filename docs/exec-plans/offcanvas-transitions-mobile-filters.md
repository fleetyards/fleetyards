# OffCanvas Transition Fix + Mobile Filter OffCanvas

## Goal

Fix the OffCanvas component's broken async transitions and use it to display filter forms on mobile instead of inline collapsing.

## Context

The OffCanvas component has visual bugs: empty panel flash during async component loading, fragile `setTimeout(550)` cleanup, and content-shifting `translateX` hacks on `.app-content` causing flicker. On mobile, filter forms should open in an OffCanvas overlay for a better UX instead of collapsing inline.

## Decisions

### D1 — Dual-state pattern (matching AppModal)

Use `isShow` + `isOpen` instead of a single `visible` flag. `isShow` controls DOM visibility, `isOpen` triggers CSS animation. This matches the established AppModal pattern in the codebase and provides proper lifecycle separation.

### D2 — Remove content shifting

Remove all `translateX` transforms on `.app-content` and `.navigation-mobile`. The OffCanvas should be a pure overlay. This eliminates the reflow hacks and flicker source entirely.

### D3 — GPU-accelerated transform instead of left/right

Animate `transform: translateX()` instead of `left`/`right` CSS properties. Transform is GPU-accelerated and doesn't trigger layout reflow.

### D4 — Teleport-only (no async component loading)

Remove the async component pattern entirely — OffCanvas becomes a pure container. Content arrives exclusively via Vue `<Teleport>` from consumer components. Add `id="off-canvas-content"` to the OffCanvas body div as a stable teleport target (always in DOM since the panel is always rendered, just off-screen). No current consumers use the async component path.

### D5 — Use existing `useMobile()` composable

Replace FilteredList's manual mobile detection (duplicate `ref + resize listener`) with the existing `useMobile()` composable.

## What changed

### Phase 1 — Fix OffCanvas transitions

1. **`types.ts`**: Remove `component` and `props`, keep only `title?` and `side?`
2. **`useComlink.ts`**: Add `"off-canvas-closed"` event for close notification
3. **`index.vue`**: Rewrite with dual-state (`isShow`/`isOpen`), remove content shifting, add `id="off-canvas-content"` to body div
4. **`index.scss`**: Replace `left`/`right` animation with `transform: translateX` + `visibility` toggle, replace `visible` class with `show`/`in`

### Phase 2 — Mobile filters in OffCanvas

1. **`FilteredList/index.vue`**: Use `useMobile()`, open OffCanvas on mobile filter toggle, Teleport filter slot to `#off-canvas-content`, listen for `"off-canvas-closed"` to sync state
2. Handle edge cases: unmount cleanup, mobile-to-desktop resize, OffCanvas reuse

## Intent Verification

- [ ] **Desktop filter toggle unchanged** — Inline slide transition works as before on screens >= 992px
- [ ] **Mobile filter in OffCanvas** — Filter toggle at < 992px opens OffCanvas overlay with filter form
- [ ] **Backdrop close syncs state** — Tapping OffCanvas backdrop closes it and resets filter visibility
- [ ] **No empty panel flash** — OffCanvas slides in only after content is ready
- [ ] **Smooth transitions** — No flicker, no layout shifts during open/close
- [ ] **Resize handling** — Resizing mobile→desktop while filter open closes OffCanvas gracefully

## Key files

| File | Role |
|------|------|
| `app/frontend/shared/components/OffCanvas/index.vue` | Main OffCanvas component |
| `app/frontend/shared/components/OffCanvas/index.scss` | OffCanvas styles |
| `app/frontend/shared/components/OffCanvas/types.ts` | OffCanvas TypeScript types |
| `app/frontend/shared/components/FilteredList/index.vue` | Filter container with mobile/desktop logic |
| `app/frontend/shared/composables/useComlink.ts` | Event bus for cross-component communication |
| `app/frontend/shared/composables/useMobile.ts` | Mobile detection composable |

## Not in scope (deferred)

- **Filter form styling adjustments** — May need minor padding tweaks inside OffCanvas, handle post-implementation
- **Admin FilteredList** — Admin app also uses FilteredList and OffCanvas; same changes apply automatically

## Discovery Log

- **2026-04-05** Initial research and plan creation

## Progress

- [x] Phase 1 — Fix OffCanvas transitions
- [x] Phase 2 — Mobile filters in OffCanvas
