# Exec Plan: Display Extended Ship State (Holo + Views)

## Context

Commit `e75e0814f` added admin-side extended dimensions and media for ships
that physically transform (Hull-B/C, etc.):

- `extended_length`, `extended_beam`, `extended_height`
- `extended_fleetchart_offset_length`, `extended_fleetchart_offset_beam`
- attachments: `extended_holo`, `extended_top_view`, `extended_side_view`,
  `extended_front_view`, `extended_angled_view` (+ colored variants)

The public API already exposes these under `model.metrics.*` and
`model.media.*` (see `app/views/api/v1/models/_base.jbuilder`). Nothing on the
frontend reads them yet.

## Goals

1. On the ship detail page, let users flip between retracted and extended
   state — the holo, the fleetchart-style views, and the dimension labels all
   swap in place.
2. In the Fleetchart tool, expose a single global toggle (per namespace) that
   renders every ship in its extended state when on, falling back per-ship
   when extended data is missing.

Out of scope:
- The embed fleetchart (`app/frontend/embed/components/Fleetchart/*`) —
  separate consumers, keep retracted-only for now.
- Compare page, hangar lists outside the fleetchart canvas.
- Admin pages (already handled in the original commit).

## Detail page — `app/frontend/frontend/pages/ships/[slug]/index.vue`

### State

Local `ref<boolean>` `extendedState`, default `false`. No store — the choice
is page-scoped; users switching ships should start retracted.

Computed `hasExtendedState` is true when any of the extended fields are
populated. Used to conditionally render the toggle:

```ts
const hasExtendedState = computed(() => Boolean(
  props.model.metrics.extendedLength ||
  props.model.media.extendedHolo ||
  props.model.media.extendedTopView,
));
```

### Toggle UI

Add a `BtnGroup` next to the existing 3D/2D/ADI Map controls (`.toggle-3d`).
Two buttons: "Retracted" / "Extended". Only mounted when `hasExtendedState`
is true. Translation keys under `labels.model.state.{retracted,extended}`.

### Holo

Replace the existing `holoModel` computed with one that swaps source based on
`extendedState.value`:

```ts
const holoModel = computed(() => {
  const useExtended = extendedState.value && props.model.media.extendedHolo;
  const path = useExtended
    ? props.model.media.extendedHolo?.url
    : props.model.media.holo?.url;
  const length = useExtended
    ? props.model.metrics.extendedFleetchartOffsetLength ||
      props.model.metrics.extendedLength
    : props.model.metrics.fleetchartOffsetLength;

  if (!path || !length) return;
  return { path, length };
});
```

`HoloViewer` already takes `{ path, length }`; no signature change needed.

### Fleetchart views

Push `extendedState` into `FleetchartImages` as a prop:

```vue
<FleetchartImages :model="model" :extended="extendedState" />
```

Inside `FleetchartImages/index.vue`, each `fleetchartImage*` computed picks
the extended attachment when `props.extended` is true AND the extended
variant exists; otherwise it falls back to the regular one (same
mobile/colored selection logic).

Same fallback for `modelLength` / `modelBeam`:

```ts
const modelLength = computed(() => {
  if (props.extended) {
    return props.model.metrics.extendedFleetchartOffsetLength ||
           props.model.metrics.extendedLength ||
           props.model.metrics.fleetchartOffsetLength || 1;
  }
  return props.model.metrics.fleetchartOffsetLength || 1;
});
```

### Dimension labels

`ModelBaseMetrics` currently reads `model.metrics.length/beam/height`. Two
options — picking the simpler one:

- **Picked:** accept an `extended` prop and swap the displayed value in
  place. Cleaner — same row count, single column reads as "current state".
- Rejected: show both lengths side-by-side. Doubles the visual real estate
  and is redundant when the user already chose a state.

```vue
<ModelBaseMetrics :model="model" :extended="extendedState" />
```

`BaseMetrics` computes `displayLength/Beam/Height` that fall back the same
way as above. Keep `model.metrics.length` as the floor so non-extendable
ships render unchanged.

### Watch for state reset

`watch(() => props.model, () => { extendedState.value = false; })` so
navigating between ships doesn't leave the toggle stuck.

## Fleetchart tool — global toggle

### Store — `app/frontend/shared/stores/fleetchart.ts`

Add a per-namespace flag, mirroring `color`:

