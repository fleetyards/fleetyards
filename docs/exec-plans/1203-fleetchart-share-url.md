# Fleets: sharable deeplink for fleetcharts

## Goal

Pressing Share while looking at a fleet's fleetchart hands out a link that opens the fleetchart, not the ship list.

## Context

Opened six years ago. Almost all of it has since been built by accident, in pieces that were never joined up:

- `fleets/[slug]/routes.ts:28` defines a route `fleet-fleetchart` at `fleetchart/`, redirecting to `fleet-ships` with `query: { fleetchart: "true" }`. It answers 200 in production today.
- `Fleetchart/App/index.vue:152` reads `route.query.fleetchart` on mount and calls `fleetchartStore.show(namespace)`. Both `ShipsList` and `PublicShipsList` render that component.

So the deeplink works end to end already. What does not work is producing one: `shareUrl` in `pages/fleets/[slug]/ships.vue:36` returns `${host}/fleets/${slug}/ships` unconditionally, so a reader who opens the fleetchart and presses Share sends someone to the plain list.

Resolves #1203

## Decisions

### D1 — The button belongs inside the chart, not in the header

The first attempt made `shareUrl` on the ships page follow the chart's state. It was dead logic: `Fleetchart/App` is `position: fixed; z-index: 2100`, so it covers the app header — and the share button is teleported to `#header-right`. It would have switched the URL at exactly the moment nobody could press it.

So the control moves into the chart's own `.fleetchart-app-controls`, beside the mode dropdown, and the page keeps sharing the ship list unchanged.

### D2 — Clipboard needs a container inside the overlay

`copyText(text, container?)` hands clipboard.js a container and defaults it to `document.body` — which is behind this overlay. Copying from inside a fixed overlay then reports success and copies nothing.

`ShareBtn` called it without a container, so it gains an optional `container` prop and the chart passes its own root element.

### D3 — Only a public fleet offers the button

Whoever receives the link can only open it if the fleet is public: `fleet-ships` renders `PublicShipsList` for a non-member and nothing at all for a private fleet. So `fleetchartShareUrl` is `undefined` for a private fleet and the control is not rendered, rather than handing out a link that shows the recipient an empty page.

This is deliberately wider than the header button, which also requires `membership` — a visitor to a public fleet can now share the chart they are looking at.

### D4 — Share the named route, not the query string

`/fleets/{slug}/fleetchart` rather than `/fleets/{slug}/ships?fleetchart=true`. Both work, but the first is what a person would want to paste into Discord, and it is already the route's public shape. The redirect turns it into the query form on arrival.

### D5 — View options stay out

Viewpoint, scale, colour and the extended-state toggle live in the store, not the URL. Carrying them would mean serialising view state into the link and reading it back on mount — a larger change than this issue asks for, and one that invites a link nobody can read. The link opens the fleetchart; how the recipient looks at it is theirs.

### D6 — No test, deliberately

There are 67 frontend specs and not one of them is for a page: the convention here covers components, composables and lib code. A first page spec for a sixteen-line computed would be disproportionate.

The rigorous alternative is e2e — `Fleet.spec.ts` already logs in and builds fleets through factories — but it would need a fleet with ships, the chart opened, and the share control read, and the suite cannot be run locally without colliding with another worktree on its port. `pnpm lint` covers the types; the behaviour is worth one look in a browser instead.

## What changed

1. `ShareBtn` takes an optional `container` and passes it to `copyText`.
2. `Fleetchart/App` takes optional `shareUrl` / `shareTitle` and renders a `ShareBtn` in its controls, handing it the chart's root element as the clipboard container.
3. `ShipsList` and `PublicShipsList` build the fleetchart URL, for a public fleet only.
4. `ships.vue` is untouched.

## Intent Verification

- [ ] **The chart has a share control at all** — this is what the header button could never be
- [ ] **It copies** — the clipboard container is the point; a success message with an empty clipboard is the failure to watch for
- [ ] **It shares `/fleetchart`**, and the ship list still shares `/ships`
- [ ] **A private fleet offers no control**
- [ ] **A visitor to a public fleet gets one**
- [ ] **Opening the shared link lands on the fleetchart**, which is the half that already worked

## Key files

| File | Role |
|------|------|
| `app/frontend/frontend/pages/fleets/[slug]/ships.vue` | `shareUrl`, and the namespace choice |
| `app/frontend/shared/stores/fleetchart.ts` | `isVisible(namespace)` |
| `app/frontend/frontend/pages/fleets/[slug]/routes.ts` | The `fleet-fleetchart` route that already exists |
| `app/frontend/frontend/components/Fleetchart/App/index.vue` | Reads the query param on mount |

## Not in scope (deferred)

- **View options in the link** — see D3.
- **The same treatment for the hangar and the ships index**, which also render `Fleetchart/App` and also share a fixed URL. Worth doing, but this issue is about fleets and the pattern is easier to judge once it exists in one place.

## Discovery Log

- **2026-09-10** First attempt was wrong and was reverted: the share button sits in the app header, and the chart covers the header. Found by looking at the running app, not by reading. Rebuilt inside the chart, which surfaced the clipboard-container trap on the way.
- **2026-09-10** Implemented. `pnpm lint` green. The store declaration moved above the computeds that use it — it worked either way, since a computed body runs later, but a reader should not have to know that.
- **2026-09-10** Research. Found the route and the query-param reader already in place, which turns this from "build a deeplink" into "produce the one that exists". Confirmed the route answers 200 in production before relying on it.

## Progress

- [ ] Share URL follows the fleetchart
