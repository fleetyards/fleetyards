# Install prompt and a complete web app manifest

Working plan for #5232. Decisions live in the issue body. Deleted before the PR merges.

## Goal
People can install Fleetyards on purpose (a Chrome install action, or iOS "Add to Home Screen" instructions), shown at useful moments and never nagging, and the installed app ships a complete manifest.

## Open questions
Chosen without a decision from the user; listed in the PR for review. Move whatever is confirmed to the issue body.
- **Fleet events shortcut** — new `/events/` route lands on the first of the user's fleets with the mission builder enabled; no fleets → create fleet.
- **Screenshots** — captured from the live `/ships/` page (1280×720 wide, 412×915 narrow).
- **Maskable icon** — the round icon scaled to 400/512 on #333333, inside the 80% safe zone.
- **iOS sheet host** — the offer is a persistent toast (like SupportHint); its button, and the nav item, open an AppModal with the steps.
- **Feature flag** — none; the nav item only shows where installing is possible.
- **Nav item on first visit** — shown; "never on first visit" is applied to the unprompted offer only.
- **theme-color mismatch** — left alone.

## What changed

### Phase 1 — Manifest
1. `app/views/frontend/_manifest.json.erb`: add `id: "/"`, `scope: "/"`, `launch_handler: { client_mode: "navigate-existing" }`, `shortcuts` (Hangar `/hangar/`, Fleet events, Compare `/compare/`), a maskable icon entry, and `screenshots`.
2. Add the maskable icon (and screenshots) under `app/frontend/images/favicons/`.
3. Delete the dead `manifest` block in `vite.config.ts` (`manifest: false`), and drop `manifest.webmanifest` from the Dockerfile copy.
4. `/events/` route (`pages/events.vue`) as the fleet events shortcut target.

### Phase 2 — Install composable
1. `app/frontend/frontend/composables/useInstallPrompt.ts`, modelled on `useSupportPrompt.ts`: capture `beforeinstallprompt` early (in `entrypoints/frontend.ts`, before the app mounts, since it fires once), expose `canInstall`, `isIos`, `isStandalone` (`matchMedia("(display-mode: standalone)")` or `navigator.standalone`), `install()`, and handle `appinstalled`.
2. Dismissal in localStorage (`fy.install-prompt`) with a cooldown, try/catch wrapped, skipped under `navigator.webdriver` and on the first visit.
3. Spec next to it.

### Phase 3 — Entry points
1. "Install app" `NavItem :action` in the Navigation footer (`frontend/components/Navigation/index.vue`), visible only when installable or on iOS Safari and not standalone.
2. Offer after a meaningful action: the two self-signup success paths (`EventSignupCta`, `EventSlotRow`). The `fleet-event-signup-changed` comlink event also fires on withdrawals and admin assignments, so it is not used.
3. iOS instructions component ("Share, then Add to Home Screen"), plus a visual-test page.
4. Translations in all 7 locales.

## Intent Verification

- [ ] **Chrome/Android shows our own install action** — after `beforeinstallprompt`, the nav item appears and triggers the native dialog; never on the first visit.
- [ ] **iOS shows the instructions sheet** at the same moments, and never when running installed.
- [ ] **Dismissal sticks** — a dismissed prompt stays hidden across reloads for the cooldown.
- [ ] **Manifest is complete** — `id`, `scope`, maskable icon, screenshots, shortcuts and `launch_handler` present; Chrome DevTools Application › Manifest shows no warnings.
- [ ] **No "My Awesome App"** left in `vite.config.ts`.

## Key files

| File | Role |
|------|------|
| `app/views/frontend/_manifest.json.erb` | The manifest pages actually link |
| `app/views/layouts/_meta.html.erb` | Manifest link, theme-color, apple-touch meta |
| `app/controllers/frontend/base_controller.rb` | Serves the manifest (digest-busted) |
| `vite.config.ts` | Dead VitePWA manifest block |
| `Dockerfile` | Copies SW + `manifest.webmanifest` to `public/` |
| `app/frontend/entrypoints/frontend.ts` | SW registration; early `beforeinstallprompt` capture |
| `app/frontend/shared/composables/useSupportPrompt.ts` | Precedent for localStorage-backed prompts |
| `app/frontend/frontend/components/Navigation/index.vue` | Footer nav for the install action |
| `app/frontend/frontend/components/Fleets/Events/EventSignupCta/index.vue` | Emits `fleet-event-signup-changed` |

## Not in scope (deferred)
- **Web Push / injectManifest** — #4980.
- **Admin manifest** (`app/views/admin/manifest.json.erb`) — separate app.

## Discovery Log

- **2026-09-26** Initial research and plan creation. The VitePWA manifest is built but never linked; the ERB one is live. No install-prompt code exists anywhere.
- **2026-09-26** `/fleets/` redirects to fleet-add, so it cannot be the events shortcut; events are per fleet and gated by `FLEET_MISSION_BUILDER`.
- **2026-09-26** The manifest has no locale: nothing sets `I18n.locale` for it, so shortcut names render in English, like the app name already did.
- **2026-09-26** The manifest can be rendered in the Ruby suite by stubbing `ViteRuby#dev_server_running?`, the same trick the admin CSRF test uses.

## Progress
- [x] Phase 1 — Manifest
- [x] Phase 2 — Install composable
- [x] Phase 3 — Entry points
