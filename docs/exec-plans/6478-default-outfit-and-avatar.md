# Default outfit with character and generated avatar

Working plan for #6478. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A user marks one outfit as their default; the dressing room opens on it, the public hangar links to it, and two head-and-shoulders renders of it (with and without helmet) can be chosen as the avatar.

## What changed

### Phase 1 — Backend
1. Migration: `users.default_outfit_id` (FK, nullify on delete), `users.avatar_source` (integer enum: uploaded, character_helmet, character_bare).
2. `User`: `belongs_to :default_outfit`, `has_one_attached :character_avatar_helmet`/`:character_avatar_bare`, `shown_avatar` (falls back to the upload when no default outfit or render), `AVATAR_PRELOADS`, `with_avatars` scope.
3. Outfits API: `default` in the outfit payload and in create/update input.
4. `PUT /users/me`: `characterAvatarHelmet`, `characterAvatarBare` (signed ids), `avatarSource`; `/users/me` returns them plus `shownAvatar`.
5. Every user-avatar serialization site renders `shown_avatar`; preloads use `User::AVATAR_PRELOADS`.
6. Public user: `defaultOutfit` (body, held weapon, item slugs, stored items, character token) when the hangar is public; cache key bumped.

### Phase 2 — Frontend
1. Outfits list: mark/unmark default.
2. Dressing room: a bare visit with nothing remembered loads the default outfit.
3. HoloViewer `capture()`: renders a head shot of the loaded figure to a PNG blob.
4. Dressing room: saving the default outfit renders both avatars off screen and uploads them.
5. Settings → profile: pick uploaded / with helmet / without helmet.
6. Nav and own-user surfaces read `shownAvatar`.
7. Public hangar heading: link to the character in the dressing room.
8. Translations in every locale.

## Intent Verification
- [ ] Only one default per user; deleting it clears it
- [ ] Dressing room opens on the default outfit
- [ ] Renders upload on save of the default outfit; settings switches the shown avatar
- [ ] Fleet/member/friend lists show the chosen avatar

## Key files

| File | Role |
|------|------|
| `app/models/user.rb` | default outfit, render attachments, shown avatar |
| `app/controllers/api/v1/outfits_controller.rb` | default flag |
| `app/controllers/api/v1/users_controller.rb` | render uploads, source |
| `app/frontend/frontend/pages/tools/dressing-room.vue` | open on default, render avatars |
| `app/frontend/shared/components/HoloViewer/index.vue` | capture |
| `app/frontend/frontend/pages/settings/profile.vue` | avatar source picker |

## Discovery Log
- **2026-11-23** Initial research: no shared avatar URL helper; ~20 jbuilder sites and ~25 preloads read `avatar` directly.

## Progress
- [ ] Phase 1
- [ ] Phase 2