```ts
type FleetchartState = {
  // ...existing
  extended: string[];
};

getters: {
  extended: (state) => (namespace: string) =>
    state.extended.includes(namespace),
  // ...
}

actions: {
  toggleExtended(namespace: string) {
    if (this.extended.includes(namespace)) {
      this.extended = this.extended.filter((n) => n !== namespace);
    } else {
      this.extended.push(namespace);
    }
  },
}
```

Persisted automatically (store has `persist: true`).

### UI — `FleetchartApp/index.vue`

Place the toggle next to the existing mode dropdown so it's discoverable
from both panzoom and classic mode. Single icon button with active state,
tooltip "Extended state" / "Retracted state":

```vue
<Btn
  v-tooltip="t(extended ? 'actions.fleetchartApp.useRetracted' : 'actions.fleetchartApp.useExtended')"
  size="small"
  :active="extended"
  @click="fleetchartStore.toggleExtended(namespace)"
>
  <i class="fa-light fa-arrows-from-line" />
</Btn>
```

(Icon TBD — `fa-arrows-from-line` or `fa-expand-arrows-alt`.)

### Item rendering — `Fleetchart/List/Item/index.vue` + `ListPanzoom/Item/index.vue`

Both items currently read `model.metrics.fleetchartOffsetLength/Beam` and
`model.media.{topView,sideView,angledView}` (via
`extractImageFromModel`). They receive the namespace via the parent
`FleetchartList` / `FleetchartListPanzoom`.

Two clean ways to pass the flag:

- **Picked:** prop drill `extended` from List → Item (1 hop). Keeps Item
  pure, no store coupling, matches how `viewpoint`/`scale` flow.
- Rejected: read the store inside Item. Item would need the namespace,
  which means a new prop anyway — same surface area, more coupling.

In `FleetchartListItem`, swap the lookups when `props.extended`:

```ts
const length = computed(() => {
  const offset = props.extended
    ? model.value.metrics.extendedFleetchartOffsetLength ||
      model.value.metrics.fleetchartOffsetLength
    : model.value.metrics.fleetchartOffsetLength;
  return (offset || 0) * props.sizeMultiplicator * props.scale;
});
```

`extractImageFromModel(model, viewpoint)` becomes
`extractImageFromModel(model, viewpoint, extended)`: when `extended` is true
and `media.extendedTopView` (etc.) exists, return it; otherwise current
behavior. The paint/module-package branches stay on retracted media — paints
don't have extended attachments, and adding them is a separate piece of
work (see "Open question" below).

`sourceImage{Width,Height}` calculations follow the same fallback.

`FleetchartList` and `FleetchartListPanzoom` read the namespace flag once:

```ts
const extended = computed(() => fleetchartStore.extended(props.namespace));
```

…and forward it to each `<FleetchartItem ... :extended="extended" />`.

The sort in `FleetchartApp.updateItems` keeps using `metrics.length`. Sorting
by extended length when toggled is a nice-to-have but adds churn (the list
would reshuffle every time someone flips the toggle); skip for v1.

## API

No changes — data is already exposed (verified in
`app/views/api/v1/models/_base.jbuilder:68-122` and `:132-139`).

## Open question

Paints and module packages don't currently have extended media. The
fleetchart item falls back to model media when paint media is missing, so
the extended toggle works for vanilla ships and for paints/modules where
extended data isn't yet authored. If we eventually want
paint/module-package extended renders, that's a separate admin + DB +
importer piece; flag it as follow-up rather than blocking this work.

## Testing

- Manual: pick a ship with extended state (Hull-B once data exists; until
  then a fixture with mock attachments). Verify on detail page:
  - Toggle swaps holo path
  - Toggle swaps the four fleetchart views
  - Toggle swaps length/beam/height labels
  - Navigating to another ship resets to retracted
- Manual: fleetchart tool — open with a fleet mixing extendable and
  non-extendable ships. Verify extendable ones swap, others stay put.
- Manual: persisted flag — toggle on, reload, flag is still on for that
  namespace.

No new specs needed — purely view-layer wiring.

## Phasing

1. Store + types — add `extended` array and getters/actions.
2. Detail page wiring — toggle, holo, views, metrics props.
3. Fleetchart tool — UI button in `FleetchartApp`, prop drill through
   List/ListPanzoom into Item.
4. i18n strings.
