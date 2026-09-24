# Berth Model: Axes, Pad Classes and What the Game Files Carry

**Date:** 2026-09-24 (measured against production 2026-09-10/11, game-file findings 2026-09-20; tracked in #4863)

"Will it fit" on a dock was one envelope comparison standing in for four questions. This note records the axes a berth actually has, the measurements behind the ship and vehicle ladders, and which parts can be derived from Star Citizen game files and which never can. Read it before changing `Dock`, the fit filter, or the vehicle size ladder.

## The axes

**Envelope — what physically goes in.** Length × beam × height. A legitimate question on its own: the Idris hangar is a 100 × 25 × 8 hall that is really three Gladius-sized pads, and nothing stops someone parking one long slim ship in it. It is reference data, not the answer to "what fits" — see the settled model below.

**Pads — what it is built for.** How many berths a hangar holds and what class each is. This separates the Polaris from the 890 Jump: comparable hangars, probably the same pad, yet slightly different ships fit — the similarity is in the pads, the difference in the envelope. Vehicle pads are already visibly standardised:

| dimensions | count | ships                                                                          |
| ---------- | ----: | ------------------------------------------------------------------------------ |
| 10 × 7 × 6 |     9 | Carrack, 600i, Corsair, Freelancer MAX, 3× Constellation, Hammerhead, Valkyrie |
| 18 × 9 × 7 |     3 | A2/C2/M2 Hercules                                                              |

with three hand-entered-looking outliers: Starfarer 8 × 5 × 4, Cutlass Black 8 × 6 × 5, 890 Jump 18.2 × 10.8 × 7.

**Vehicle class — what a bay takes.** A t-shirt ladder anchored on reference vehicles, because "holds an Ursa" is the answer a player wants and "10 × 7 × 6" is not:

ATLS → hover bikes → PTV/UTV → Cyclone → Ursa → Storm → Nova/Ballista

It is curated, not derived from volume. Volume gets the rough shape right and the boundaries wrong: the Dragonfly is Cyclone territory by volume (63–72 m³) but stows like a bike; the MDC/MTC (77 m³) sit between Cyclone and Ursa with nothing to break the tie; the Storm (284 m³) is alone between Ursa and Nova. The ATLS is its own smallest class; its rule of thumb — fits where two 1 SCU boxes stack (2 × 1.25 m = 2.5 m) — roughly checks out against a recorded 2.8 m height.

The Ursa shows why dimensions mislead. It has a lowerable turret and so two legitimate heights; the recorded 2.20 m is the lowered one, and that is the one to judge a berth on — a vehicle that can make itself shorter should be. The Medivac (same chassis) was recorded at 3.20 m, the raised configuration. Grouped by volume, that reads as two classes; it is one class and one row measuring the other configuration.

**Access — how a vehicle gets in.** Ramp, lift, or as a last resort a tractor beam. Not a yes/no: a car can be tractor-beamed into a hangar, it is merely awful. So access belongs on the label, not in the filter. A hover bike needs no ramp in space but does in atmosphere, so it asks the same question a ground vehicle does.

## Distinctions that are not what they look like

- **`size`, never `ground`.** `ground` means "cannot reach space". Every hover bike (Nox, Dragonfly, X1, Pulse, HoverQuad) is `ground: false` while still berthing as a vehicle — eleven of the forty-four vehicles.
- **`vehiclepad` vs `garage` is not "on the cargo grid" vs "dedicated bay".** Carrack and Polaris are `garage`, Hammerhead `vehiclepad`; dock names overlap across both, and Hammerhead's `vehiclepad` and Carrack's `garage` are both 10 × 7 × 6. Whether a berth consumes cargo capacity is a real distinction, but it is not this field and not derivable — the Carrack has nine cargo holds and a dedicated garage.
- **A dock can belong to a module**, not only a ship: the Galaxy's medic module carries an Ursa lift. Hence the polymorphic, non-null parent on `docks`.
- **`ship_size` carried two meanings.** Sorted by envelope length, recorded sizes ran monotonic except the Polaris (45 m, recorded XS, wrong on any reading). The Idris (100 m, recorded S) is arguably right because it describes the _pads_, which is the tell.

## The extended columns exist and are empty

`models.extended_length/beam/height` were populated on **0 of 245** models. They are not vestigial: they render into `metrics`, and the fleetchart's extended toggle appears only when `model.metrics.extendedLength` is set, so a whole control was unreachable for want of data. This is where a second configuration belongs (the Ursa with its turret raised, anything that unfolds). A berth should be judged on the smaller figure; comparing `height` is only right while models are recorded in their compact state.

## The settled model

Two definitions, and only one is shown:

- **What a berth is for.** The Galaxy's hangar is an XS pad for an XS ship; the Idris has three Small pads. Other things physically go in (a medium ship fits an Idris if you are careful) — deliberately not shown.
- **What fits.** Curated: the admin picks a class, everything of that class or below fits, and individual models are added for what the class does not cover. That union replaces the envelope comparison.

A dock carries capacity entries `(ladder, class, count)`:

- **Entries under one dock are alternatives.** The Kraken's deck is one large pad _or_ two mediums; the Ironclad Assault's grid is six Ursas _or_ two Novas (a Nova is 16 m against a 25 m grid, an Ursa 7.6 m).
- **Separate docks are simultaneous.** The Kraken's deck, side pads and hangars are all available at once.
- **The count is simultaneous within an entry.** `1 × large` already admits a medium; `2 × medium` adds that two sit there together. Nesting needs no modelling — "a big pad with two mediums on it" is the alternative.
- One entry per dock is flagged for display and its label renders from class and count ("2 medium pads"), so it translates rather than being typed English.

```
Galaxy            hangar      1 × extra_small
Idris             hangar      3 × small
Kraken  main deck (open)      1 × large  --or--  2 × medium
        side pads (open)      4 × small
        hangars   (enclosed)  2 × small
Ironclad Assault  cargogrid   6 × Ursa-class  --or--  2 × Nova-class
Carrack           garage      1 × Ursa-class
Starfarer         cargohold   1 × Ursa-class
```

Switching to this retires the envelope as the filter on both paths (`Dock#fits?` / `Model#carried_by_with_docks`, and `WillItFitConcern`), the `measured?` gate — otherwise an unmeasured berth like the Merchantman's stays silent however much is curated — and the ship/vehicle gate in `Dock#accepts?`, which is why a cargo grid could never admit a snub. It also stops inventing dimensions nobody measured: the Starfarer records Ursa-class instead of made-up centimetres.

## The ship ladder is the game's; the assignment is not

`Libs/Foundry/Records/landingpadsize/` defines six pad classes. All carry a `shipSize` box; only Small, Medium and Large carry a `groundVehicleSize`, the rest `0 × 0 × 0`. `Dock::SHIP_SIZE_METRICS` is the ship half of this table (with XLarge duplicated as `capital`). Station hangars declare their class as `sizeId` on 84 instanced interiors.

| id  | class      | shipSize       | groundVehicleSize |
| --- | ---------- | -------------- | ----------------- |
| 1   | Tiny / XXS | 12 × 16 × 6    | —                 |
| 2   | XSmall     | 24 × 32 × 12   | —                 |
| 3   | Small      | 48 × 48 × 16   | 8 × 16 × 6        |
| 4   | Medium     | 56 × 88 × 18   | 12 × 20 × 6       |
| 5   | Large      | 72 × 128 × 36  | 16 × 30 × 6       |
| 6   | XLarge     | 160 × 272 × 64 | —                 |

What the game does **not** carry:

- **Which pad a ship is assigned.** Recorded `dock_size` values (from the RSI matrix and game files) do not follow box containment — ships overhang their pads, and five of eighteen sat a class below what the boxes allow (the 400i at 56 m recorded `small` against a 48 m pad). So `dock_size` is derived from the measured hull as the smallest containing box, and only once a holo measurement exists; deriving from unmeasured dimensions would just move the guess into a new column.
- **The carrier side.** 1062 ship records reference no pad size at all, and `ObjectContainers` holds only outposts and stations — no ship interior is in the extract. The Idris' three pads and the Kraken's deck are curation and always will be.

The vehicle ladder (ATLS → Nova) is ours and does not line up with the game's three `groundVehicleSize` boxes. A dock may carry entries on either ladder or both.

## `maxBoundingBoxSize` is a bucket for ground vehicles

`maxBoundingBoxSize` is imported as `sc_length/beam/height`, and it is where the Cyclone's recorded 8.75 m beam came from. For ground vehicles it is a shared bucket, not a measurement: twelve carry the same three numbers — five Cyclone variants (AA, MT, RC, RN, TR), both Ursas, the Medivac, the Mule, the CSV-SM and the STV as 6.00 × 8.75 × 3.50, and the base Cyclone as 8.75 × 6.00 × 3.50 (axis order ours, not the game's). The ATLS pair has no box at all. For ships it is sound: 93 of 178 match the recorded figures exactly.

Wrong vehicle dimensions like the Cyclone's beam or the Medivac's height are therefore not admin curation: `MeasureHoloJob` writes `length/beam/height` off an attached holo, so a corrected holo export is the whole fix. The raised Ursa turret belongs on `extended_holo`.

## Data traps met on the way

- `vehicle_size` may only be set where `size` is `vehicle`, and the ten largest ground vehicles had no `size` — the RSI matrix carries none for exactly those ten, and the loader wrote its blanks verbatim, which would have undone a backfill nightly and, on a vehicle already on the ladder, failed validation and dropped the whole update. `size` also held four capitalised spellings and empty strings copied from the matrix. The loader must not overwrite a curated value with a blank.
- `Model#variants` groups by `base_model_id` when present, else by `rsi_chassis_id`. A family where no member has a base still groups; a family where only _some_ members carry a base breaks — the member holding the lone base shows no variants at all.
- `dock.rb` once annotated a `ramp` boolean and `ransackable_attributes` offered `station_id`; neither column existed (leftovers from the 2021 station era that also left 391 orphaned docks).
