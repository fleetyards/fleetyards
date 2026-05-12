# Event detail page — split member view from manage view

## Goal

Replace the current 3-tab event detail page (Overview / Teams / Settings) with
two focused surfaces:

1. **Member detail page** (`events/[event].vue`) — clean, compact, signup-focused.
2. **Manage page** (`events/[event]/manage.vue`, new) — admin workspace.

The edit form (`events/[event]/edit.vue`) stays as a separate page, linked from
both.

## Member detail page (`events/[event].vue`)

Layout, top to bottom — no tabs:

- Hero (unchanged) — cover, title, status badge, meta (date, location, etc.).
- Action row — kept, but only with two buttons for managers:
  - "Edit event" → `fleet-event-edit`
  - "Manage event" → `fleet-event-manage` (new)
  - Non-managers: row is hidden.
- `YourSignupPanel` / `EventSignupCta` — unchanged.
- Description + briefing — inline `Panel`, no tab wrapper. Hidden if both empty.
- Read-only slot/team overview — current "teams tab, non-edit branch" markup.

Strip:

- `FormTabs` / `FormTab`.
- `editMode` toggle and the editable branch.
- `UnassignedSignups`.
- Settings buttons (edit / manage admins / archive). Move to manage page.
- `EventActions` (publish/lock/start/etc.) — move to manage page.

Keep `isEventManager` computed only insofar as it gates the manage/edit links.

## Manage page (`events/[event]/manage.vue`, new)

Route: `:event/manage/`, name `fleet-event-manage`.

Access meta:
- `fleet:events:manage`, `fleet:events:update`, `fleet:manage`
- Plus a runtime check on `viewerEventRole` ∈ {creator, admin, moderator} so
  event-scoped admins (not fleet-level managers) can still get in.

Layout:

- Compact header (smaller than hero) — title, status badge, start date, link
  back to public detail page.
- `EventActions` — lifecycle transitions.
- Admin row: "Edit event" / "Manage event admins" / "Archive/Destroy".
- `UnassignedSignups`.
- Editable team/slot list — current "teams tab, editMode" branch, rendered
  unconditionally (no edit toggle). Add-team button.
- Sync-to-Discord etc. already inside `EventActions`, no extra wiring.

## Route changes

`app/frontend/frontend/pages/fleets/[slug]/events/routes.ts`:

- Add `fleet-event-manage` route, ordered before `:event/` catch.
- Title key: `fleets.events.manage`.

## Translations

New keys:

- `actions.fleets.events.manage` — "Manage event"
- `actions.fleets.events.viewPublic` — "View public page"
- `title.fleets.events.manage` — "Manage event"
- `headlines.fleets.events.manage` — "Manage event"

Existing keys reused: `actions.fleets.events.edit`, `manageEventTeam`,
`destroy`, `archive`, `addTeam`, `signupsLockedHint`, etc.

`labels.fleets.events.tabs.*` — leave for now in case they're reused
elsewhere; remove only if grep shows no other references.

## Out of scope

- Backend changes — none required. The existing show endpoint already returns
  `unassignedSignups`, `viewerEventRole`, etc.
- Calendar / index page tweaks — leave alone.

## Testing

- Manually verify member view (no fleet role) shows no manage controls.
- Manager view shows both Edit and Manage links.
- Visit `/manage` as non-manager → blocked by `access` meta.
- Visit `/manage` as event-only admin (not fleet manager) → allowed via
  runtime `viewerEventRole` check.
- Slot edits from manage page reflect on detail page (already wired via
  `comlink` events).
