# SC Data: Crafting Blueprints, Counted Commodities and Contracts

**Date:** 2026-09-24 (research 2026-09-17 to 2026-09-21, against `4.10.1-live.12660092`)

This note covers how the export describes crafting recipes, where a recipe comes from, which commodities the game counts in pieces, and what a contract states. `BlueprintsParser`, `ContractsParser` and `CommoditiesParser` read these records, and `Blueprint`, `BlueprintSource`, `Commodity#counted` and `GameMission` store them. Most of the chains are GUID-only and nest to no fixed depth, and several obvious readings return plausible but wrong answers. The measurements are recorded here so that a later parser change does not rediscover them the hard way.

## Blueprint → pool → contract → org

The chain resolves only by GUID. `grep -rl "BlueprintPool\|blueprintreward" contracts/` returns zero files, so any name-based join finds nothing.

```
blueprint ──> BlueprintPoolRecord.blueprintRewards[].blueprintRecord   (weighted)
BlueprintPoolRecord.__ref ──> ContractGenerator                        (by GUID)
ContractGenerator.factionReputation ──> FactionReputation.displayName  (@*_RepUI_Name)
```

Here is one chain from end to end. The pool `crafting/blueprintrewards/blueprintmissionpools/bp_missionreward_foxwellenforcement_ambush.xml` has `__ref` `af21edb5-…`. `contracts/contractgenerator/mercenary_guild/foxwellenforcement/shipbattles/foxwellenforcement_ambush.xml` references it. That generator's `factionReputation` resolves to `factions/factionreputation/factionreputation_lawful_foxwellenforcement.xml`, whose `displayName` is `@Foxwell_RepUI_Name`.

The generator tree goes one level deeper than it looks, and there are two separate mechanisms:

```
ContractGenerator
└─ generators > ContractGeneratorHandler_*[]        6 shapes; 4 carry a pool
   ├─ factionReputation ──> FactionReputation.displayName        the org
   └─ contracts > {CareerContract|Contract}[]       one per difficulty variant
      ├─ minStanding / maxStanding ──> SReputationStandingParams.displayName
      ├─ paramOverrides > ContractStringParam[param="Title"]     the mission
      └─ …contractResults… > BlueprintRewards{chance, blueprintPool}

rox_scenarioprogress.xml                            XenoThreat, the second mechanism
└─ factionRewardTiers > … > STierReward{minPoints} > blueprintPool > Reference[]
```

|                          |                                                                                              |
| ------------------------ | -------------------------------------------------------------------------------------------- |
| pools                    | 154. 130 have a source and 24 have none (17 `ors`, 6 mission pools, 1 `48blueprints`)        |
| by mechanism             | 105 through a contract generator, 25 through the XenoThreat scenario, 0 overlap              |
| generators               | 107 files under 10 guild folders                                                             |
| source entries           | 533: 508 contract, 25 scenario                                                               |
| orgs                     | 20 named, and 9 entries left unattributed                                                    |
| blueprints with a source | **706** of 1607. 732 are in a pool, but 26 of those are only in pools that nothing hands out |
| `blueprint_sources` rows | 4,101 after deduplication, from 4,157 raw                                                    |

Traps, each one found because a measurement disagreed with the one before it:

- **Walking only `ContractGeneratorHandler_Career` finds 74 of the 105 pools.** There are six handler shapes and four of them carry a pool. `_List` accounts for most of the shortfall. Contracts also sit under `introContracts` and `PVPBountyContract`, not only `contracts`. Reading only `contracts` missed 23 contracts, including an org's first mission.
- **`contractResults` nests to no fixed depth.** A dig that assumes one depth quietly returns nothing for the others, which is exactly why walking `_Career` _looked_ like it worked. The same goes for `<difficulty>`: a fixed-path dig found none of the 2,360. Every lookup under `contractResults` has to be a recursive walk.
- **A standing carries a debug `name` next to its `displayName`.** Reading `name` first leaves every band blank, because a name like `FactionRep_Allied_Rank1` is in no localisation file.
- **The XenoThreat scenario names a `Faction`, not a `FactionReputation`.** Its own name is `@LOC_UNINITIALIZED`, and the org comes through its `factionReputationRef`.
- **A `_List` handler states no faction.** The org falls back to the generator's, but only where the generator names exactly one. Nine entries name two and stay unattributed on purpose. When the whole question is "who gives me this", a wrong org is worse than none.

A pool is named by every difficulty of every mission that hands it out, so the same org and mission arrive many times over and have to be deduplicated. The 24 pools with no source (Wikelo, ORS and similar) keep their pool name and get no org. A blueprint with no stated source has to say so explicitly on its page, because an empty section reads as a bug.

## Blueprint records

