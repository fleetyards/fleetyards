# Cargo Grid 45-Degree Rotation Support

## Goal

Support 45-degree rotation of cargo holds in the CargoGridViewer so ships like the Hull B can display a true diamond pattern instead of approximating it with offset staggering.

## Approach

**Rendering-only rotation** — container packing stays axis-aligned on the original hold dimensions. The visual rotation is applied via a Three.js transform on the hold group, rotating wireframe + containers together.

## Steps

### 1. Frontend — Extend types in CargoGridViewer

**File:** `app/frontend/frontend/components/CargoGridViewer/index.vue`

Add `rotation` (degrees, 0 for none) to:
- `Placement` type (~line 261)
- `HoldLayout` type (~line 148)

### 2. Frontend — Pass rotation through `findBestHoldArrangement`

**File:** `app/frontend/frontend/components/CargoGridViewer/index.vue`

In the `allHaveOffsets` branch (~line 369-386):
- Read `h.rotation` from the hold data
- For 90/270: keep existing dimension swap logic
- For 45 (and other non-axis-aligned angles): do NOT swap dimensions, pass rotation through to placement
- Store rotation on the `Placement` object

### 3. Frontend — Update bounding box math in `placementsToResult`

**File:** `app/frontend/frontend/components/CargoGridViewer/index.vue` (~line 302-344)

Current code uses simple `p.ox + p.gx` for bounding extents. For rotated holds, compute the 4 corners of the rotated rectangle:

```typescript
const theta = (p.rotation || 0) * Math.PI / 180;
const cos = Math.cos(theta);
const sin = Math.sin(theta);
const hw = p.gx / 2;
const hd = p.gz / 2;
const cx = p.ox + hw;
const cz = p.oy + hd;

const corners = [
  [cx + hw*cos - hd*sin, cz + hw*sin + hd*cos],
  [cx - hw*cos - hd*sin, cz - hw*sin + hd*cos],
  [cx + hw*cos + hd*sin, cz + hw*sin - hd*cos],
  [cx - hw*cos + hd*sin, cz - hw*sin - hd*cos],
];
// Use corners for min/max instead of p.ox + p.gx
```

For 0/90/270 the corner math produces the same result as the current simple approach, so no regression.

### 4. Frontend — Pass rotation to HoldLayout

**File:** `app/frontend/frontend/components/CargoGridViewer/index.vue`

In the layout building loop (~line 626-648), set `rotation` on the `HoldLayout` from the arrangement position data. Default to `0`.

### 5. Frontend — Apply visual rotation in template

**File:** `app/frontend/frontend/components/CargoGridViewer/index.vue` (~line 1087)

Add `:rotation` to the hold `TresGroup`:

```vue
<TresGroup
  v-for="layout in group.holds"
  :key="`hold-${layout.holdIndex}`"
  :position="layout.position"
  :rotation="[0, (layout.rotation || 0) * Math.PI / 180, 0]"
>
```

Rotation is around Y (the up axis in the 3D scene). TresJS accepts `[x, y, z]` radians mapping to `Object3D.rotation` (Euler).

### 6. Admin UI — Allow 45-degree step

**File:** `app/frontend/admin/pages/models/[id]/edit/cargo-holds.vue`

Change rotation input `:step="90"` to `:step="45"`.

### 7. Update Hull B offsets

**File:** `app/tasks/maintenance/apply_cargo_hold_offsets_task.rb`

Replace the current stagger-based Hull B offsets with `r: 45` values. Recalculate offset positions to account for rotated footprint — a 2.5x2.5 hold rotated 45 degrees has an axis-aligned bounding box of ~3.54x3.54.

### 8. Verify other ships unaffected

Ships using `r: 90` (Hull C) and `r: 270` (Caterpillar, Carrack) must render identically. The corner-based bounding box math produces the same result for axis-aligned rotations.

## What doesn't change

- **Container packing** (`tryPlaceOne`, `computeGreedyFill`) — containers always pack into the unrotated hold grid
- **Database schema** — `rotation` column already accepts any integer
- **API schema** — already typed as `{type: :integer, nullable: true}`

## Risks

- Rotated holds have larger axis-aligned bounding boxes → camera may zoom out more than needed (cosmetic)
- Hold overlap must be prevented through careful offset values (data quality, not code)
- SCU floor grid won't align with rotated holds (cosmetic, acceptable)

## Files to change

| File | Change |
|---|---|
| `app/frontend/frontend/components/CargoGridViewer/index.vue` | Steps 1-5: types, placement, bounding box, rendering |
| `app/frontend/admin/pages/models/[id]/edit/cargo-holds.vue` | Step 6: rotation input step |
| `app/tasks/maintenance/apply_cargo_hold_offsets_task.rb` | Step 7: Hull B offsets with `r: 45` |
