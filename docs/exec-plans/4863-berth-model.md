# Berths: pads, envelope, vehicle classes and access

## Goal

A berth can say what it is built for, what will physically go in it, and how a vehicle gets there — so "will it fit" stops being one dimension check standing in for four different questions.

## Context

#4856 shipped the narrow version: one rule, envelope only, stated on a ship's page. It is correct about what it claims and deliberately claims little. Working on it, and talking it through, turned up that the domain has at least four axes where the schema has one and a half.

Everything below was measured against production data on 2026-09-10/11 unless marked otherwise. The domain knowledge is @mortik's; the numbers are checked.

Tracks #4863.

## The axes

### Envelope — what physically goes in

Length × beam × height. Recorded, used by #4856, and the only axis that works today.

It is a legitimate question on its own. The Idris is a 100 × 25 × 8 hall that is really three Gladius-sized pads, and nothing stops somebody parking one long slim ship in it.

### Pads — what it is built for

How many berths a hangar holds, and what size each is. Not recorded at all.

This is what separates the Polaris from the 890 Jump: comparable hangars, probably the same pad beneath, yet slightly different ships fit. The similarity lives in the pads, the difference in the envelope.

Vehicle pads are visibly standardised already:

| dimensions | count | ships |
|---|---:|---|
| 10 × 7 × 6 | 9 | Carrack, 600i, Corsair, Freelancer MAX, 3× Constellation, Hammerhead, Valkyrie |
| 18 × 9 × 7 | 3 | A2/C2/M2 Hercules |

with three outliers that look hand-entered: Starfarer 8 × 5 × 4, Cutlass Black 8 × 6 × 5, 890 Jump 18.2 × 10.8 × 7.

Ship docks are not standardised, and their `ship_size` is unreliable — see the curation list below.

### Vehicle class — what a bay takes

A ladder of t-shirt sizes rather than measurements, because "holds an Ursa" is the answer a player wants and "10 × 7 × 6" is not. Anchored on reference vehicles:

ATLS → hover bikes (Dragonfly down to Pulse) → PTV/UTV → Cyclone → Ursa → Nova/Ballista

The ladder is visible in the data. Ground vehicles by volume (m³):

| class | vehicles | volume |
|---|---|---:|
| ATLS | ATLS, ATLS GEO | 10 |
| bikes / small | PTV, Ranger ×3 | 13–15 |
| UTV/STV | UTV, STV | 23 |
| Cyclone | Cyclone MT, ROC, CSV-SM | 60–62 |
| Ursa | MTC, MDC, Ursa, ROC-DS, G12 | 77–113 |
| large | Ursa Medivac, Lynx, Storm | 141–284 |
| Nova/Ballista | Nova, Centurion, Spartan, Ballista | 560–655 |

The ATLS is its own smallest class at half a PTV, and its rule of thumb — fits wherever two 1 SCU boxes stack — checks out: 1 SCU is a 1.25 m cube, so two is 2.5 m against a recorded ATLS height of 2.8 m.

**It cannot be derived.** The Cyclone base variants are recorded as 6.0 × **8.75** × 3.5 — wider than long, wider than an Ursa — which puts Cyclone above Ursa by volume and inverts the real order, on exactly the class where "does it fit the Carrack" is decided. `Cyclone MT` at 6.0 × 4.0 × 2.5 is sane, so the family disagrees with itself.

### Access — how a vehicle gets in

Ramp, lift, or in the last resort a tractor beam. Not recorded, and interesting for every dock rather than only hangars.

This is not a yes/no about fitting. A car can be tractor-beamed into a hangar; it is merely awful. So access belongs on the *label*, not in the filter — "possible, awkwardly" is a thing a boolean cannot say, and #4856 currently answers by staying silent instead.

Note the asymmetry: a hover bike needs no ramp in space but does in atmosphere, so it asks the same question a ground vehicle does.

## Decisions taken

### D1 — A dock belongs to something, polymorphically

`docks` hangs off `models` alone. `cargo_holds` is already polymorphic, and six of its rows hang off a `ModelModule` — the Galaxy's medic module carries a vehicle lift for an Ursa, and the Caterpillar may get one.

