# Dressing room: hold a rifle in the lowered pose that fits the worn armour

Working plan for #6255. Decisions live in the issue body. Deleted before the PR merges.

## Goal

A held rifle uses the export's lowered hold clip for the worn core's armour weight, so it stays out of the armour.

## What changed

### Phase 1 — Import and serve the hold poses
1. `CharacterStore#characters` passes `holdPoses` through.
2. `CharacterBodiesImportJob` keeps the well-formed `rifleLowered` entries in a new `hold_poses` jsonb column, as `{armor_weight, clip}` with `none` stored as a null weight.
3. The bodies payload serves `holdPoses`, described in the `CharacterBody` schema. The generated client is regenerated.

### Phase 2 — Pick the clip
1. `dressingRoom.ts` picks the lowered clip from the body's `holdPoses` for the core's `subType`. A worn core with a missing or unlisted weight, or one whose clip the body lacks, gets the `Heavy` clip. With no core, or no hold poses at all, it uses `hold_rifle_lowered`.
2. `dressing-room.vue` uses it for the automatic pose. A pose in the address still wins.

## Intent Verification

- [ ] The Antium core on the male body holds a CQ7 out of the chest plate.
- [ ] No core, or an undersuit only: `hold_rifle_lowered`.
- [ ] `?pose=` still overrides.

## Key files

| File | Role |
|------|------|
| `app/lib/sc_data/character_store.rb` | Reads the character index |
| `app/jobs/sc_data/character_bodies_import_job.rb` | Stores a body's clips and hand data |
| `app/views/api/v1/character_bodies/index.jbuilder` | Bodies payload |
| `app/api_components/v1/schemas/dressing_room/character_body.rb` | Payload schema |
| `app/frontend/frontend/utils/dressingRoom.ts` | Hold clip choice |
| `app/frontend/frontend/pages/tools/dressing-room.vue` | Automatic pose |

## Discovery Log

- **2026-11-09** The export's `holdPoses` is `{"rifleLowered": {"none", "Light", "Medium", "Heavy"}, "rifleReady": {"any"}, …}`, confirmed verbatim on the export issue.
- **2026-11-09** `Jbuilder.ignore_nil` drops the null weight; the view merges it in, as `locations/_link` does.
- **2026-11-09** Equipment `subType` already holds the torso's `AttachDef.SubType` (Antium core `Heavy`, Aril core `Medium`), so the export's `armor_weights.json` is not needed.

## Progress
- [x] Phase 1
- [x] Phase 2
