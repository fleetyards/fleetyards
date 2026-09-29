# Links that should open the installed app on Android

Working plan for #5233. Decisions live in the issue body. Deleted before the PR merges.

## Goal

A link shared into Fleetyards from Android's share sheet opens its page in the app, and the hangar stats share link reaches the stats page.

## Open questions

- None. The device test and any switch to full URLs wait for the user's test on a phone (see the issue body).

## What changed

### Phase 1 — Hangar stats and fleetchart short links

1. `h/:username/stats` and `h/:username/fleetchart` on the short domain redirect to the public hangar's stats and fleetchart pages. Until now the stats share button produced a short link that had no route and landed on the home page.
2. Integration test under `test/integration/short/`.

### Phase 2 — Share target

1. `share_target` in the manifest: GET `/share/` with `title`, `text` and `url`.
2. The short domain reaches the frontend next to `FRONTEND_ENDPOINT`.
3. A pure resolver takes the shared fields and returns a route on this origin, a short link to hand to the server, a search, or home.
4. A `/share/` page runs it: an in-app `router.replace` for a Fleetyards URL, `location.replace` for a short link, the ships search for anything else.
5. `title.share` in all seven locales.

## Intent Verification

- [ ] **Stats link works**: `GET /h/<user>/stats` on the short domain redirects to `/hangar/<user>/stats`.
- [ ] **Sharing a Fleetyards URL opens it**: `/share/?url=https://<domain>/ships/x/` lands on `/ships/x/`.
- [ ] **Sharing a short link resolves it**: `/share/?text=… https://<short>/fe/…` hands off to the short URL.
- [ ] **Anything else searches**: `/share/?text=Carrack` opens the ships list filtered by "Carrack".

## Key files

| File                                       | Role                           |
| ------------------------------------------ | ------------------------------ |
| `config/routes/short_routes.rb`            | short-domain routes            |
| `app/controllers/short/base_controller.rb` | short-link redirects           |
| `config/routes/frontend_routes.rb`         | full routes they redirect to   |
| `app/views/frontend/_manifest.json.erb`    | web app manifest               |
| `app/views/layouts/_app_env.html.erb`      | window config for the frontend |
| `app/frontend/frontend/pages/routes.ts`    | frontend routes                |

## Not in scope (deferred)

- **Device test and full URLs for invites and events**: the user tests on a phone first. The tasks stay open on #5233.

## Discovery Log

- **2026-09-29** Initial research. No search page exists; the home page's search routes to the ships list with `searchCont`, so the share target does the same.

## Progress

- [x] Phase 1
- [x] Phase 2
