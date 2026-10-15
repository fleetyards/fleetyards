# Admin form for a module's slot on a hull

Working plan for #5722. Decisions live in the issue body. Deleted before the PR merges.

## Goal
An admin can see and set or clear each module's slot on a hull from the admin model modules page.

## What changed

### Phase 1 — API
1. `link` (and `create` with a model) set the slot whenever `slot` is sent; a blank value clears it.
2. The admin model payload lists the hull's game-file module slots (`moduleSlots`).

### Phase 2 — Admin page
1. Each module row shows its slot on this hull, or that it has none.
2. The edit form has a slot field; the hull's game-file slots are listed beside it.

## Intent Verification

- [ ] **Shown** — the modules page shows each module's slot on this hull
- [ ] **Set and cleared** — saving a slot sets it; saving it empty clears it
- [ ] **Not overwritten** — no load rewrites an existing link's slot (see the issue's decision)

## Key files

| File | Role |
|------|------|
| `app/controllers/admin/api/v1/model_modules_controller.rb` | `link`, `create` |
| `app/views/admin/api/v1/models/*.jbuilder`, `app/api_components/admin/v1/schemas/models/model_extended.rb` | `moduleSlots` |
| `app/frontend/admin/pages/models/[id]/edit/modules.vue` | the page |

## Discovery Log

- **2026-10-15** The admin module payload already carries `moduleHardpoints[].slot`. `ModulesImporter` sets a slot only on creating a link.

## Progress
- [ ] Phase 1 — API
- [ ] Phase 2 — Admin page
