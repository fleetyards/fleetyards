# Link item variants and compatible attachments on equipment pages

Working plan for #5978. Decisions live in the issue body. Deleted before the PR merges.

## Goal
An equipment page lists the item's other versions, a weapon's page lists the attachments that fit each of its ports (default marked), and an attachment's page lists the weapons it fits.

## Open questions
- Re-parse and `bin/scdata push`: production loaders pull the bucket, and the `hidden` change would unhide skins there before this merges. Ask before pushing.

## What changed

### Phase 1 — Parser
1. `equipment_parser.rb`: shrink `VARIANT_SUFFIX` to `_prop`/`_template` (164 skins unhidden on live 4.10.2).
1. Emit `family_key`: the shortest key prefix (3+ segments) that is a parsed record of the same `equipment_type` and `item_type` and whose name the item's keeps (around a quoted skin name, plus a colour, or with the colour swapped), else for worn gear the key without its last segment. Nil for an item with no other version. Live 4.10.2: 622 families, 549 with two or more visible members.
2. Emit `ports` for weapons: name, subtypes, `min_size`, `max_size`, `required_tags`, `port_tags` from `SItemPortDef` (Type `WeaponAttachment` only), and `default` from `SEntityComponentDefaultLoadoutParams` (`itemPortName` → `entityClassName`).
3. Emit the attachment's own `required_tags` from `AttachDef RequiredTags` (only `hmg_mag_port` uses it on live 4.10.2).
4. Parser tests with raw fixtures for a rifle, its magazine, a barrel attachment and a skin.
5. Re-parse (~6 min) so the loader tests see the new fields.

### Phase 2 — Schema and loader
1. Migration: `equipment.family_key` (string, indexed). Identity rather than a build fact, like `sc_key`.
2. `equipment_attachments` hangs off the weapon's `EquipmentBuild` (per environment and version, cascaded with the build): attachment, port name, port type (first subtype), default. Ports themselves are not stored; the loader matches from the parsed data.
3. `equipment_loader.rb`: a second pass after every row exists (as in `items_loader.rb` passes 1 and 2) that resolves `base_key` and computes matches: subtype in port subtypes, size in range, port `required_tags` ⊆ attachment tags, attachment `required_tags` ⊆ port tags. Hidden attachments are left out.
4. Loader tests against `test/fixtures/sc_data/parsed/test/equipment` (`behr_rifle_ballistic_01` + `_mag` are already there).

### Phase 3 — API
1. Member routes `versions`, `attachments` and `weapons` rather than the cached show payload, whose key cannot see another family member change. Attachments and weapons list one per family.
2. Components `EquipmentList`, `EquipmentAttachment`, `EquipmentAttachmentsList`; schema regenerated.
3. Integration test in `test/integration/api/v1/equipment_show_test.rb`.

### Phase 4 — Page
1. `pages/equipment/[slug].vue`: "Other versions", "Attachments" (one slim `MetricsCard` per port, default marked) and "Fits" sections, following the existing `craftedFrom` card with `CatalogueItemPopover` rows.
2. Locale keys in all 7 locales.
3. Spec in `[slug].spec.ts`.

## Intent Verification

- [ ] **Gallant "Boneyard" Rifle links to Gallant Rifle and its other skins** — on the live page
- [ ] **Gallant Rifle lists 1 magazine, 30 optics, 6 barrel and 10 underbarrel attachments**, with its battery marked as default (fewer if colourways are collapsed)
- [ ] **A Quell Suppressor2 page lists the energy weapons it fits and no ballistic ones**
- [ ] **A magazine is not listed as a version of its weapon**

## Key files

| File | Role |
|------|------|
| `app/lib/sc_data/parser/equipment_parser.rb` | Parses records; drops ports today; `mark_skins`, `VARIANT_SUFFIX` |
| `app/lib/sc_data/loader/equipment_loader.rb` | One-pass per-record loader |
| `app/lib/sc_data/loader/items_loader.rb` | Two-pass pattern to copy |
| `app/lib/sc_data/loader/blueprints_loader.rb` | Delete-then-insert per build pattern |
| `app/models/equipment.rb`, `app/models/equipment_build.rb` | Model and per-build facts |
| `app/controllers/api/v1/equipment_controller.rb` | Show endpoint |
| `app/views/api/v1/equipment/_equipment.jbuilder` | Cached item view |
| `app/api_components/shared/v1/schemas/equipment.rb` | Hand-written schema |
| `app/frontend/frontend/pages/equipment/[slug].vue` | Item page |
| `test/parsers/sc_data/equipment_parser_test.rb`, `test/loaders/sc_data/equipment_loader_test.rb` | Parser and loader tests |

## Not in scope (deferred)
- **Weapon skins as `appearance_modifier` items** — the game also ships skins as attachable modifiers under `weapons/appearance_modifier`; unrelated to the keyed variants here.
- **Ship weapon hardpoints** — components have their own hardpoint system.

## Discovery Log

- **2026-10-25** Key prefix alone merged distinct products: attachment keys extend other products' (Quell `arma_barrel_supp_s1_02` under Tacit, Escalate under Emod, LL sights, posters, keycards). Families now also need a matching name; a non-breaking space in the P8-SC skins needed whitespace normalising.
- **2026-10-25** Gallant on live 4.10.2 after the load: 1 magazine (default), 27 optics, 6 barrel, 5 underbarrel products; 16,616 attachment rows in all. The HMG magazine fits nothing because the HMG is a mounted gun outside the catalogue; the multi-tool's `Personal` port has no attachment of that subtype in the game files.
- **2026-10-25** Ports are only read off `WeaponPersonal` records: armour and gun cases carry `WeaponAttachment` ports for magazine pouches (487 armour records). 394 weapons and tools carry ports.
- **2026-10-25** The S3 parsed tree predates main's parser: a fresh parse also changes 338 `item_type` and 47 `equipment_type` values unrelated to this branch.
- **2026-10-25** Initial research. Live tree: 247 visible items in 77 keyed families; 3,115 worn items in 486 colourway families. Gallant port matching gives 1/30/6/10. Attachment-side `RequiredTags` appears once (`hmg_mag_port`).

## Progress
- [x] Phase 1 — Parser (re-parse and push pending)
- [x] Phase 2 — Schema and loader
- [x] Phase 3 — API
- [x] Phase 4 — Page (visual check pending a dev server)
