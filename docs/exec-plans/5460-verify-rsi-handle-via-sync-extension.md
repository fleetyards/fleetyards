# Verify RSI handle through the Sync extension

Working plan for #5460. Decisions live in the issue body. Deleted before the PR merges.

## Goal

With the FleetYards Sync extension installed, the RSI verification modal can put the token into the RSI bio, run the existing server-side check, and restore the bio, all from one click.

## Open questions

- **RSI bio endpoint.** Which request does `robertsspaceindustries.com/account/profile` send to save the bio, with what payload, and does it need anything beyond `X-Rsi-Token` + cookies (CSRF, a full profile payload that would reset other fields)? Find it from a signed-in session before writing extension code. Known so far: the editor lives at `/en/account/settings/profile` (the old `/account/profile` URL redirects there), the bio limit is 1024 characters, and the save is not sent through the page's `window.fetch`/XHR and does not show in the tab's network log (worker or socket?). The form definitions come from `/api/settings/Page`. Next step: DevTools → Network with "Preserve log" while saving a changed bio, by hand.

## What changed

### Phase 1 — Extension (fleetyards/sync)
1. `lib/rsi.ts`: `fetchBio(token)` and `updateBio(token, bio)` against the endpoint found above.
2. `lib/message-handler.ts`: `bio-write` action (stores the previous bio in `browser.storage.session`, appends the token, answers an error code instead of writing when the result would exceed RSI's bio limit) and `bio-restore` action (writes the stored bio back). Same origin allow-list as `sync`/`identify`.
3. Tests in `__tests__/message-handler.test.ts` and `__tests__/rsi.test.ts`.
4. Release the extension (release-please) before the site ships the UI. The site must work with older extension versions that do not know the action (an "Unknown Action" 500 → manual steps).

### Phase 2 — Site: extension detection outside the hangar
1. Move the health check out of `Hangar/SyncBtn/index.vue` into a shared composable (e.g. `useSyncExtension`) that both the hangar and the verification modal use. Today `hangarStore.extensionReady` is only set when the hangar sync button is mounted, so the profile page never knows about the extension.
2. Add the new actions to `FleetyardsSyncAction` in `lib/FleetyardsSyncHandler.ts`.

### Phase 3 — Site: modal flow
1. `RsiHandleVerificationModal`: when the extension is ready, show a "Verify with extension" action above the manual steps. If `identify` returns a different handle than the profile's, show an error instead (no handle change offered).
2. Flow: `bio-write` → `POST /me/rsi-verification/check` right away (no delay) → poll as today → `bio-restore` on any final status and on modal unmount.
3. Bio over the length limit: error in the modal; the manual steps stay available.
4. The manual steps stay as they are and still work as the fallback.
5. Translations in all 7 locales, by hand.
6. Point `RSI_PROFILE_SETTINGS_URL` at `https://robertsspaceindustries.com/account/settings/profile`; the current `/account/profile` only lands on the settings index.

### Backend
No change: the citizen page shows a bio edit right away, so the existing check job is reused as-is.

## Intent Verification

- [ ] **One-click path** — with the extension and an RSI session, the modal verifies without the user editing their bio
- [ ] **Bio restored** — the RSI bio reads as before after success, failure, and closing the modal mid-check
- [ ] **Server stays the authority** — a forged `fy-sync` postMessage cannot verify a handle
- [ ] **Fallback** — no extension, an old extension version, or no RSI session shows the manual steps unchanged

## Key files

| File | Role |
|------|------|
| `app/frontend/frontend/components/RsiHandleVerificationModal/index.vue` | Verification modal: gets the extension path |
| `app/frontend/frontend/components/Hangar/SyncBtn/index.vue` | Current extension health check, to be extracted |
| `app/frontend/frontend/lib/FleetyardsSyncHandler.ts` | Message types shared with the extension |
| `app/frontend/frontend/stores/hangar.ts` | `extensionReady` today |
| `app/controllers/api/v1/me/rsi_verifications_controller.rb` | `check` endpoint (reused) |
| `app/lib/user_rsi_verification.rb` | Bio check (reused) |
| `~/dev/fleetyards-sync/lib/rsi.ts`, `lib/message-handler.ts` | Extension RSI calls and message actions |

## Not in scope (deferred)

- **Fleet RSI verification via the extension** — same idea for the org page token (`FleetRsiVerification`). Needs org-admin rights on RSI, so it is a separate flow. Becomes its own issue if wanted.

## Discovery Log

- **2026-10-07** RSI settings probe: bio limit 1024 chars; save request not found (bypasses page fetch/XHR and the extension network log); reCAPTCHA Enterprise on the page is used for checkout only; RSI's GraphQL schema has `AccountDossier.bio` but no bio mutation was found in the main bundle.
- **2026-10-07** Initial research. The extension's `identify` handle crosses `window.postMessage` and cannot be trusted server-side, so the extension only automates the bio edit. `extensionReady` is set only by the hangar sync button.

## Progress

- [ ] Open questions answered (RSI bio endpoint)
- [ ] Phase 1 — Extension
- [ ] Phase 2 — Shared extension detection
- [ ] Phase 3 — Modal flow
