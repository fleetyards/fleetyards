# Cargo Grids: Ship Comparison — Unified 3D Viewer

**Issue:** fleetyards/fleetyards#3783
**Branch:** `feature/cargo-grids-comparison`

## Context

When accepting hauling missions, players need to check cargo crate sizes and determine which ship handles them best. Currently the Cargo Grids tool only shows one ship at a time, requiring tedious back-and-forth switching. This feature adds a unified 3D viewer that renders up to 4 ships' cargo grids in one scene, color-coded per ship, with draggable groups and per-ship stats.

## Design Decisions

- **Unified 3D viewer:** All ships rendered in a single TresJS/Three.js canvas — one WebGL context, direct visual size comparison.
- **Color-coded wireframes:** Each ship's hold outlines rendered in a distinct color (cyan, orange, purple, blue). Container colors shared across ships.
- **Ship name labels:** HTML labels (via `@tresjs/cientos` Html component) floating above each ship's grid group.
- **Draggable groups:** Each ship's cargo grid can be dragged in the XZ plane with snap-to-grid (1 SCU / 1.25m). OrbitControls disabled during drag.
- **Per-ship stats:** Stats section below the viewer with one panel per ship showing capacity, max container, packed SCU, and warnings.
- **Selection UX:** "Add Ship" button adds additional FilterGroup dropdowns (up to 4). Remove button is a `×` icon. Reset behind confirm dialog.
- **Auto-fill:** Per-ship "Auto-fill" button fills shared container inputs optimally for that ship.
- **Module toggles:** Inline with each ship selector row.
- **URL scheme:** `?ship=slug` (backward compat single), `?ships=a,b,c` (multi), `?modules.slug=mod1,mod2` (per-ship modules).

## Implementation

### New Files

| File | Purpose |
|------|---------|
| `composables/useCargoGridShip.ts` | Per-ship composable: model query, modules query, combined holds, module toggle, greedy fill |
| `components/CargoGridViewer/CargoGridDragHandler.vue` | Renderless component inside TresCanvas for raycasting-based drag with 1 SCU snap |

### Modified Files

| File | Changes |
|------|---------|
| `components/CargoGridViewer/index.vue` | `ships` prop, `ShipEntry` type, `SHIP_COLORS`, multi-ship pack results, color-coded wireframes, Html labels, drag handler integration, per-ship stats template |
| `components/CargoGridViewer/index.scss` | Ship label, multi-stats, ship-stats styles, compact variant |
| `pages/tools/cargo-grids.vue` | Multi-ship selectors with pre-allocated 4 composable slots, inline module toggles + auto-fill per ship, unified viewer, confirm on reset |
| `pages/tools/cargo-grids.scss` | Ship selectors layout |
| `translations/*/labels.json` | addShip, removeShip, autoFillShip keys |
| `translations/*/messages.json` | confirmReset key |
| `spec/playwright/e2e/CargoGrids.spec.ts` | Updated for unified viewer, multi-ship tests |

### Architecture

```
cargo-grids.vue (page)
  ├── 4x useCargoGridShip(slug) — pre-allocated composable slots
  ├── builds ships: ShipEntry[] from active slots
  └── CargoGridViewer
        ├── ships prop → multiShipPackResults (per-ship packing)
        ├── CargoGridDragHandler (raycasting + snap drag)
        ├── TresCanvas with per-ship TresGroups (color-coded)
        └── Per-ship stats section below canvas
```

### Key Technical Details

- **packSingleShip()** — extracted packing logic, left-aligns holds at x=0 so multi-ship layout controls positioning
- **multiShipPackResults** — positions ships sequentially along X with 4 SCU gaps, centers the entire scene
- **shipDragOffsets** — decoupled from pack computation; applied via `getShipPosition()` in template only, preventing scene rebuilds on drag
- **isPreviewMode** — excludes multi-ship mode to prevent preview containers rendering alongside ship grids

## Verification

1. Single ship: `?ship=drak-caterpillar` — identical to previous behavior
2. Multi ship: `?ships=anvl-carrack,drak-caterpillar` — color-coded grids side by side, per-ship stats
3. Drag: click and drag a ship's grid — snaps to 1 SCU grid, camera stays stable
4. Reset: click "Reset" — confirm dialog appears
5. Mobile: stacks vertically, reduced DPI
