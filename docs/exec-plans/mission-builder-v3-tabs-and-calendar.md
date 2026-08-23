# Mission Builder v3 — Tabbed Forms & Calendar Refresh

Follow-up UX pass on top of the [Events & Calendar phase](mission-builder-v3-events.md). The data model, lifecycle, signups and notifications have already shipped. This plan covers three frontend tracks:

1. A reusable **tabbed-form shell** for events, missions, and admin forms (currently no tab nav exists in the codebase)
2. **Form consolidation** — the Mission form and Event form share a layout, with the event form adding scheduling/visibility on top
3. **Calendar refresh** — switch the in-house grid to **`@event-calendar/core`** (vkurko), add week view, fix box-resize on populated days, render cover images, and allow in-place event creation

This **supersedes** the "in-house minimal calendar" decision in the events plan. `@event-calendar/core` is MIT-licensed (verified at https://github.com/vkurko/calendar), ~35 KB Brotli with modular per-view imports, and exposes a FullCalendar-compatible API. iCal export and recurring events stay backend-only (already covered by the events plan).

## Scope summary

| Track | Status | Touches |
|---|---|---|
| Tabbed form shell | 🔜 this plan | new `FormTabs` shared component |
| Mission/Event form consolidation | 🔜 this plan | `EventForm`, `MissionModal` → `MissionForm` (dedicated page), shared sub-sections |
| Role-gated event detail | 🔜 this plan | `pages/fleets/[slug]/events/[event].vue` reorganised into the same tabbed shell |
| Calendar migration | 🔜 this plan | `CalendarGrid` replaced with `@event-calendar/core` wrapper; new week view; cover images on events; in-place create |
| Panel-background reuse | 🔜 this plan | tab content wrapped in `Panel` for readable backgrounds |
| Settings page refactor | 🔜 this plan | split Discord into own tab; expose fleet-event types in user settings; remove dead options |

Out of scope: the fleet-event data model is settled — no event-related migrations or API changes are expected. The settings refactor may introduce one small migration if any unused column is confirmed dead and removed.

## 1. Tabbed form shell

### Component design

New shared component at `app/frontend/shared/components/base/FormTabs/`:

```
FormTabs/
  index.vue          # tab nav + content slot host
  FormTab.vue        # single tab (slot child, declarative API)
  types.ts           # FormTabsProps, FormTabConfig
```

**Declarative slot API** — preferred over config-driven, matches the existing `Panel` family pattern:

```vue
<FormTabs v-model:active-tab="activeTab">
  <FormTab id="basic" :label="t('events.tabs.basic')" :invalid="hasErrors(['title','startsAt'])">
    <PanelBody>...basic info fields...</PanelBody>
  </FormTab>
  <FormTab id="description" :label="t('events.tabs.description')">
    <PanelBody>...description + cover...</PanelBody>
  </FormTab>
  <FormTab id="teams" v-if="isEdit" :label="t('events.tabs.teams')">
    <PanelBody>...teams & ships...</PanelBody>
  </FormTab>
</FormTabs>
```

**Why slot-based:** vee-validate field state needs to live inside the parent form, not be pushed through tab config. The slot pattern keeps validation context clean and lets each tab access the same `useForm()` instance.

### Required behaviours

- **Works for new records** — current `EventForm` survey shows no tab tech exists; the user explicitly called this out. The `Teams & Ships` tab is hidden in `:create` mode (no event ID yet to attach teams to) and revealed after the first save. Other tabs render in both modes.
- **Per-tab error indicator** — when a field inside an inactive tab fails validation, the tab nav shows an error dot. This is critical because vee-validate scrolls to the first error and a hidden field would otherwise be invisible.
- **URL-syncable active tab** — `?tab=teams` in the URL drives `activeTab` so deep links and browser back/forward work, and so the admin "Manage teams" button can deep-link from the event detail.
- **Keyboard nav** — left/right arrows on the tab strip, `Home`/`End` to jump, Enter activates. Standard ARIA tabs role.
- **Mobile fallback** — under `$desktop-breakpoint` (992px), the vertical sidebar collapses to a horizontal scroll-tab strip above the content. This matches the existing `TabNavView` (settings page) pattern; an accordion fallback was considered but rejected to preserve visual consistency with the rest of the app.

### Reuse target: admin UI

The admin pages (`app/frontend/admin/pages/models/create.vue` etc.) currently use single-page linear forms. The `FormTabs` component is shared (`shared/components/base/`) so it can be adopted by the admin app without duplication. Not part of this plan's deliverables — but the API needs to support that use case. Concretely, that means **no fleet-domain assumptions** in the component; pure tab nav.

## 2. Form consolidation — Mission + Event

### Current state

- **EventForm** — `app/frontend/frontend/components/Fleets/Events/EventForm/index.vue` (595 lines, full-page, 17 fields)
- **MissionModal** — `app/frontend/frontend/components/Fleets/Missions/MissionModal/index.vue` (~150 lines, modal, 6 fields)

The mission form is the strict subset. Per the user's standing preference (forms-with-many-fields-go-on-a-page), the Mission form moves to a dedicated page too: `pages/fleets/[slug]/missions/new.vue` and `.../[mission]/edit.vue`. The modal becomes a thin "create from mission" picker only — it stops being a primary form surface.

### Tab structure

Three tabs, applied to **both** Mission and Event forms (Event tabs include extra fields):

| Tab | Mission fields | Event fields (add) |
|---|---|---|
| **Basic Info** | title, category, scenario | + starts_at, ends_at, timezone, max_attendees, visibility, location, meetup_location, auto-lock toggle + minutes |
| **Description & Cover** | description, cover_image_preset, custom cover upload | + briefing (markdown) |
| **Teams & Ships** | team list, ship list, slot config | (same — snapshotted from mission on spawn) |

The "Basic Info" tab gets bigger for events but keeps the same column grid the existing form uses (col-12 / col-md-6). No need for sub-sections inside tabs — the divider-based grouping the EventForm currently uses can simply disappear once tabs do that work.

### Shared sub-components

Extract from `EventForm` so `MissionForm` can reuse:

- `EventForm/sections/BasicInfoSection.vue` — accepts a `mode: "mission" | "event"` prop; renders the appropriate field subset
- `EventForm/sections/DescriptionSection.vue` — description + cover preset grid + custom upload
- `EventForm/sections/TeamsSection.vue` — wraps the existing team/ship/slot CRUD components

`EventForm/index.vue` and `MissionForm/index.vue` become thin shells that mount `FormTabs` and the sections they need.

## 3. Role-gated event detail

User requirement, verbatim:
> Event Admins/Creators should have more info available including the ability to move users to slots and manage the event itself. Regular Users should only see other attendees and see which slot they are on and their own status.

### Approach

Repurpose the **same tabbed shell** for the detail page (`pages/fleets/[slug]/events/[event].vue`). Tabs gate by role using the existing `viewerEventRole` + `isEventManager` / `isEventCreator` computeds (lines 67–98 of the current detail page).

| Tab | Member sees | Manager sees |
|---|---|---|
| **Overview** | title, date, location, status, briefing, own signup status | + edit-in-place fields (links to edit page if heavy) |
| **Attendees** | list with own slot highlighted | + drag/drop to reassign signups, kick action |
| **Teams & Ships** | structure + which slots are filled | + slot CRUD, team CRUD |
| **Activity** (manager only) | — | lifecycle transitions, audit log, cancel |
| **Settings** (manager only) | — | visibility, auto-lock, archive, delete |

The current detail page already has all the role logic — this refactor lays it out in tabs instead of in stacked v-if sections. Edit page (`/edit`) stays a separate route for now (deep-link friendly) but renders the same tabs so the UX feels continuous.

### Removing the edit route — defer

Tempting to collapse `/edit` into the detail page with edit-on-tab. Don't do it in this pass — the current API mutations are scattered (separate update vs. team-update vs. slot-update) and inline edit means more conditional rendering. Leave for a later cleanup once we see how managers use the tabs.

## 4. Calendar refresh — `@event-calendar/core`

### Why this library

- **MIT licensed** (https://github.com/vkurko/calendar) — no copyleft, safe for monetization
- **~35 KB Brotli** with **modular per-view imports** — only ship what we use (`DayGrid` + `TimeGrid`)
- **FullCalendar-compatible API** — most-used calendar API in JS; lowest swap-cost if we ever migrate
- **CSS Grid-based DOM** — modern, predictable layout. Directly fixes the "event-populated day resizes the row" bug, which stems from the current in-house grid using implicit row sizing
- **Drag-create / drag-move / resize built in**, plus `eventContent` callback for custom event rendering (cover image overlays)
- Zero runtime deps; recent v5 release (Apr 2026) → actively maintained

iCal export and recurring events are deliberately **not** features we lean on this library for — both stay backend (per the events plan: server-side iCal feed, recurring deferred to Phase D).

### Migration plan

1. Add `@event-calendar/core` as a frontend dep via **pnpm** (per project standard). Plugins imported as named members (`DayGrid`, `TimeGrid`).
2. Replace `app/frontend/frontend/components/Fleets/Events/CalendarGrid/index.vue` with a wrapper:
   ```
   CalendarGrid/
     index.vue              # mounts the calendar, exposes events prop, emits create/click
     useCalendarEvents.ts   # transforms FleetEvent[] → calendar event objects
     EventChip.vue          # rendered into eventContent — cover bg + title + time
     types.d.ts             # local type shims (library ships no first-party types)
   ```
3. Wire the calendar config:
   - Plugins: `[DayGrid, TimeGrid]`
   - `view`: `dayGridMonth` (default), with header buttons to switch to `timeGridWeek`
   - `events`: from `useCalendarEvents` mapper
   - `eventContent`: returns DOM nodes from `EventChip` rendering
   - `dateClick` + `select` → emit `create-event` to the page with prefilled `starts_at`
   - `eventClick` → navigate to event detail page (no in-place edit)
4. Cover images on events — `eventContent` returns a chip element with the cover as a CSS background, title + start time overlaid. Fallback to category colour when no cover.
5. Click empty day/slot → emit `create-event` with prefilled `starts_at` → opens the new tabbed event form **modal** (keeps user in calendar context) prefilled from query.
6. Box-resize bug auto-fixed — the new library uses CSS Grid with fixed cell heights and ellipsizes overflow into a "+N more" link. No manual patching of the in-house grid.

### TypeScript shim

Library has no first-party `.d.ts`. Add a minimal `types.d.ts` declaring `@event-calendar/core` with the option/event shapes we actually consume. Lightweight — start with `any`-typed plugin imports and tighten as the wrapper grows.

### Box-resize bug — root cause

Current `CalendarGrid/index.vue` uses CSS grid with implicit row sizes; rows expand to fit tallest cell. Fix is structural — the new library uses fixed-height cells with overflow ellipsing. No manual fix needed once migrated. **Don't burn cycles patching the in-house grid first.**

## 5. Panel reuse for readability

The existing `Panel` component (`shared/components/base/Panel/`) supports background images, transparency, shadow positions, rounded corners. Wrap each tab's content in a `Panel` so:

- Forms get a subtle panel background → fields are easier to scan against the page bg
- The event detail Overview tab uses `PanelBgImage` with the cover image at low opacity → context without sacrificing legibility
- Calendar event chips reuse the Panel's transparency variants (`MORE` for inactive past events, `DEFAULT` for upcoming)

Not a new component — purely consistent application of what's already there. The pattern is: **every tab's content is one `Panel` containing one `PanelBody`** unless the tab is a list view, in which case each row gets its own panel (already true for `EventPanel`).

## 6. Settings page refactor

### Why

The current `pages/fleets/[slug]/settings/notifications.vue` mixes two concerns: in-app event toggles **and** Discord integration config (webhook URL, guild ID, channel ID, test connection). They're different mental models — Discord is an integration, in-app notifications are a master switch. Splitting them makes both clearer and avoids forcing officers to wade through Discord setup just to silence one in-app event type.

A second concern: the user-level notification settings page (`pages/settings/notifications.vue`) only exposes `saleNotify`, while the `NotificationPreference` enum already supports every fleet-event type (`fleet_event_published`, `fleet_event_locked`, …). The schema is ahead of the UI.

### Architecture is already split — keep both layers

The `FleetNotificationSetting` model (per-fleet) and `NotificationPreference` model (per-user) answer different questions:

| Layer | Question | Owner |
|---|---|---|
| Fleet | "Are these notifications published for this fleet at all?" | Officer / admin |
| User | "Do I personally want them, via which channel (app/mail/push)?" | Individual member |

Without the fleet layer, small fleets can't silence noisy types for everyone. Without the user layer, a member in three fleets can't tone things down personally. **Both stay.**

### Fleet settings: new tab structure

| Tab | Privilege | Content |
|---|---|---|
| **Fleet** | `fleet:manage` | Logo, fid, name, description, RSI SID, public toggle, public-stats toggle, social URLs (homepage, Teamspeak, Discord-public-link, Guilded, Twitch, YouTube). The Discord URL here is the **public profile link** — not the integration webhook |
| **Membership** | none | Existing per-member options (primary fleet, hangar filter) |
| **Notifications** | `fleet:notifications:manage` | **In-app only** master toggles: which event types fire as in-app notifications for this fleet |
| **Discord** *(new)* | `fleet:notifications:manage` | Webhook URL, guild ID, channel ID, test-connection button, install-bot link. **No event-toggle UI** — Discord posts the canonical event set (decided server-side); fleets either have the integration or they don't |
| **Roles** | `fleet:roles:manage` | Existing role privilege editor |

Same privilege gates `Notifications` and `Discord` for now — no need to invent a separate `fleet:discord:manage` privilege. If we later want to delegate Discord setup separately, it can split.

### User settings: extend the notifications page

`pages/settings/notifications.vue` currently has one toggle (`saleNotify`). Extend to a grouped, channel-aware grid:

```
Account & hangar
  hangar_create / hangar_destroy / hangar_sync_finished / hangar_sync_failed
  wishlist_create / wishlist_destroy
  model_on_sale / new_model

Fleet membership
  fleet_invite / fleet_member_requested / fleet_member_accepted / fleet_request_accepted
  fleet_inventory_item_added

Fleet events  ← new section
  fleet_event_published / fleet_event_locked / fleet_event_starting_soon
  fleet_event_started / fleet_event_completed / fleet_event_cancelled
  fleet_event_signup_added / fleet_event_signup_withdrawn / fleet_event_signup_confirmed
  fleet_event_signup_assigned / fleet_event_signup_kicked
```

Each row gets three checkboxes: **App**, **Mail**, **Push** — backed by the existing `NotificationPreference` columns (`app`, `mail`, `push`). No schema change needed.

Defaults follow what the events plan already specified:
- `fleet_event_starting_soon` → app: ON, mail: ON for events you signed up to
- `fleet_event_cancelled` → app: ON, mail: ON for events you signed up to
- `fleet_event_signup_*` (creator-only) → app: ON
- Everything else → app: ON, mail/push: OFF

### Cleanup candidates

Two items from the survey, each handled differently:

1. **`enabled_discord_events` column on `fleet_notification_settings`** — with the Discord event-toggle UI gone, this column has no input source. Candidate for removal in a follow-up migration; in the meantime the controller stops accepting it as a writable param. The canonical Discord event set lives in code (a constant on the Discord subscriber). If a fleet wants finer control later, that's a future feature, not a current capability.
2. **`public_fleet_stats` on `fleets`** — the public stats page **is** in use, so the setting stays. It needs to be wired to actually gate the page (or the relevant sections within it). If the survey couldn't find consumers, that's a wiring bug, not dead code — fix it as part of this pass: grep all reads of the column, verify the public stats page checks it before rendering, add the check if missing.

`discord_channel_id` is **not** flagged for removal — the Discord integration likely needs it once the bot worker ships, even if no current code path reads it.

Anything we keep gets a one-line comment in the model explaining what consumes it, so the next survey doesn't re-flag it.

### Files touched

**Frontend:**
- `pages/fleets/[slug]/settings/notifications.vue` — strip Discord config, keep in-app toggles only
- `pages/fleets/[slug]/settings/discord.vue` — **new** page, hosts everything Discord
- `pages/fleets/[slug]/settings/routes.ts` — add `fleet-settings-discord` route, gated on `fleet:notifications:manage`
- `pages/settings/notifications.vue` — extend to grouped grid covering all `notification_types`
- `i18n` — split keys: `labels.fleet.notifications.*` keeps in-app, `labels.fleet.discord.*` for the new tab; existing `actions.fleet.notifications.*` for the test button moves to `actions.fleet.discord.*`

**Backend:**
- No model or migration changes in this pass (deferred until verification step on dead options completes)
- `FleetNotificationSettingPolicy` already covers both — no policy changes
- Existing `fleet_notification_settings_controller.rb` doesn't need to split; the frontend just talks to the same endpoint from two pages

## 7. Implementation order

1. **`FormTabs` + `FormTab` shared components** — slot-based, ARIA-compliant, responsive accordion fallback. Storybook entry if a stories setup exists; otherwise a smoke-test page.
2. **Refactor `EventForm` onto `FormTabs`** — three tabs, extract `BasicInfoSection` / `DescriptionSection` / `TeamsSection`. Preserve all existing fields and validation.
3. **Hide `Teams & Ships` tab in create mode** — show after first save; alternative: enable but disable inputs with a "save the event first" hint. Pick whichever validation flow tests cleanly.
4. **New `MissionForm` page + extract** — promote `MissionModal` content into `MissionForm/index.vue`, mount on `pages/fleets/[slug]/missions/new.vue` and `.../[mission]/edit.vue`. Keep modal as a "spawn-from-template" picker only.
5. **Detail page tab refactor** — `pages/fleets/[slug]/events/[event].vue` mounts `FormTabs` in read-only mode; manager-only tabs (`Activity`, `Settings`) gated on `isEventManager`.
6. **Settings: split Discord into its own tab** — new `pages/fleets/[slug]/settings/discord.vue`, route added, fleet `notifications.vue` stripped to in-app toggles only. Reuse the same `FleetNotificationSettings` API endpoint from both pages.
7. **Settings: extend user notifications page** — replace single-toggle with a grouped grid (Account & hangar / Fleet membership / Fleet events) × (App / Mail / Push) backed by `NotificationPreference`.
8. **Settings: cleanup pass** — wire `public_fleet_stats` to the public stats page if not already (gate render on the flag); stop accepting `enabled_discord_events` as writable input now that there's no UI for it. Drop the column in a follow-up migration once the controller no longer references it.
9. **Calendar wrapper** — add `@event-calendar/core` dep, build `CalendarGrid` wrapper, port the page to it. Verify month view first, then add week view, then cover-image rendering via `eventContent`.
10. **In-place create from calendar** — wire `onEventAdded` / empty-slot click to open the new event form (modal mode acceptable here, prefilled `starts_at`).
11. **Panel-wrap all new tab content** — apply the readability pattern uniformly.
12. **i18n** — tab labels (`events.tabs.basic`, etc.), week-view weekday names, calendar action labels, new `labels.fleet.discord.*` and `actions.fleet.discord.*` keys, expanded user-notification labels.
13. **Manual UX QA** — create event from list, edit each tab, create event from calendar (month + week), verify validation error indicators on inactive tabs, verify mobile accordion fallback, verify role-gated detail tabs, verify Discord-tab gating, verify user-notifications grid persistence.
14. **Type-check + standardrb + frontend lint** — run the project's pre-commit chain before PR.

Estimated PR count: **3–4** — `FormTabs` shell (self-contained); form consolidation + detail-page refactor; settings split + user-notifications grid; calendar migration.

## 8. Decisions baked in

| Decision | Choice | Why |
|---|---|---|
| Calendar library | **`@event-calendar/core`** (vkurko, MIT) | Modular ~35 KB Brotli; FullCalendar-compatible API; CSS-grid DOM directly fixes the box-resize bug; iCal/recurring stay backend |
| Tab API | **Slot-based** (`<FormTab>` children) | vee-validate context stays in parent form; matches existing `Panel`/`PanelBody` family |
| Tab nav for new records | **Yes**, but `Teams & Ships` hidden until first save | Slots can't attach to a non-existent event; surfacing a disabled tab with explanatory hint is also acceptable — pick whichever validates cleanly |
| Mobile tab UX | **Horizontal scroll-tabs under 992px** | Matches existing `TabNavView` (settings page); preserves visual consistency across the app |
| URL-sync active tab | **Yes**, `?tab=…` query param | Deep-linkable; browser back/forward works |
| Mission form surface | **Dedicated page**, not modal | Many fields → page (per project convention); modal kept only for "spawn from mission" picking |
| Detail page edit collapse | **Defer** — keep `/edit` route | API mutations are scattered; inline edit needs a follow-up cleanup pass |
| Tabbed admin forms | **Out of scope this plan**, but `FormTabs` API supports it | Ship the shell now; admin migration is its own pass |
| Calendar create flow | **Modal new-event form** prefilled with `starts_at` | Keeps user in calendar context; matches "create from calendar" UX they want |
| Calendar in-place edit | **No** — click event navigates to detail page | Avoids cramming the form into a calendar tooltip; detail page is one click away |
| Cover image in calendar cells | **Yes** via `eventTemplate` callback; fallback to category colour | User explicitly requested |
| Box-resize fix | **Inherent to library migration** | New lib uses fixed-height cells with overflow ellipsing; don't burn time patching the in-house grid first |
| Notification layering | **Keep both fleet-level + user-level** | They answer different questions (master switch vs personal channel pref); schema already supports this |
| Discord vs Notifications split | **Two dedicated tabs**, same privilege gate | Different mental models; same `fleet:notifications:manage` privilege avoids privilege sprawl |
| Discord public-link vs integration | **Keep both** — public link on Fleet tab, webhook config on Discord tab | They serve different purposes; users browsing the fleet see the link, officers configuring see the integration |
| Discord event-set | **Server-side canonical list**, no per-fleet toggle UI | "We need the events we need" — toggles add config surface area without product value; fleets either integrate or don't |
| `enabled_discord_events` column | **Stop writing from controller now; drop in follow-up migration** | No UI source means no reason to keep the column; deferred to follow-up so this pass stays UX-only |
| `public_fleet_stats` | **Keep, ensure it's wired** | Page is in active use; flag should gate render — fix the wiring if missing rather than removing the option |

## 9. Open questions

- **i18n integration** — the library accepts a `locale` option but localised button labels need wiring from our locale files. Confirm the integration shape during step 9.
- **Drag-to-reschedule** — the library supports drag-to-move. Probably gate behind manager role; out of scope for first pass but worth confirming the API permits a PATCH on `starts_at`/`ends_at` from the calendar.
- **Mail/Push channels for fleet-event notifications** — `NotificationPreference` has `app`/`mail`/`push` columns, but is mail delivery actually wired for fleet-event types? If not, the user-settings grid should grey out the column for those rows until the mailer is implemented.
- **Canonical Discord event set** — with no UI toggles, the canonical "what fires to Discord" list lives server-side. Define it in a single constant (`Notifications::Discord::FleetEventSubscriber::PUBLISHED_EVENTS` or similar) and document the rationale next to it.
