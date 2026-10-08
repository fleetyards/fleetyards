# Drop the legacy item_type/component_class columns from components

Working plan for #5163. Decisions live in the issue body. Deleted before the PR merges.

## Goal

Nothing reads or writes `item_type`/`component_class` on `components` or `component_builds`, and both columns plus the two `component_builds` indexes are gone.

## Open questions

- None. Public surface is removed; the drop ships as a second, stacked PR (see the issue body).

## What changed

### Phase 1: Code stops reading and writing
1. Remove `item_type`/`component_class` from `ComponentBuild::FACTS` and `FILTERABLE`, `Component` paper_trail `only:` and `ransackable_attributes`.
2. Delete `Component.item_types`, `component_classes`, `item_type_filters`, `class_filters`, `item_type_label` and `component_class_label`.
3. Admin: remove the `class_filters`/`item_type_filters` actions and routes, the params and query permits, and the jbuilder fields. Add `category` (and `component_type`/`sub_type`) to the admin view, input, query, filter form, list column and create/edit forms. This also fixes `componentType: props.component.type`, which currently reads `item_type`.
4. Delete `ComponentClassSelect` and `ComponentItemTypeSelect` and add a category select. The public `/filters/components/categories` endpoint already exists.
5. Public API: remove the `classes`/`item-types` filter endpoints, the `itemTypeIn`/`componentClassIn` params, `Component.class` and `ComponentClassEnum`, with an oasdiff override.
6. Remove the locale keys from all 7 locales: frontend labels and placeholders, plus Rails `activerecord`, `helpers` and `filter.component.class`.
7. Tests: switch the `component_test.rb` fact tests and the `base_loader_apply_build_test.rb` case to `category`, delete the four filter integration tests, and clean the factories.
8. Regenerate the swagger, asyncapi and generated clients.
9. Add `self.ignored_columns` for both columns on both models.

### Phase 2: Drop the columns
1. Write a migration that removes both columns from both tables, plus `index_component_builds_on_environment_and_{item_type,component_class}`.
2. `db/data/20260827150100_backfill_component_builds.rb` keeps a frozen list that names both columns. On a fresh DB every schema migration runs first, so remove them from that list.
3. Remove `ignored_columns` and regenerate the annotations.

## Intent Verification

- [ ] **Admin uses category.** The admin component list, filter and forms show and edit `category`, and nothing shows class or item type.
- [ ] **No readers.** `grep` finds no component `item_type`/`component_class` outside historical migrations.
- [ ] **Loaders don't write them.** This already holds: `items_loader.rb` writes `category`, `component_type` and `component_sub_type`.
- [ ] **Columns and indexes gone.** `db/schema.rb` has neither column on either table, and no index on them.

## Key files

| File | Role |
|------|------|
| `app/models/component.rb`, `app/models/component_build.rb` | FACTS/FILTERABLE, legacy class methods |
| `app/controllers/admin/api/v1/components_controller.rb` | Admin filters and params |
| `app/views/admin/api/v1/components/_base.jbuilder` | Admin payload (no `category` today) |
| `app/api_components/admin/v1/schemas/{inputs,queries}/component_*.rb` | Admin schema |
| `app/api_components/shared/v1/schemas/{component,enums/component_class_enum}.rb` | Shared `class` field |
| `app/controllers/api/v1/{components,filters/components}_controller.rb`, `config/routes/api/components_routes.rb` | Deprecated public surface |
| `app/frontend/admin/pages/components/**`, `app/frontend/admin/components/{Components/FilterForm,base/Component*Select}` | Admin UI |
| `db/data/20260827150100_backfill_component_builds.rb` | Frozen column list |

## Not in scope (deferred)

- None yet.

## Discovery Log

- **2026-10-08** Phase 1: oasdiff 1.18.1 flags the removed `class` property (17 public warnings) and the two admin filter paths (errors). Both went into the ignore lists, and 8 runs came back stable. The public filter paths and params were already deprecated, so they are not flagged.
- **2026-10-08** Initial research. The loaders already stopped writing both columns, `category` exists on both tables, and admin exposes none of `category`, `component_type` or `sub_type`.

## Progress

- [x] Phase 1 (PR 1)
- [ ] Phase 2
