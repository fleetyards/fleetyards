# Fleet roles: an explicit default role for new members

Working plan for #5379. Decisions live in the issue body. Deleted before the PR merges.

## Goal

Each fleet has exactly one default role that new members get, and fleets can rename their roles from a modal on the Roles page.

## Open questions

None.

## What changed

### Phase 1 — Data model
1. `fleet_roles.default_role` (boolean, not null, default false) with a partial unique index per fleet. The backfill marks each fleet's lowest-ranked non-permanent role.
2. `FleetRole`: Admin (permanent) can't be the default, and the default can't be cleared, only moved. `make_default!` runs under the fleet's row lock. The default role can't be destroyed. `setup_default_roles!` seeds Member as the default.
3. The slug stays fixed once a role is created. Promote/demote in `MemberActions` checks `admin`/`member` slugs, so a rename must not move them.
4. `Fleet#default_member_role` reads the flag and falls back to `ranked.last` for a fleet created while the column was migrated in.
5. `PurgedFleetRestorer` matches roles by slug, keeps the latest snapshot per role, and restores the default.

### Phase 2 — API
1. `PUT /fleets/{slug}/roles/{id}` renames a role. `FleetRolePolicy#update?` needs `fleet:manage`, `fleet:roles:manage` or `fleet:roles:update`.
2. The extended role payload carries `defaultRole`.
3. An `update_roles` capability.
4. The member `role` filter matches the role slug, not its name, so the filter survives a rename.

### Phase 3 — Frontend
1. Roles page: a "(Default)" badge, and an edit button opening `FleetRoleModal` (the name, plus the default as a disabled checkbox).
2. The members filter builds its role options from the fleet's roles (value slug, label name).
3. Translations in all seven locales.

## Intent Verification

- [ ] **Exactly one default:** existing fleets get their lowest non-permanent role as the default, and new fleets get Member.
- [ ] **New members get it:** invites, invite links, join requests and the restorer use the default role.
- [ ] **Guarded:** the default can't be destroyed or cleared, and Admin can't be the default.
- [ ] **Rename:** a role with `fleet:roles:update` renames a role. Promote/demote and the role filter keep working after the rename.

## Key files

| File | Role |
|------|------|
| `app/models/fleet_role.rb` | Default flag, slug, seeding |
| `app/models/fleet.rb` | `default_member_role` |
| `app/models/fleet_membership.rb` | `role` ransack alias |
| `app/services/fleets/purged_fleet_restorer.rb` | Role restore |
| `app/controllers/api/v1/fleet_roles_controller.rb` | Rename endpoint |
| `app/frontend/frontend/pages/fleets/[slug]/settings/roles.vue` | Roles page |
| `app/frontend/frontend/components/Fleets/MembersFilterForm/index.vue` | Role filter options |

## Not in scope (deferred)

- **Creating, reordering or re-privileging roles:** fleets can't do any of these today, and the issue doesn't ask for it.

## Discovery Log

- **2026-10-02** No role editing exists anywhere, the admin pages included: the three roles are only ever seeded. The member `role` filter matches the role name case-insensitively, and `MemberActions` keys promote/demote on the slugs `admin` and `member`.

- **2026-10-02** `default_role` is a name Active Record reserves (connection roles), so the column is `new_member_default`, and the API still says `defaultRole`. The members `role` filter never applied: `role` was missing from the ransack allowlist, and FleetRole allowed no attributes. A disabled FormToggle still registers with the vee form, so the modal sends its payload explicitly.

## Progress

- [x] Phase 1 — Data model
- [x] Phase 2 — API
- [x] Phase 3 — Frontend
