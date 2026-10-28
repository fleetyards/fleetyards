# Raffle system for Star Citizen gift codes

Working plan for #6024. Decisions live in the issue body. Deleted before the PR merges.

## Goal
Admins run raffles for CIG gift codes: confirmed users enter by accepting the participation conditions and are listed publicly; an admin draws one random order; the first in line gets a claim mail, and a click within the claim period mails them the code, otherwise the next in line is mailed.

## Open questions
- **Conditions wording** — the participation conditions are a draft and need a legal read before the first real raffle.

## Data model

- `raffles` (uuid): `title`, `description`, `model_id` (optional prize ship), `code` (encrypted, skipped by PaperTrail), `starts_at`, `run_days` (default 14), `ends_at` (computed), `claim_period_days` (default 3), `published`, `start_announced_at`, `last_day_announced_at`, `drawn_at`, `drawn_by_id`, `concluded_at`; `has_many_attached :images` (upload order, first is the cover).
- `raffle_entries` (uuid): `raffle_id`, `user_id` (nullified on account deletion after the draw), `username` (snapshot on account deletion), `email` (encrypted snapshot at entry, cleared at conclusion), conditions acceptance + version, `draw_position`, `won_at`, `claim_deadline_at`, `claimed_at`, `forfeited_at`, claim/prize mail Postmark message id + status, `prize_mail_sent_at`.
- Notifications index for `raffle_started` / `raffle_last_day` makes fan-out batches idempotent.

## What changed

### Backend
1. `Raffles::Draw` fixes one random order of confirmed entrants; `Raffles::Succession` promotes the next in line after an unclaimed deadline (entry locked against a racing claim), run every 10 minutes by `Raffles::SuccessionJob`.
2. Claim by mail: `Raffles::ClaimMailJob` mails a `generates_token_for(:raffle_claim)` link; `POST /api/v1/raffle-claims` (no sign-in) claims; `Raffles::PrizeMailJob` mails the code and concludes the raffle. Links and codes are built inside the mailer, never passed as job arguments.
3. `Raffles::MailStatusJob` reads Postmark message events every 15 minutes into the entry's mail status.
4. `Raffles::AnnounceJob` fans out `raffle_started` (all confirmed users) and `raffle_last_day` (those not entered) in batches, and posts the start to Bluesky (`Raffles::PostSocialJob`); `Raffles::SocialPost` builds the post text, also offered to copy for X in the admin.
5. Public API: `GET /raffles/current`, `GET /raffles/:id`, entrants, enter/withdraw; admin API: CRUD with gallery and run length, draw, entries with mail status.

### Frontend
1. Admin: form with gallery upload and run length, entries page with winner, mail status and copyable posts.
2. Public: `/raffles/` shows the current raffle (approved design A: key image slider, how it works and conditions left, entry box, winners and entrants right); `/raffles/:id/` for links; `/raffle-claims/:token/` claim page.
3. Homepage: a raffle strip in the landing's first section, a raffle panel on the dashboard.

## Intent Verification

- [x] Code never in admin JSON, public JSON or the app; only in the prize mail
- [x] Entry needs a confirmed account and accepted conditions; acceptance time and version stored
- [x] Draw fixes the order; unclaimed win passes on after the claim period
- [x] Claim link works without sign-in, once, before the deadline
- [x] Start and last-day notifications sent once per raffle; Bluesky post at start
- [x] Mail delivery status tracked through Postmark

## Key files

| File | Role |
|------|------|
| `app/models/raffle.rb`, `app/models/raffle_entry.rb` | State, current raffle, claim token |
| `app/lib/raffles/` | Draw, succession, social post, Postmark mailing |
| `app/jobs/raffles/` | Claim/prize mails, succession, announcements, mail status |
| `app/frontend/frontend/pages/raffles/[id].vue` | Raffle page (current or by id) |
| `app/frontend/admin/pages/raffles/` | Admin |

## Not in scope (deferred)
- **Reordering gallery images** — upload order decides; the first upload is the cover.
- **Reminder mail before the claim deadline** — the claim mail states the deadline.

## Discovery Log

- **2026-10-27** Production blocks sign-in for unconfirmed accounts; the `confirmed?` gate is a backstop and is tested on the policy, since CI allows unconfirmed sign-in.
- **2026-10-27** The admin form's save was silent on a missing date: `FormDateTime` shows only the error it is handed, so the form passes date errors and alerts on any invalid submit.
- **2026-10-28** Gallery attachments carry UUIDs and come back in no fixed order; `Raffle#ordered_images` sorts by blob upload time.
- **2026-10-28** Frontend strings live in one `translations/<locale>/raffles.json`, deep-merged into the catalogue, so `labels.json` was not touched.

## Progress
- [x] Backend
- [x] Admin
- [x] Public page and homepage
- [ ] Legal review of the conditions
