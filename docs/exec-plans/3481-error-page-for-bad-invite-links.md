# Add an error page for bad invite links

## Goal

An invite link that is wrong, expired or used up renders a readable error state on the invite page itself, instead of a blank page and a toast the user is immediately redirected away from.

## Context

A reporter was given a wrong invite link by their org and saw a blank page. As an experienced user they assumed their browser or the site was broken and spent time debugging before an org member told them the link was bad.

`app/frontend/frontend/pages/fleets/invite.vue` renders `<section class="container fleet-detail" />` — an element with no content — and does all of its communication through a transient `displayAlert` toast, after which it pushes the user to `home`. A missed toast leaves exactly the empty page from the issue screenshot, and the redirect means there is nothing left on screen to go back and read.

Resolves #3481

## Decisions

### D1 — Render the failure on the page, do not redirect away from it

The page already knows the lookup failed; it just has nothing to show for it. The *not found* case becomes a persistent state on the page instead of a toast plus `router.push({ name: "home" })`. A toast is the wrong instrument for a terminal state the user has to read and act on — it is gone in seconds, and the redirect removes the context that would explain it.

### D2 — A fifth shared error component, not an inline composition

Revised during implementation. The first draft composed the primitives inline in `invite.vue`, on the grounds that a component earns its place at the second caller. That was wrong about this codebase: `shared/components/` already holds four full-page error blocks — `NotFound`, `NotAuthorized`, `Forbidden`, `ServerError` — each with a single real caller, all four built from the same `Box` / `Text` / `Btn` shape, and all four rendered side by side under "Error Pages" in `pages/visual-tests/states.vue`.

So the house pattern is one component per error state, and `InviteInvalid` becomes the fifth. It takes a `token` prop, which is the one thing that makes it differ from its siblings, and joins them on the visual-tests page — which is also the only way to eyeball it without a live invite link.

### D3 — One message for all three causes

`Api::V1::FleetsController#find_by_invite` resolves the token through `FleetInviteUrl.active.find_by!`, and `active` means *not expired* **and** *uses left*. A typo'd token, an expired link and an exhausted link are therefore indistinguishable to the client — all three arrive as a 404. The copy says the link is invalid or no longer valid rather than claiming which one it is.

The reporter asked for the bad link to appear in the error box; showing the token satisfies that without the page having to reconstruct a URL.

### D4 — Only the lookup becomes a page state

Redeeming a valid invite (`handleFleetInvite`) keeps its toast and redirect. By that point the user has confirmed a real fleet, and a failure there is transient — a server error, a race — rather than a property of the link they were given. Turning it into the same terminal error state would misreport a retryable failure.

### D5 — New keys go under `headlines`/`texts`, not `messages`

`headlines.notFound` / `texts.notFound` and their `forbidden` and `featureNotReady` siblings are where full-page error copy already lives. The new keys join them. `messages.fleetInvite.notFound` has exactly one reference — the toast this change removes — so it goes with it.

## What changed

### Phase 1 — Error state on the invite page

1. New `app/frontend/shared/components/InviteInvalid/index.vue`, following its four siblings, with a `token` prop and a scoped rule that breaks the token rather than letting it run out of the box.
2. `invite.vue`: an `inviteInvalid` ref that the `findFleetByInvite` catch sets, in place of `displayAlert` + `router.push`; the component renders inside the existing `<section>`.
3. Register it under "Error Pages" in `pages/visual-tests/states.vue`.
4. Leave the confirm dialog and `handleFleetInvite` paths untouched.

### Phase 2 — Copy in all seven locales

5. Add `headlines.inviteInvalid`, `texts.inviteInvalid` and `labels.inviteToken` to all seven locales, hand-translated. Crowdin is not in use and `enableFallback` hides gaps, so an en-only key silently ships English to six locales.
6. Remove `messages.fleetInvite.notFound` from all seven locales, its only caller being gone.

All 28 translation files round-trip byte-identically through `json.dumps(indent=2, ensure_ascii=False)`, so the edits were scripted and the diff is exactly one line per file.

## Intent Verification

- [ ] **Bad token shows something** — opening `/fleets/invites/<garbage>/` renders a visible error box, not a blank page
- [ ] **It stays on screen** — the page does not redirect to home behind the error
- [ ] **Expired and exhausted links land there too** — an invite past `expires_after`, and one with `limit` used up, reach the same state
- [ ] **The happy path is unchanged** — a valid invite still opens the join confirm dialog and joining still works
- [ ] **The link is named** — the error box shows the token the user opened
- [ ] **Seven locales** — both new keys exist in every locale directory, and the removed key is gone from all seven

## Key files

| File | Role |
|------|------|
| `app/frontend/frontend/pages/fleets/invite.vue` | The page; today an empty `<section>` plus toasts |
| `app/frontend/shared/components/InviteInvalid/index.vue` | New; the fifth full-page error block |
| `app/frontend/shared/components/NotFound/index.vue` | The pattern its four siblings establish |
| `app/frontend/frontend/pages/visual-tests/states.vue` | Where the error blocks are rendered for eyeballing |
| `app/frontend/frontend/pages/fleets/routes.ts` | Route `fleet-invite`, `needsAuthentication: true`, no `title` meta |
| `app/controllers/api/v1/fleets_controller.rb` | `find_by_invite`, raises `RecordNotFound` → 404 |
| `app/models/fleet_invite_url.rb` | `active` scope — the reason three causes collapse into one 404 |
| `app/frontend/translations/*/headlines.json`, `texts.json`, `messages.json` | Copy, seven locales |

## Not in scope (deferred)

- **The `needsAuthentication: true` guard** — a logged-out visitor with a bad link is sent to login first and only meets this error after signing in. Whether an invite page should be readable while logged out is a separate product question.
- **The backend's 404 body** — `find_by_invite` falls into a `rescue_from` that renders `messages.record_not_found.fleet` interpolated with `params[:slug]`, which is never a slug on this route. The client never reads the body, so this is cosmetic.
- **Distinguishing expired from wrong** — would need the API to stop conflating them in `active`, and to answer differently for a token that exists but is spent. Worth doing only if the single message turns out to confuse people.

## Discovery Log

- **2026-09-10** Phases 1 and 2 implemented. `lint:js`, `format` and `lint:ts` green. D2 revised on contact with the code: the four existing error components make a fifth the conventional choice, not an inline composition. No spec added — all four siblings are presentational and untested, and the project's check for them is the visual-tests page.
- **2026-09-10** Initial research and plan creation. Confirmed the blank page is the empty `<section>` in the template, not a failed render. Confirmed via `FleetInviteUrl.active` that wrong, expired and exhausted tokens are one indistinguishable 404. Confirmed `messages.fleetInvite.notFound` has a single caller.

## Progress

- [x] Phase 1 — Error state on the invite page
- [x] Phase 2 — Copy in all seven locales
- [ ] Manual check against a running dev server