So `docks` wants `parent_type` / `parent_id`, **not optional**: a dock always belongs to something, just not always to a ship. That is stricter than today's nullable `model_id` and looser than requiring a model.

Sequenced after #4864 and #4856: the orphans have to go first — they would have no parent — and `Model.with_dock` is what #4856 builds on, so reshaping under it would mean rebasing seven commits against a schema change.

**Done.** `model_id` stays on the table for one release: the pre-deploy migration runs against the containers still serving the old code, and that code selects the column. Dropping it in the same deploy 500s every dock read in the window between. A follow-up removes it.

The admin API moved with it — `modelId` became `parentId` + `parentType` on the payload, the input and the query — and the docks editor is now one component both the model and the module pages render, so a module dock can actually be created rather than merely expressed.

Touches `Model.with_dock`, the dock associations on `Model` and newly on `ModelModule`, `docks_controller` (`model_id_eq` and the create params), `dock_input` and `dock_query`, and three places in `admin/pages/models/[id]/edit/docks.vue`.

### D2 — `size`, never `ground`

Settled in #4856 and recorded here because it is easy to get wrong twice. `ground` means "cannot reach space": every hover bike — Nox, Dragonfly, X1, Pulse, HoverQuad — is `ground: false` while still berthing as a vehicle, eleven of the forty-four.

### D3 — The existing `vehiclepad` / `garage` split is not the distinction

It does not separate "stands on the cargo grid" from "dedicated bay". Carrack and Polaris are both `garage`; Hammerhead is `vehiclepad`. The dock names overlap across both — "Cargo" under `vehiclepad`, "Cargohold" and "Cargobay" under `garage` — and the dimensions do too: Hammerhead's `vehiclepad` and Carrack's `garage` are both 10 × 7 × 6.

Whether a berth consumes cargo capacity is a real and useful distinction. It is just not this field, and it is not derivable — the Carrack has nine cargo holds *and* a dedicated garage.

## Curation list

Code cannot answer these; they need somebody who knows the ships.

**Ship dock sizes.** Sorted by envelope length the run is monotonic apart from one:

| hangar | length | `ship_size` | note |
|---|---:|---|---|
| Galaxy | 16 | XXS | at least XS, per @mortik |
| Carrack | 20 | XS | |
| Odyssey | 29 | XS | closer to the Polaris, so S |
| 890 Jump | 33.9 | S | |
| Javelin | 39 | M | |
| **Polaris** | **45** | **XS** | wrong on any reading |
| Idris | 100 | S | arguably right — it describes the *pads* |

The Idris is the tell that the column already carries two meanings.

**Unmeasured ship docks:** the Merchantman hangar and both of the Odyssey's docking collars. Silent today rather than wrong, since an unmeasured dock declines to answer.

**Vehicle dock outliers:** the three listed above.

**Cyclone dimensions:** filed separately; the beam is wrong and it misorders the class ladder.

## Not in this plan

Letting players record what a specific berth holds — "the garage on my Carrack takes an Ursa", "the 400i bike garage takes a Nox". It needs the class ladder first, so that it is a statement on a scale rather than free text.

## Discovery Log

- **2026-09-11** D1 built. Two columns turned out not to exist at all: `dock.rb` annotated a `ramp` boolean, and `ransackable_attributes` offered `station_id` — the same 2021 station era that left the 391 orphans. Neither was reachable, both are gone.
- **2026-09-11** Written after #4856. The polymorphic parent (D1) came out of a question about modules mid-review, and stopped that PR from shipping a `NOT NULL model_id` that would have had to be undone.
- **2026-09-10/11** Measurements taken while building #4856. Two of them corrected earlier conclusions of mine: the dock data is healthy once the 391 orphans are excluded, and `ground` is not what distinguishes a vehicle.

## Progress

- [x] D1 — polymorphic parent, after #4864 and #4856
- [ ] Vehicle class ladder, curated
- [ ] Pads: count and size per berth
- [ ] Access: ramp / lift / tractor beam, on the label
- [ ] Curation pass on the list above
