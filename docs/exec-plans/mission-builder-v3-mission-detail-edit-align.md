# Align mission detail/edit pages with recent event refactors

## Why

The event surfaces were restructured on this branch:

- Detail page mounts an `EventAdminActions` component (Edit + dots dropdown) into
  the breadcrumbs `#actions` slot (commit `ee9e913c5`).
- Edit page was split into a parent `edit.vue` layout with `TabNavView` and three
  nested per-tab routes (`index`/basic, `description`, `teams`), each owning its
  own `useForm` and submitting partial updates via `EventEditFormShell`
  (commit `5bf6f2be5`, mirrors admin-model-edit).

Mission detail/edit still uses the older patterns:

- Mission detail teleports a flat row of buttons (Edit/Archive/Unarchive/Destroy/
  Spawn Event) into `#header-right`.
- Mission edit is a single page rendering `MissionForm` with in-page `FormTabs`.

Bring missions in line so the two feature areas stay structurally identical.

## Plan

### Detail page

1. New `MissionAdminActions` component (mirrors `EventAdminActions`):
   - `Edit` button on the left.
   - `BtnDropdown` on the right with: Spawn Event (when allowed and not
     archived), Unarchive (when archived), Archive (when not archived), Destroy
     (when archived).
2. Update `[mission].vue`:
   - Drop the `Teleport to #header-right` block and all its handlers (delete,
     archive, unarchive, destroy, spawn) — move them into `MissionAdminActions`.
   - Mount `MissionAdminActions` via the `BreadCrumbs` `#actions` slot.
   - Optionally promote the cover/hero/description block to a `Panel` wrapper to
     match the event detail hero look. Keep as-is for now if it would balloon
     scope; the action move is the load-bearing change.

### Edit page

1. New `MissionEditFormShell` (mirrors `EventEditFormShell`):
   - Wraps `useUpdateFleetMission` mutation.
   - Renders `FormActions` (submit, cancel back to `fleet-mission` detail).
   - Surfaces validation errors via `transformErrors` + `setErrors`.
2. Replace `[mission]/edit.vue` (single page) with:
   - `[mission]/edit.vue` — parent layout with `BreadCrumbs` + `TabNavView`.
   - `[mission]/edit/index.vue` — basic tab (title, category, scenario).
   - `[mission]/edit/description.vue` — description, cover-image preset grid,
     cover-image file input.
   - `[mission]/edit/teams.vue` — teams list with add/edit/sortable cards.
   - `[mission]/edit/routes.ts` — the three child routes; `fleet-mission-edit`
     resolves to the basic tab so existing links keep working.
3. Update `missions/routes.ts` to nest the edit children with
   `redirect: { name: editRoutes[0].name }`.
4. Leave `MissionForm` (the single-form component) in place — it is still used
   by `missions/new.vue`. Once the edit page is split it stops being shared,
   which is fine; the create flow is one form on one page.

### Translations

Add nested keys to mirror events:

- `headlines.fleets.missions.editBasic` / `.editDescription` / `.editTeams`
- `nav.fleets.missions.edit.basic` / `.description` / `.teams`
- `title.fleets.missions.edit` becomes a nested object with `basic`,
  `description`, `teams` (the existing flat `"edit": "%{fleet} Mission"` string
  is replaced).

## Out of scope

- `missions/new.vue` keeps `MissionForm`; no per-tab routes for create.
- No backend changes — `useUpdateFleetMission` already accepts partial payloads.
- The mission detail page's `EventPanel` "spawned events" section is unchanged.
