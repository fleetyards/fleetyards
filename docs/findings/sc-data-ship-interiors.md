# SC Data: Ship Interiors (Beds, Weapon Racks, Lockers, Jump Seats)

**Date:** 2026-10-16 (measured on 4.10.2-live.12913470)

What a ship's rooms hold is placed furniture, not loadout. No vehicle record points at it. Since the export ships `derived/shiprooms.json`, it can be read per vehicle. This note records how the export reads it, the traps found in turning it into figures, and what is left for jump seats. Read it before changing `ScData::Parser::ShipInteriors`, or before building the jump-seat follow-up.

## The source

`derived/shiprooms.json` is written by the exporter from the object containers in `Data.p4k`, which the raw tree does not carry. It has three sections:

- `vehicles`: per vehicle record, the rooms it brings (`container`, `via`) and per room the usable entities placed in it, both by kind (`contents`) and by class name (`classes`). There are 1139 records.
- `items`: per loadout item that brings rooms of its own, for example a module. The Apollo's medical modules read their beds from here.
- `stations`: seat ports in the loadout. They are missing for 671 of the 1139 vehicles, so they are not used.

The export counts items, not what they hold. A bunk is one `bed`, and a 19-slot armoury is one `weapon_rack`. The berths and slots come from the usable's own record, under `entities/scitem/usables/` or `entities/scitem/ships/usableitems/`. Five bed classes live only in the second.

## Telling furniture apart

The export classifies a usable by its `SActorUsableParams` `fragmentTag` (`bed`, `weapon_rack`, `locker`). A medical bed is the exception: it is told apart by `MedBedComponentParams`. Fleetyards follows the same rule. With it, the per-kind counts for all 1139 vehicles match the export's `totals` exactly.

Classifying by class name looks equivalent and is not. Both of these were found in review:

- `Cargo_Slot_*` usables are weapon racks by tag. They are the Aurora Mk2's and the Lynx's racks.
- Medical beds are `Bed_*` classes too. Counting them as crew beds put the Clipper at 2 beds instead of 1.

## Beds are berths

A berth is an alignment slot whose `helperName` is `$anchor_bed`, `$anchor_bed_top`, `$anchor_bed_left` or `$anchor_bed_right`. So a bunk is 2 and a double bed is 2. The `_tv` anchors are a second pose on a berth that already has its own. Matching `Name="$anchor_bed"` in the XML finds nothing, because the attribute is `helperName`. Counting mattress slots fails too: 8 bed records have none. With berths, the Andromeda GS has 4 beds, where the export's item count says 2.

## Weapon-rack slots

Every `SItemPortDef` in a rack's `SItemPortContainerComponentParams` is a slot, whatever its type. Each slot keeps:

- its types and sub-types, for example `WeaponPersonal/Gadget` for tractor beams and multitools, or `Cargo`, `Misc`, `Char_Armor_*` and `Container/Box` on the Ironclad's smuggling stash
- its size range (all 886 rack ports in this build state both sizes)
- its `RequiredPortTags`

Only the required tags pin a slot to one kind of item: `multitool` (Clipper), `medical_injection` and `grenade` (ATLS IKTI). A port *name* such as `$IP_tractor_01` carries no restriction.

## Pre-rework interiors are empty

An interior from before its ship's rework places none of this furniture. The Freelancer, Starfarer, Carrack (no racks) and the legacy Constellation records come back empty, so they show nothing rather than zero. A build's nil is final for these facts. If the column showed through, it would carry another environment's interior onto a pre-rework build.

Reworked ships have two records, for example `RSI_Constellation_Andromeda` and `RSI_Constellation_Andromeda_GS`. Production already resolves the Constellations to the `_GS` records: their mass and hull health match.

## Jump seats

These supersede [scdata-jumpseats-missing.md](scdata-jumpseats-missing.md), which predates the rooms export. Per-ship counts *are* now in the export. What is still missing is a tag: a jump seat is `fragmentTag="seat"` like any bench, so it can only be told apart by class name. The export's own `jump_seat` kind is name-based and counts two toilets (`Seat_Jump_ORIG_300i_Bathroom_Toilet`, `Seat_Jump_MISC_Reliant_Toilet`). The names that carry passengers are:

- `Seat_Jump_*`
- `*Jumpseat*`
- `Seat_Chair_Anim_DropShipPassenger_Template`
- `Standing_Harness_*`

Examples: Cutlass Black 6, Cutlass Steel 18, Vanguard Hoplite 6, Redeemer 4, Ironclad Assault 24, Prowler 16 harnesses.

Jump seats are wanted for fleet event planning as well as for the ship page: as passenger capacity beside an event ship's crew positions, and as a filter next to `min_crew`.
