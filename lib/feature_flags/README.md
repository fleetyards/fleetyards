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

The registry owns the flag **list**, and nothing else about a flag's behaviour.
The admin UI owns its **gates** (boolean, actors, groups, percentages) and its
self-service — a switch per surface the flag may be toggled on outside
`/admin/features`. The registry cannot declare either, and sync never writes
them.

Creating and deleting flags through the admin UI was removed along with this
change. It could not coexist with pruning: a flag added there has no registry
entry, so the next deploy deleted it and every gate configured on it.

## Components

| File | Purpose |
| --- | --- |
| `config/feature_flags.yml` | Registry — per flag: `description`, optional `permanent` |
| `FeatureFlags::Registry` | Loads and validates the YAML (naming, required/known keys) |
| `FeatureFlags::Definition` | Value object for one flag (`name`, `description`, `permanent?`) |
| `FeatureFlags::Synchronizer` | Reconciles Flipper with the registry: adds missing, prunes orphaned |
| `FeatureSetting` | The self-service decision — one boolean per surface a toggle can live on. Written only by `/admin/features` |
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
   ```

2. Validate: `bin/feature-flags validate`.
3. Merge → `.kamal/hooks/pre-deploy` runs `bin/feature-flags sync` and creates the flag,
   **off** by default, with no self-service toggle.
4. Turn it on per user, per fleet, or globally at `/admin/features`.
5. Hand out a toggle, if the flag should have one, under **Self-Service** on the
   same page: **Users can toggle** for a personal one, **Fleet admins can
   toggle** for a fleet-wide one, either or both.

Step 5 is the admin UI's alone. Sync never writes `feature_settings`, in either
direction, so a deploy can neither hand out a toggle nor take one away — which
also means a new flag arrives with no toggle until somebody grants it one, on a
fresh development database included.

## Self-service scopes

Two independent booleans, one per surface, both set at `/admin/features`:

| Column | Switch lives at | Who may flip it |
| --- | --- | --- |
| `self_service_user` | Settings → Features | the user, for themselves |
| `self_service_fleet` | a fleet's Settings → Features | members holding `fleet:manage` |

They started life as one boolean and an exclusive `user`/`fleet` scope, which did
not fit: a fleet feature wants **both**, because the personal switch on one is a
preview for that member alone and never reaches the rest of the fleet — Flipper
gates each actor separately. So `fleet` had to mean "as well as user", the pair
could not express a fleet switch without a personal one, and reading the enum
told you neither surface reliably.

Turn on both for a fleet feature you also want members to be able to preview,
`self_service_fleet` alone for one only a fleet's admins should reach.

The two do not fight. A fleet's grant covers every member and cannot be
overridden per user — the backend ORs both actors — so once a user's fleet has
the flag on, `GET /user-features` reports the row as `enabled`, names the fleets
responsible in `fleets`, and `enable`/`disable` return 403 rather than reporting
a change the user would not see.

Grant `self_service_fleet` when the feature belongs to a whole fleet. A member
must not be able to switch one on for everyone, and because the backend gate ORs
the user actor in (`Flipper.enabled?(flag, user, fleet)`), reading a fleet
feature against the user would let them do exactly that in every fleet they
belong to.

Read a fleet-scoped flag against the fleet — `Flipper.enabled?(:my_flag, fleet)`
in Ruby (or `feature_enabled?(:my_flag, @fleet)` in a controller, which ORs the
current user in), and `isFleetFeatureEnabled(fleet, FeatureFlagName.MY_FLAG)` in
Vue off the fleet payload's `features`. A route behind one needs
`featureScope: "fleet"` in its meta so the router guard consults the fleet rather
than the viewer.

Read it in code exactly as before: `Flipper.enabled?(:my_new_flag, actor)` in Ruby,
`isFeatureEnabled('my_new_flag')` in Vue.

Locally, `bin/feature-flags sync` creates the flag in your dev database — off, and
with no self-service toggle until you grant one at `/admin/features`.

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
