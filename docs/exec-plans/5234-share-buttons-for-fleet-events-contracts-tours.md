# Share buttons for fleet events, contracts, tours and fleet invites

Working plan for #5234. Decisions live in the issue body. Deleted before the PR merges.

## Goal

Fleet events, contracts, tours and fleet invites can be shared from the phone's share sheet, and their links preview with a title only when every fleet member may see the item.

## Open questions

- None.

## What changed

### Phase 1 — Link previews

1. `LinkPreview` decides title and image: members-visible, published items name themselves; officers, squadron and draft items read "Contract in <Fleet>" with the fleet logo.
2. `Frontend::FleetsController#event` uses it, which closes the officers-only title leak; new `#contract` and `#tour`, and `Frontend::ToursController#show`/`#join` for `/tools/tours/`.
3. Both controllers inherit `Frontend::BaseController`, so these pages keep the flash and features prefetch that `base#index` gave them.
4. Titles in all seven locales under `title.link_preview`.

### Phase 2 — Share buttons

1. `ShareBtn` on the fleet event page (BreadCrumbs actions), contract page (`#header-right`) and tour details (`#header-right`).
2. A tour shares its invite link when the viewer may invite, otherwise its page.
3. `ShareBtn` in `Fleets/InviteUrlModal`, with the modal passed as `container` so the copy fallback works inside the overlay.

## Intent Verification

- [ ] **Share on phone** — event, contract, tour and invite each open the share sheet on mobile and copy on desktop.
- [ ] **Previews** — a member-visible contract/tour/event link previews with its title; an officers-only or squadron one previews as "… in <Fleet>" and its title appears nowhere in the HTML.
- [ ] **Tour invite** — a viewer who may invite shares `/tools/tours/join/<token>/`.

## Key files

| File                                                                                       | Role                                  |
| ------------------------------------------------------------------------------------------ | ------------------------------------- |
| `app/lib/link_preview.rb`                                                                  | what a preview may say                |
| `app/controllers/concerns/link_preview_rendering.rb`                                       | renders the frontend with that meta   |
| `app/controllers/frontend/fleets_controller.rb`, `tours_controller.rb`                     | preview actions                       |
| `config/routes/frontend_routes.rb`                                                         | contract, tour and tools/tours routes |
| `app/frontend/frontend/components/ShareBtn/index.vue`                                      | share or copy                         |
| `app/frontend/frontend/pages/fleets/[slug]/events/[event].vue`, `contracts/[contract].vue` | detail pages                          |
| `app/frontend/frontend/components/Payouts/TourDetails/index.vue`                           | tour header actions                   |
| `app/frontend/frontend/components/Fleets/InviteUrlModal/index.vue`                         | invite URLs                           |

## Not in scope (deferred)

- **Short or full URLs for events and invites** — waits for the device test on #5233.

## Discovery Log

- **2026-09-29** Research. The event preview named officers-only events. Contract and tour pages fell through to `base#index` with the default meta. Fleet pages render without the frontend prefetch.

## Progress

- [x] Phase 1
- [x] Phase 2
