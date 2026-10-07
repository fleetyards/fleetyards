# Verify RSI handle through the Sync extension

Working plan for #5460. Decisions live in the issue body. Deleted before the PR merges.

## Goal

With the FleetYards Sync extension installed, the RSI verification modal can put the token into the RSI bio, run the existing server-side check, and restore the bio, all from one click.

## Open questions

- None. RSI saves the bio with `POST /api/settings/UpdateField` `{pageId: "my_profile", fieldId: "biography", value}` (captured from a signed-in session).

## What changed

### Phase 1 — Extension (fleetyards/sync)
1. `lib/rsi.ts`: `fetchCitizenPage(handle)` and `updateBio(token, bio)`.
2. `lib/bio.ts` + `lib/message-handler.ts`: `verify-write` appends the token after a blank line; `verify-remove` strips exactly that suffix from the current bio. No snapshot: the bio is read back from the citizen page, which renders it escaped with `<br />`, so a restore from a snapshot could overwrite the user's bio with a near copy. A bio with other markup answers 422 and is never written. The handle is always the signed-in account's own (`identify`), and only a `FLEETYARDS-` token is accepted.
3. Tests in `__tests__/message-handler.test.ts` and `__tests__/rsi.test.ts`.
4. Release the extension (release-please) before the site ships the UI. The site must work with older extension versions that do not know the action (an "Unknown Action" 500 → manual steps).

### Phase 2 — Site: extension detection outside the hangar
1. `useSyncExtension` composable: one request, the matching answer, a timeout. `supports(action)` reads the health check's `actions` list. The hangar keeps its own health check in `hangarStore.extensionReady`; moving it over was not needed for this.
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

- **Fleet RSI verification via the extension**: #5465.

## Discovery Log

- **2026-10-07** RSI settings probe: bio limit 1024 chars; save request not found (bypasses page fetch/XHR and the extension network log); reCAPTCHA Enterprise on the page is used for checkout only; RSI's GraphQL schema has `AccountDossier.bio` but no bio mutation was found in the main bundle.
- **2026-10-07** Initial research. The extension's `identify` handle crosses `window.postMessage` and cannot be trusted server-side, so the extension only automates the bio edit. `extensionReady` is set only by the hangar sync button.

## Progress

- [x] Open questions answered (RSI bio endpoint)
- [x] Phase 1 — Extension (fleetyards/sync, `feat/rsi-handle-verification`)
- [x] Phase 2 — Shared extension detection
- [x] Phase 3 — Modal flow
- [ ] Live run against RSI with the unpacked extension
