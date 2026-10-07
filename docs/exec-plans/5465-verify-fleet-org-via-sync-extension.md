# Verify a fleet's RSI organisation through the Sync extension

Working plan for #5465. Decisions live in the issue body. Deleted before the PR merges.

Stacked on #5464 (`feat/5460-verify-rsi-handle-via-sync-extension`): it reuses `useSyncExtension`, the health check's `payload.actions`, and the remove-only-what-was-added rule from `docs/findings/rsi-profile-writes-via-sync-extension.md`.

## Goal

With the FleetYards Sync extension installed and an RSI session that can edit the org, the fleet verification modal puts the token on the org page, runs the existing check, and takes the token off again, all from one click.

## Open questions

Each needs a capture from a signed-in RSI session with content rights on an org (DevTools → Network, "Preserve log"):

- **Captured 2026-10-07:** the org content editor (`/en/orgs/<SID>/admin/content`) saves a field with `POST /api/orgs/saveDraft` `{"symbol": "<SID>", "<field>": "<whole text>"}` (seen with `history`), headers `x-rsi-token` and `x-requested-with: XMLHttpRequest`. One field per call, whole value. A draft does not go live by itself: `POST /api/orgs/publishDraft` `{"symbol": "<SID>"}` publishes it, and it takes no field, so it publishes **every** pending draft change of the org, including other officers' unpublished edits.
- **Unpublished drafts** (decided in #5465: write only when nothing is pending). The extension reads the draft and the live text of every field, compares, and refuses (409) on any difference. RSI renders the draft at `/en/orgs/<SID>/admin/preview`; comparing it with the public `/orgs/<SID>` page works if both render the same way, but the raw text for the write still needs a source (see below).
- **Raw read, found 2026-10-07:** `/en/orgs/<SID>/admin/content` renders the draft's raw text server-side in `<textarea name="introduction|history|manifesto|charter">` (markItUp editors; `introduction` has `maxlength="300"`, the others none), so the extension can read a field exactly before writing it, formatting included. The page shows no pending-draft marker (Save draft / Preview / Publish / Erase draft are always there), so the pending check compares `/admin/preview` with the public page, both with `FLEETYARDS-…` tokens removed.
- **Org field save request.** URL and payload when RSI saves one org text field (introduction, history, manifesto or charter). Does it replace the whole field, like the bio's `UpdateField`? Which field should the token go in? The one least likely to be long and formatted is the obvious pick.
- **Raw field read.** The request the org editor makes to load that field's current text. The public org page renders these fields as formatted HTML, so unlike the bio it cannot be read back exactly. Without a raw source the extension must not write (decision pending, see the issue).
- **Edit rights, found so far:** without content rights, `/en/orgs/<SID>/admin/content` renders a client-side "Restricted area / Insufficient permissions" screen; the page's only data requests are `graphql` calls, and the HTTP status is 200 either way, but the server-rendered HTML already says so: its `<title>` starts with "Access denied". That is the extension's no-rights signal (403 to the site).
- **Edit rights.** Where RSI says which orgs the signed-in account can edit (a rank or permission list), so the modal can say "this account cannot edit SID" before writing anything rather than after a refused save.
- **Field length limit** for the chosen field.

## What changed

### Phase 1 — Extension (fleetyards/sync)
1. `lib/rsi.ts`: read and write for the chosen org field, from the captures above.
2. `org-verify-write` / `org-verify-remove` actions taking `{sid, token}`: the SID must be one the signed-in account can edit, only a `FLEETYARDS-` token is accepted, the token is appended after a blank line and removed as exactly that suffix. Unreadable field → 422, too long → 413, no edit rights → 403.
3. Both actions in `SUPPORTED_ACTIONS`. Tests mirroring the verify tests.

### Phase 2 — Site
1. `Fleets/RsiVerificationModal`: the extension block from `RsiHandleVerificationModal` (detecting, signed-in account, errors, result next to the button, removal on close/pagehide/after the check answers), with the SID in place of the handle.
2. Whether to pull the shared flow out of both modals into a composable (`useExtensionVerification`) once the second copy exists. Likely yes: the token-removal rules are the part that must not drift.
3. Translations in all 7 locales by hand.

### Backend
None expected: `FleetRsiVerification` already searches the whole org page.

## Intent Verification

- [ ] **One-click path** — a manager with an officer RSI session verifies the fleet without editing the org page by hand
- [ ] **Org page restored** — the field reads as before after success, failure and closing the modal mid-check
- [ ] **No rights, clear error** — a signed-in account that cannot edit the org gets an error before anything is written; the manual steps stay
- [ ] **Fallback** — no extension, an older one, or no RSI session leaves the modal unchanged

## Key files

| File | Role |
|------|------|
| `app/frontend/frontend/components/Fleets/RsiVerificationModal/index.vue` | Fleet verification modal: gets the extension path |
| `app/frontend/frontend/components/RsiHandleVerificationModal/index.vue` | The handle version of the same flow, to mirror or extract |
| `app/frontend/frontend/composables/useSyncExtension.ts` | Request/answer helper and `supports()` |
| `app/lib/fleet_rsi_verification.rb`, `app/lib/rsi/org_page.rb` | Server check (reused) |
| `fleetyards/sync`: `lib/rsi.ts`, `lib/bio.ts`, `lib/message-handler.ts` | Extension side; the bio helpers are the model |

## Not in scope (deferred)

- None yet.

## Discovery Log

- **2026-10-07** Admin content page read with the officer session: raw draft text in four named textareas; no pending marker.
- **2026-10-07** Draft preview at `/admin/preview`; no-rights admin page is a client-side restricted screen fed by GraphQL.
- **2026-10-07** Org publish captured: `POST /api/orgs/publishDraft` with only the SID; publishes the whole draft.
- **2026-10-07** Org save captured: `POST /api/orgs/saveDraft`, one field, whole value (see Open questions).
- **2026-10-07** Initial research. The fleet modal matches the handle modal's structure (token, cooldown, polling, statuses incl. `symbol_mismatch`); `FleetRsiVerification` reads the whole org page text, so any org text field works. Blocked on the RSI captures above.

## Progress

- [ ] Open questions answered (captures)
- [ ] Phase 1 — Extension
- [ ] Phase 2 — Site
