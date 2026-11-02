# Dressing room: put worn equipment together on a body, with share links and saved outfits

Working plan for #6106. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A dressing room page where anyone can pick a body and one item per worn slot, see them together in the holo viewer, share the outfit by link, and, when signed in, save named outfits.

## Open questions
- **`characters/index.json` shape.** Not published yet. Assumed to follow `item-views/`: `{"characters": {"male": {"files": "<md5>", "updatedAt": …}}}`, with `male/files.json` listing `body.glb`, `animations.glb`. Adjust `ScData::CharacterStore#characters` once the first export lands.

## What changed

### Phase 1 — Base bodies
1. Migration + model `CharacterBody` (uuid, `key` string unique — "male" now, "female" later — `has_one_attached :body`, `files_digest` to skip unchanged listings).
2. `ScData::CharacterStore < RenderStore` (prefix `characters`) and `ScData::CharacterBodiesImportJob`, run alongside the item-views import; `body.glb` only, `animations.glb` deferred.
3. `GET /character-bodies` (public, `PublicBaseController`), with jbuilder and an `api_components` schema.

### Phase 2 — Saved outfits API
1. Migration + models `Outfit` (uuid, `user_id`, `name` unique per user, `gender`) and `OutfitItem` (`outfit_id`, `slot` enum reusing `Equipment.slots`, `equipment_id`, unique `[outfit_id, slot]`). Items are written in one go from an `items=` setter, as `VehicleLoadout#item_list=` does.
2. `OutfitsController` CRUD (`< Api::BaseController`, scoped to `current_resource_owner`), `OutfitPolicy` copied from `HangarPlanPolicy`, routes file `config/routes/api/outfits_routes.rb`.
3. Validation: the item's `slot` must match the outfit slot; an item may be retired.
4. Schemas `v1/schemas/outfits/*`, inputs `outfit_input.rb`; integration tests one per action; `bin/generate-schema`.
5. Feature flag `dressing_room` in `config/feature_flags.yml` (`bin/feature-flags validate` + `sync`), gating the controller and the route.

### Phase 3 — HoloViewer for a character
1. Body as the root `path`, every piece as a mount at identity — the export rig places helmets too.
2. Fit the camera and near plane after mounts attach, counting mounts in `modelReach`.
3. Let textured mounts keep their own materials instead of `setMaterials` forcing clay.
5. Count mount sizes in the low-power confirmation total.
6. Specs for each, and no regression in the loadout preview.

### Phase 4 — Dressing room page
0. Male body only; no body switch until a second body exists.
1. Route `tools-dressing-room` at `/tools/dressing-room/`, `meta.feature: DRESSING_ROOM`, nav entry in `TOOLS_ITEMS`, titles in `nav.*` and `title.*`.
2. URL state: `?undersuit=<slug>&torso=<slug>&arms=…&legs=…&helmet=…&backpack=…`, synced with `router.replace` as `useHoloQuery` does; single values normalised with `[x].flat()`.
3. Slot pickers built on `Logistics/ItemPicker` with `slotIn` fixed per slot and `equipmentTypeIn: armor, undersuit`.
4. Per item detail via `useEquipmentItem(slug)`; holo chosen like `useItemHolo` (textured, then clay); items without a holo listed and marked "not shown in 3D".
5. Outfit list: save, rename, update, delete for signed-in users; "Copy link" for everyone.
7. Phone layout following the ship holo's phone behaviour.
8. Translations in all seven locales by hand.

## Intent Verification

- [ ] **Picking a body and items draws them together** — core, arms and legs line up on the body; the helmet sits on the collar (placed by the export rig)
- [ ] **Textured first, clay fallback** — an item with only a clay holo is drawn in clay; one with neither is listed but not drawn
- [ ] **Share link** — copying the URL in a private window opens the same outfit without signing in
- [ ] **Saved outfits** — signed-in user can save, list, rename, update and delete; another user gets 404 on someone else's outfit
- [ ] **Flag** — with `dressing_room` off, the page 404s and the API returns 403
- [ ] **Loadout preview unchanged** — the ship loadout preview still frames and paints as before

## Key files

| File | Role |
|------|------|
| `app/models/hangar_plan.rb`, `app/controllers/api/v1/hangar_plans_controller.rb`, `app/policies/hangar_plan_policy.rb` | Template for a user-owned named record |
| `app/models/vehicle_loadout.rb` | `item_list=` bulk write of child rows |
| `app/models/equipment.rb:243` | `slot` enum (torso is the core) |
| `app/jobs/sc_data/item_views_import_job.rb` | Item-views bucket import, where the bodies come in |
| `app/frontend/shared/components/HoloViewer/index.vue`, `Model/index.vue`, `mounts.ts` | Viewer, camera fit, mounts |
| `app/frontend/frontend/composables/useItemHolo.ts` | Textured vs clay choice and fallback |
| `app/frontend/frontend/components/Logistics/ItemPicker/index.vue` | Slot-filtered equipment picker |
| `app/frontend/frontend/pages/tools/routes.ts`, `components/Navigation/entries.ts` | Route and nav entry |
| `config/feature_flags.yml` | New flag |

## Not in scope (deferred)
- **Clothing slots** (hat, shirt, jacket, …): no holos yet. Becomes its own issue before the PR merges.
- **Building outfits from owned items**: rejected for now, see the issue.
- **Rigged item holos and hide masks**: the static holos are enough for a rest-pose figure.
- **Female body**: comes later from the export.
- **Backpack / core compatibility hint**: `core_compatibility` and `backpack_compatibility` need their exact meaning confirmed against the game files before the page warns about a pairing.
- **Poses from `animations.glb`**: a rest pose first.

## Discovery Log

- **2026-11-02** Built all four phases. Zoom limits left alone: item holos down to 0.3 m already work in the viewer. Without a published body the figure roots on its first piece, undersuit first; the pieces share a frame, so nothing moves. A painted piece that fails loads its clay holo. Backpack/core compatibility hint not built.
- **2026-11-02** Decisions recorded in the issue: `characters/` bucket prefix, helmets placed by the rig, male only, no share token, Tools placement. `characters/` not in the bucket yet.
- **2026-11-02** Initial research and plan creation. Measured production GLBs: core/arms/legs share a body frame (feet at y=0), helmets are neck-local; clay and textured holos share frames. Coverage: helmet/torso/arms/legs ~98%, undersuit/backpack 0% today.

## Progress
- [x] Phase 1 — Base bodies
- [x] Phase 2 — Saved outfits API
- [x] Phase 3 — HoloViewer for a character
- [x] Phase 4 — Dressing room page
- [ ] Live check in the running app once a body is published
