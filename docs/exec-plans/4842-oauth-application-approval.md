# OAuth applications: open registration, gated by admin approval

## Goal

Anyone can register an OAuth application, and an application does nothing until an admin approves it — so the provider that has been live and unreachable becomes usable without handing strangers a working client.

## Context

The OAuth2/OIDC provider runs in production today. Probed 2026-09-10:

```
/.well-known/openid-configuration   200   full discovery document
/oauth/authorize                    401   exists, wants a login
/oauth/token                        400   live
/oauth/discovery/keys               200   real RSA keys
/oauth/userinfo                     401   live
```

Scopes are enforced in the controllers, the OpenAPI security schemes and the `api/auth-v1` docs pages exist, and there are integration tests. What is missing is any way to *reach* it: `oauth-applications` has no global gate, exactly one user holds an actor gate, and `feature_settings` carries no row for it, so `UserFeaturesController#enable` answers `403 This feature cannot be self-activated`. One application exists, with 0 access tokens and 0 grants.

Resolves #4842. Unblocks #2557, #3310, #2457.

## Decisions

### D1 — Gate the application, not the ability to create one

Turning the flag on without a gate would let anyone mint a working client against the API. Gating creation instead keeps the door shut. So registration opens to everyone and a new application starts `pending`.

### D2 — Enforce in `allow_grant_flow_for_client`

Doorkeeper's hook receives `(grant_flow, client)`, answers `:unauthorized_client` and stops the request. It sees the token exchange and the refresh as well as the authorization, so one predicate covers every way a client could be used. Guards on the endpoints would have to be complete, and one forgotten guard is a working client for a stranger.

That the hook fires is not taken on trust: adding it turned two existing authorize tests red with `unauthorized_client`, because the factory built an unreviewed application.

### D3 — AASM `pending / approved / rejected`, with a mandatory reason

Matches `FleetMembership`, `FleetEvent` and `Import`. Rejection is a state rather than an absence so the refusal can carry a reason — the owner is shown it, and a refusal they cannot act on is worse than no answer. It also allows withdrawing an approval later.

Transitions go through `event` + `save` rather than `event!`: the bang form persists with `save!`, so a reject without a reason would raise instead of returning a validation error the controller can render as a 400.

### D4 — Changing the redirect target or the scopes returns an application to review

Found while reading the controller, not in the report. `update` permitted `redirect_uri` and `scopes` on an approved application, so the gate was bypassable: get approved while harmless, then point the client somewhere else. Approval is granted for one redirect target and one scope set, and changing either sends the application back to `pending`.

The rule lives in a `before_update` on the model rather than in the controller, so no future write path can skip it. An admin edit is caught by the same rule; re-approving is one click, and the alternative is a rule with a hole in it.

### D5 — Admin-created applications skip the queue

The approval exists to gate strangers, not the operator. `Admin::…::OauthApplicationsController#create` approves on creation.

### D6 — The operator hears about it in the notification center

`AdminNotification.notify!` with a new `oauth_application_review` type, `access: [:oauth_applications]` so it reaches exactly the admins who can act on it, and a `dedupe_key` so a re-edited application stays one row in the inbox. The alternative — a badge on the admin page — only works for somebody already looking.

### D7 — A logo, and `no_vector_image` is not negotiable

Shown on the consent screen so the person granting access can recognise who is asking. `validates :logo, no_vector_image: true` as `Fleet` does: an SVG can carry script, and this one is rendered to strangers.

The key is emitted only when a logo is attached. `MediaFile` requires four fields, so an empty `{}` for the common no-logo case would fail the schema; absent is valid and generates `logo?: MediaFile` rather than a nullable object, which is what produces invalid TS.

### D8 — The state enum is written inline, not shared

A shared enum component leaks into the public schema. Three literal enums cost less than one leaked component.

### D9 — The backfill approves without claiming a review

The one existing application becomes `approved`; `approved_at` stays null. Nobody reviewed it, and a fabricated timestamp would say otherwise.

## What changed

### Phase 1 — Model and migration
1. `aasm_state` (default `pending`), `approved_at`, `rejected_at`, `rejection_reason`, `reviewed_by_id`; existing rows approved.
2. AASM block, mandatory reason, `usable_as_client?`, `return_to_review`, `report_for_review`.
3. `has_one_attached :logo` with `no_vector_image`.

### Phase 2 — Enforcement
4. `allow_grant_flow_for_client` in the Doorkeeper initializer.

### Phase 3 — Admin
5. `PUT approve` / `PUT reject` with routes, `aasm_state_eq` filter, auto-approval on admin create.
6. `oauth_application_review` notification type.

### Phase 4 — API surface
7. `state`, `rejectionReason`, `logo` on the public schema; the admin schema also carries `approvedAt`, `rejectedAt`, `reviewedByName`. `logo` accepted on both inputs.
8. Schema regenerated, orval clients regenerated.

### Phase 5 — Tests
9. `Oauth::ApplicationTest` — transitions, the mandatory reason, both return-to-review paths, the notification, the SVG refusal.
10. Gate tests on `POST /authorize` for a pending and a rejected application.
11. Admin approve/reject, including the refusal without a reason.
12. Factory approved by default with `:pending` and `:rejected` traits — nearly every test is about a working client, and the gate is its own handful of tests.

## Intent Verification

- [ ] **An unreviewed application is inert** — `POST /authorize` answers `unauthorized_client`
- [ ] **So is a rejected one**
- [ ] **A refusal explains itself** — reject without a reason is a 400, and the reason reaches the owner
- [ ] **Approval cannot be moved** — changing redirect or scopes returns it to the queue
- [ ] **The operator finds out** — a pending application appears in the notification center
- [ ] **SVG is refused** on the logo
- [ ] **Nothing existing broke** — the one production application keeps working

## Not in scope (deferred)

- **Turning the flag on** — an admin action, and the point of the whole change, but not code. Global boolean, or a `feature_settings` row for self-service.
- **A per-user limit on applications** — worth having before this is wide open; the approval queue is the interim answer.
- **Rate limiting registration.**

## Discovery Log

- **2026-09-10** Audited the provider rather than trusting the earlier triage, which had called this "built, needs a rollout" and pointed at `oauth-security.md` — that plan is about OAuth as a *consumer* (Discord login), not the provider. Probed production: everything answers. Found the real gap is the flag and the missing `feature_settings` row. Found D4, the bypass, while reading the controller.

## Progress

- [x] Phase 1 — Model and migration
- [x] Phase 2 — Enforcement
- [x] Phase 3 — Admin
- [x] Phase 4 — API surface
- [x] Phase 5 — Tests
- [ ] Phase 6 — Frontend: consent-screen logo, settings upload and state, admin review UI
