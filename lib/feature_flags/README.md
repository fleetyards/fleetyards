# FeatureFlags

Makes `config/feature_flags.yml` the **single source of truth** for Flipper
feature flags, replacing hand-written `Flipper.add` data migrations.

## Why

Flags used to be created by a `db/data` migration per flag. That worked, but the
flag list only existed in the database: there was no reviewable inventory, no
description of what a flag does, and nothing noticed when a flag outlived the
code that read it — `hardpoints-v2` sat in Flipper for months after #4176 deleted
its last reference. A version-controlled registry makes the inventory a PR diff
and lets a deploy reconcile reality with it.

The registry owns the flag **list**, the self-service each flag **starts** with,
and which surface that self-service lives on. The admin UI still owns each flag's
**gates** (boolean, actors, groups, percentages) and its
`feature_settings.self_service` from then on, which is what decides whether the
flag may be toggled outside `/admin/features` at all.

Creating and deleting flags through the admin UI was removed along with this
change. It could not coexist with pruning: a flag added there has no registry
entry, so the next deploy deleted it and every gate configured on it.

## Components

| File | Purpose |
| --- | --- |
| `config/feature_flags.yml` | Registry — per flag: `description`, optional `permanent`, `self_service` (`user` or `fleet`) |
| `FeatureFlags::Registry` | Loads and validates the YAML (naming, required/known keys) |
| `FeatureFlags::Definition` | Value object for one flag (`name`, `description`, `permanent?`, `self_service?`, `self_service_scope`) |
| `FeatureFlags::Synchronizer` | Reconciles Flipper with the registry: adds missing, seeds self-service, prunes orphaned |
| `bin/feature-flags` | CLI: `validate`, `plan`, `sync`, `export` |

Rails autoloads `lib/` (`config.autoload_lib`), so these classes carry no
requires of their own. `bin/feature-flags` is the one place that has to know
their load order, because `validate` runs without booting Rails.

## CLI

```bash
bin/feature-flags validate   # validate the schema — no Rails, no database (CI runs this)
bin/feature-flags plan       # dry run: what would sync change?
bin/feature-flags sync       # apply (add + prune) — runs on every deploy
bin/feature-flags export     # print a YAML skeleton of the live Flipper state
```

## Adding a flag

1. Add an entry to `config/feature_flags.yml`:

   ```yaml
   my_new_flag:
     description: "What this toggles"
     self_service: user  # optional — see Self-service scopes below
   ```

2. Validate: `bin/feature-flags validate`.
3. Merge → `.kamal/hooks/pre-deploy` runs `bin/feature-flags sync` and creates the flag,
   **off** by default, with its self-service setting seeded from the registry.
4. Turn it on per user, per fleet, or globally at `/admin/features`.

Sync seeds `self_service` once and never overwrites it, so the admin toggle at
`/admin/features` survives every deploy — and dropping the key from the registry
retracts nothing. Untoggle it there instead.

## Self-service scopes

`self_service` says *who* owns the toggle, not just that one exists:

| Value | Fleet-wide switch lives at | Who may flip it |
| --- | --- | --- |
| `user` | nowhere — the flag is personal | — |
| `fleet` | a fleet's Settings → Features | members holding `fleet:manage` |
| `true` | alias for `user` | — |
| omitted | nowhere | `/admin/features` only |

The scope says where the **fleet-wide** switch lives. Every self-service flag,
whatever its scope, also keeps a **personal** toggle in Settings → Features:
enabling a fleet flag there is a preview for that one user and never switches the
feature on for the rest of the fleet, because Flipper gates each actor
separately.

The two do not fight. A fleet's grant covers every member and cannot be
overridden per user — the backend ORs both actors — so once a user's fleet has
the flag on, `GET /user-features` reports the row as `enabled`, names the fleets
responsible in `fleets`, and `enable`/`disable` return 403 rather than reporting
a change the user would not see.

Pick `fleet` when the feature belongs to a whole fleet. A member must not be able
to switch one on for everyone, and because the backend gate ORs the user actor in
(`Flipper.enabled?(flag, user, fleet)`), a user-scoped toggle on a fleet feature
would let them do exactly that in every fleet they belong to.

Unlike `self_service`, the **scope is reconciled on every sync**: it describes
which surface the code reads the flag from, so a release that moves a flag from
personal settings to a fleet's has to take effect rather than wait for an admin.

Read a fleet-scoped flag against the fleet — `Flipper.enabled?(:my_flag, fleet)`
in Ruby (or `feature_enabled?(:my_flag, @fleet)` in a controller, which ORs the
current user in), and `isFleetFeatureEnabled(fleet, FeatureFlagName.MY_FLAG)` in
Vue off the fleet payload's `features`. A route behind one needs
`featureScope: "fleet"` in its meta so the router guard consults the fleet rather
than the viewer.

Read it in code exactly as before: `Flipper.enabled?(:my_new_flag, actor)` in Ruby,
`isFeatureEnabled('my_new_flag')` in Vue.

Locally, `bin/feature-flags sync` creates the flag in your dev database.

`permanent: true` marks a long-lived infrastructure gate (the OAuth provider
flags, for example) rather than a temporary rollout expected to be cleaned up. It
is metadata only — it does not change how the flag evaluates.

## Removing a flag

Delete its entry and merge. The next deploy's sync removes the Flipper feature
**and all of its gate values** — boolean state, actors, groups, percentages —
along with its `FeatureSetting` row, so a flag does not come back self-service
if it is ever declared again.

That is irreversible: re-adding the entry later gives you a fresh flag with no
gates and no self-service, so record any rollout you still care about first.

An interrupted sync is safe to re-run. The `FeatureSetting` cleanup is keyed on
the registry, not on what the current run removed, so it also clears rows
stranded by a run that died after deleting the Flipper feature.

## Safety

The YAML is the only thing standing between a flag and deletion, so:

- `bin/feature-flags plan` prints every planned change. Run it against the target
  environment before a deploy that removes entries and check the `Removed` list.
- An invalid registry aborts before Flipper is touched (`Registry.load` raises),
  so a malformed file cannot prune anything. A *well-formed* file with a missing
  entry **will** prune it — review this file like you would a migration.
- `bin/feature-flags export` prints the live state as a YAML skeleton, to reconcile
  the registry against reality.
- `FEATURE_FLAGS_PRUNE=false` disables removal for a single run — an emergency
  brake, not part of the normal workflow.
