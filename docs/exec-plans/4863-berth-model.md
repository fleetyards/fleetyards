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

A **proposal** for the curation pass, not a derivation. Six anchors from @mortik; the seventh size is left open rather than invented. The 44 vehicles fall out roughly as:

| size | anchor | vehicles |
|---|---|---|
| `extra_extra_small` | ATLS | ATLS, ATLS GEO |
| `extra_small` | hover bikes | Pulse, Pulse LX, Nox, Nox Kue, HoverQuad, X1, X1 Force, X1 Velocity, Dragonfly ×3 |
| `small` | PTV / UTV | PTV, UTV, STV, Ranger CV/RC/TR |
| `medium` | Cyclone | Cyclone ×6, Mule, ROC, CSV-SM, MDC, MTC |
| `large` | Ursa | Ursa, Ursa Fortuna, Ursa Medivac, Lynx, ROC-DS, G12 ×3 |
| `extra_large` | Storm | Storm, Storm AA |
| `extra_extra_large` | Nova / Ballista | Nova, Centurion, Spartan, Ballista |

Three placements are guesses and want a decision: the **Dragonfly** sits at 63–72 m³, Cyclone territory by volume, yet it is a bike and stows like one. The **Storm** at 284 m³ is alone between the Ursa and the Nova. And **MDC/MTC** at 77 m³ sit between the Cyclone and the Ursa with nothing to break the tie.

Volume gets the rough shape right and the boundaries wrong, which is the whole argument for curating it rather than deriving it. Two families prove the point.

**The Cyclone.** Recorded 6.0 × 8.75 × 3.5 — wider than long, wider than an Ursa — so 184 m³ against the Ursa's 92, a class above the vehicle it sits beside. `Cyclone MT` at 6.0 × 4.0 × 2.5 is sane, so the family disagrees with itself. This is the class where "does it fit the Carrack garage" is decided.

**The Ursa.** Not a class question, and not quite a data error either.

| | L × B × H | m³ |
|---|---|---:|
| Ursa | 7.60 × 5.50 × **2.20** | 92 |
| Ursa Fortuna | 7.60 × 5.50 × **2.20** | 92 |
| Ursa Medivac | 8.00 × 5.50 × **3.20** | 141 |
| Lynx *(different chassis)* | 7.75 × 5.70 × 3.50 | 155 |

The Ursa carries a turret that can be lowered, so it has two legitimate heights. **2.20 is the lowered figure**, and it is the one to keep: a vehicle that can make itself shorter to get into a bay should be judged on the shorter measurement. The Medivac is the same chassis with a different interior and is to be corrected to 2.20.

Grouped by volume this reads as two classes. It is one class, one retractable turret, and one row that measured the other configuration.

The ATLS is its own smallest class at half a PTV, and its rule of thumb — fits wherever two 1 SCU boxes stack — checks out: 1 SCU is a 1.25 m cube, so two is 2.5 m against a recorded ATLS height of 2.8 m.

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

**Variants that are not linked.** None of the Ursa, Ursa Fortuna or Ursa Medivac carries a `base_model_id`, so they are not recorded as variants of one another and none appears in the others' variants section.

**Unmeasured ship docks:** the Merchantman hangar and both of the Odyssey's docking collars. Silent today rather than wrong, since an unmeasured dock declines to answer.

**Vehicle dock outliers:** the three listed above.

**Cyclone dimensions:** the beam is wrong and it misorders the ladder. **Ursa Medivac:** to be corrected to 2.20, matching the chassis it shares with the Ursa. Per @mortik. Both filed separately.

### The extended columns are already there, and empty

`models` carries `extended_length`, `extended_beam` and `extended_height`. They are populated on **0 of 245** models.

They are not vestigial: they are rendered into `metrics`, and the fleetchart's extended toggle decides whether to appear by asking `model.metrics.extendedLength`. So a whole control is unreachable because nobody ever filled the data behind it.

This is where a second configuration belongs — the Ursa with its turret raised, or anything else that unfolds. It also means #4856 is accidentally right today: it compares `height`, which for the Ursa is the lowered figure, and a berth should be judged on the smaller of the two. It would be wrong the moment a model is recorded in its extended state instead.

## Not in this plan

Letting players record what a specific berth holds — "the garage on my Carrack takes an Ursa", "the 400i bike garage takes a Nox". It needs the class ladder first, so that it is a statement on a scale rather than free text.

## Discovery Log

- **2026-09-11** Four commits refining this plan — the ladder table and the Ursa correction — were pushed to `docs/4863-berth-model` after #4865 had already merged, so they sat on a dead branch and never reached main. Recovered here. A merged PR does not stop accepting pushes; it stops delivering them.
- **2026-09-11** D1 built. Two columns turned out not to exist at all: `dock.rb` annotated a `ramp` boolean, and `ransackable_attributes` offered `station_id` — the same 2021 station era that left the 391 orphans. Neither was reachable, both are gone.
- **2026-09-11** Written after #4856. The polymorphic parent (D1) came out of a question about modules mid-review, and stopped that PR from shipping a `NOT NULL model_id` that would have had to be undone.
- **2026-09-11** The Ursa family was grouped by volume into two classes and corrected by @mortik — one class, one under-recorded height. Written down because it is the second time volume misled here, and the first draft of this plan made exactly the mistake the plan warns about.
- **2026-09-10/11** Measurements taken while building #4856. Two of them corrected earlier conclusions of mine: the dock data is healthy once the 391 orphans are excluded, and `ground` is not what distinguishes a vehicle.

## Progress

- [x] D1 — polymorphic parent, after #4864 and #4856
- [ ] Vehicle class ladder, curated
- [ ] Pads: count and size per berth
- [ ] Access: ramp / lift / tractor beam, on the label
- [ ] Curation pass on the list above