- **The 21 category refs resolve to nothing.** `blueprintcategorydatabase` lists 21 category GUIDs, and not one resolves to a record anywhere under `Data/Libs`. The GUID is still worth storing, because the fabricator whitelists in `basebuilding_interactables_itemfabricator_{standard,allianceaid}.xml` key off it and so decide _which machine_ can craft the item. It cannot be given a label, though. Group and filter by the crafted output's own category instead. The blueprint's folder path (`fpsgear/armour/combat`) was rejected because it is a second taxonomy for the same objects.
- **Quality ramps are piecewise.** Each slot ramps a named stat over quality 0→1000 through `CraftingCostContext_ResultGameplayPropertyModifiers` (`modifierAtStart`/`modifierAtEnd`), against the 24 stats in `craftedproperties/`. 1007 of the 4,289 slots ramp a stat in segments, for example 0.95→1.0 across quality 0-499 and then 1.0→1.05 across 500-1000. Store one row per segment and show the span across them. A reader that takes one range per stat reports half the gain.
- **There are two ramp kinds.** `_Linear` scales the stat (5,926 rows) and `_LinearIntegerAdditive` adds to it (598 rows). They cannot share one rendered sentence.
- **Resource refs join on `sc_key`, not `sc_ref`.** A cost names a `ResourceType` GUID, but `Commodity#sc_ref` comes from the _crate_ entity and is null for 100 of 232 commodities, Iron included. Resolve the `ResourceType` record to its `@items_commodities_*` key and join on `sc_key`. With that join, 0 cost options fail to resolve across all 37 distinct materials.
- 1606 of 1607 recipes have `blueprintName="@LOC_PLACEHOLDER"`, so the name comes from the output. Three outputs have two blueprints each, so there can be no unique index on `craftable`. The outer slot count varies: 62 recipes have 1 slot, 442 have 2, 1072 have 3 and 31 have 4. Slot labels (`@crafting_ui_slotname_*`) resolve only through the `,P`-stripped, downcased localisation index (`BaseParser#localize`). An exact lookup misses all 73.
- The tree also has `qualitydistribution/` (22) and `qualityquantization/` (63), which describe how a resource's quality rolls. Nothing reads them. `globalgenericdismantle.xml` is one global rule (efficiency 0.5, 15s), not a recipe.

## Counted commodities

A recipe states cost in two ways. `CraftingCost_Resource` reads SCU from `quantity.SStandardCargoUnit.standardCargoUnits`. `CraftingCost_Item` reads a bare `quantity`, which is a count of pieces. Across all 4,289 cost options, 26 materials are always bulk, 11 are always counted, and none is used both ways. So the unit is a property of the commodity, not of the slot. `commodity_type` does not predict it: minerals split into 9 counted and 10 bulk.

**`generateRandomQuality` on the commodity's `SCItemResourceContainer` is what makes a commodity counted.** Every commodity whose container declares `generateRandomQuality="1"` is counted, and every commodity without it is bulk. Read from whichever entity carries the container, the flag agrees with the recipes on all 37 materials. It covers **56 of 232** commodities in total. The other 45 are harvestables that no recipe asks for (herbs, eggs, horns, the vice drugs), all carried a piece at a time. That extends the rule rather than breaking it.

Rejected signals:

- `SMicroCargoUnit` capacity, `mutabilityLevel` and the entity path all correlate perfectly on this build. They are consequences of the same fact, not the fact itself. The counted materials are exactly those whose pieces each roll their own quality, which is why crafting counts them and why the quality ramp applies per piece.
- `BlueprintCostOption#cost_type` would be circular. It only knows the 37 commodities that some recipe consumes, and an inventory has to answer for all 232.

**A counted container's capacity is the volume of one piece.** Hadanite is `SMicroCargoUnit microSCU="1000"`, which is 0.001 SCU. All 56 counted commodities declare exactly one such capacity, and no bulk commodity declares one. A bulk commodity's "piece" is a crate sold in seven sizes from 1 to 32 SCU, so it has no single figure. Read `piece_volume` off the counted container and nowhere else, because every commodity is also sold in crates that declare their own capacity. Without it, a position recorded in pieces falls into `stock_volume`'s unmeasured bucket and the hold-fill figure silently understates itself.

## Contracts (`GameMission`)

The survey found 2,536 contracts across 107 generators and 272 handlers. Contract GUIDs are unique, 2,536 of 2,536.

- **The export states a payout for only 8 of 2,536 contracts.** 2,352 carry `ContractResult_CalculatedReward`, an empty element whose amount the game computes at runtime. There is no payout table, no currency-per-difficulty curve and no scalar anywhere in the tree. What the files do state is 2,226 reputation awards, 333 item awards, badges and 786 blueprint-pool contracts.
- **The key is `sc_key = "#{generator_key}_#{debug_name}".downcase`.** That gives 2,520 distinct keys for the 2,533 contracts that have a `debugName`, with 13 colliding pairs. **Every** member of a colliding base gets the first 8 characters of its GUID as a suffix, counted before any key is handed out. A positional counter, or suffixing only the second contract walked, fails because `Dir.glob` fixes no order between builds, so the two contracts' history would swap. The 3 contracts with no `debugName` use the whole GUID. `debugName` is free text, and 64 of them carry a space, bracket, dash or slash, so the key cannot contain `/`. `ParsedCheck` globs a catalogue folder flat while the loader globs `**/*.json`, so a nested file would load fine and still count as zero against the floor. The slug comes from `sc_key`, never from the title: 45 titles are shared by more than one org.
- **Titles and descriptions contain runtime placeholders.** 902 of 2,472 resolving titles and 2,344 of 2,475 descriptions carry a `~mission(Location|Address)`-style span that the game fills in. Only 131 descriptions are literal. Deleting the spans breaks the sentence ("head on over to , destroy a few things"), so they are rendered as muted inline tokens named after the parameter. Descriptions also carry the game's `<EM4>…</EM4>` emphasis markup, 3,567 times across the localisation file, and 4 of those tags never close. Showing the markup as text is noise and passing it through as HTML is an injection risk, so one renderer handles both.
- **Release gates.** A contract flagged `notForRelease` (348) or `workInProgress` (21) is marked `released: false`. The public list and the public detail page apply that as one shared predicate, so no link can lead to a page the list refuses to show.
- 25 orgs are named, and 362 contracts have no org. `contracts/contracttemplates` has 486 files of objectives, deadlines and partial-reward multipliers, and nothing reads them. Mission locations resolve through resource tags (`MissionPropertyValue_Location`), which would need a walk of its own.
