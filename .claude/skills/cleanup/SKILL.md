---
name: cleanup
description: Audits the local development state — worktrees, branches, Postgres databases, Redis bands — reports what nothing uses any more, and removes it after the user approves each category
---

# Cleanup Skill

Sweeps the local development state this repository accumulates: git worktrees, local
branches, the Postgres databases `bin/setup` creates per worktree, and the Redis
database bands it allocates alongside them. Reports first, removes only what the user
approves.

## When to Use

- "clean up the branches / worktrees / databases", "aufräumen", "what can go?"
- Disk pressure, or `psql -l` having become unreadable.
- After a run of merged pull requests — every merged branch leaves a worktree, up to 14
  databases and a Redis band behind, and nothing removes them automatically.

Do **not** use it to reclaim space inside a live worktree (`node_modules`, `tmp`, `log`)
— it only removes whole checkouts and their allocated resources.

---

## What a checkout owns

`bin/setup` gives every checkout a set of resources derived from two recorded values in
its `.env.local`. Understanding these is what makes the sweep safe:

| Value | Written to | Owns |
| --- | --- | --- |
| `WORKTREE_SUFFIX` | `.env.local`, `.env.test.local` | `fleetyards_dev<suffix>`, `fleetyards_test<suffix>`, `fleetyards_test<suffix>_<N>` for each parallel test worker |
| `WORKTREE_SLOT` | `.env.local` | a port pair (`8300 + 2N`) and four Redis databases (`4 + 4N`) |

The main checkout writes no `.env.local` at all: it leaves the suffix empty and takes
`fleetyards_dev` / `fleetyards_test` / `fleetyards_test_<N>` plus Redis `db0–db3`.

Two traps live here:

- **The suffix is truncated to 20 characters** (`bin/setup`'s `sanitize_worktree_name`),
  so `notification-call-to-actions` becomes `_wt_notification_call_to`. A database name
  therefore cannot be mapped back to a worktree by reading it — two long names can
  truncate to the same suffix. The audit only ever derives suffixes *forwards*, from the
  worktrees that exist, and treats everything outside that set as orphaned.
- **`fleetyards_test` is a prefix of every worktree's test database.** Never match with
  `LIKE 'fleetyards_test%'`; that deletes the main checkout's suite databases.

A worktree that was never set up (no `.env.local`) owns no database and no Redis band.

---

## Workflow

### 1. Run the audit — read-only

```bash
ruby .claude/skills/cleanup/audit.rb
```

Takes roughly 15 seconds; most of it is `du` and one `gh pr list`. Useful flags:

- `--only=worktrees,dirs,branches,databases,redis` — restrict to categories
- `--no-sizes` — skip `du` and the size columns (much faster)
- `--no-github` — skip the pull-request lookup; every branch then falls back to needing a
  decision, so only for an offline run
- `--json` — machine-readable, same classification

Every row carries one of three verdicts:

- `DROP` — nothing references it any more, and the work it held is provably elsewhere
- `ASK` — removable, but the evidence does not rule out losing work
- `keep` — in use, protected, or unrecognised

### 2. Present the report and ask per category

Show the user the reclaimable totals and the `ASK` rows in full — those are the only
rows that need their judgement. Summarise the `DROP` rows by count and size rather than
listing 400 database names.

Then ask which categories to sweep, with `AskUserQuestion` and `multiSelect: true`. Never
apply everything on the strength of a bare "yes, clean up" — worktree and branch removal
are the two irreversible ones and deserve a named confirmation.

### 3. Apply

```bash
ruby .claude/skills/cleanup/audit.rb --apply --only=databases,redis
```

`--apply` acts on the `DROP` rows of the selected categories only. `ASK` and `keep` rows
are never touched, whatever the user said — to act on an `ASK` row, run the specific
command for it by hand (`git branch -D <name>`, `supacode worktree delete …`).

### 4. Re-run the audit

Removing a worktree orphans the databases and the Redis band it held, which the previous
run still counted as in use. A second pass picks those up. Say so rather than leaving the
user to notice.

---

## How each verdict is reached

### Worktrees

Removed only when the tree is clean **and** its branch's pull request is merged. Held
back when there are uncommitted files, or the pull request is still open. A clean
worktree level with `origin/main` is deliberately an `ASK`: a workspace prepared for work
that has not started looks exactly like one whose work is finished.

Removal goes through `supacode worktree delete` for the worktrees Supacode manages, so
its sidebar state goes with them; the rest go through `git worktree remove`, unlocking
first if needed. Supacode locks every worktree it creates, and it also reconciles in the
background — a worktree in `git worktree list` but absent from `supacode worktree list`
may vanish on its own between two runs.

### Leftover directories

Directories under `.worktrees/` that `git worktree list` does not know about — what a
`rm -rf` without `git worktree remove` leaves behind, plus empty parents from branch
names containing a slash (`.worktrees/feat/`). Always `DROP`; `--apply` refuses any path
that resolves outside `.worktrees/`.

### Branches

**Squash merges are the rule here**, so a merged branch is never an ancestor of `main`
and `git branch --merged` cannot see it. The pull request's state is the only reliable
evidence that the work landed, which is why the audit joins against one `gh pr list`.

- merged pull request → `DROP`
- no commits beyond `origin/main` → `DROP` (nothing to lose)
- open pull request, or checked out in a worktree → `keep`
- `main` and `parked/*` → `keep`, never offered. `parked/visual-baselines` is the only
  home of the visual-baseline suite; it exists nowhere else.
- `backup/*` → always `ASK`, never automatic
- closed unmerged, or never opened as a pull request → `ASK`, with the count of commits
  that would be lost

Deletion is `git branch -D`, batched. `-d` would refuse every squash-merged branch.

### Postgres databases

Everything matching `fleetyards%` is listed, then measured against one keep-pattern per
existing checkout. A database left over is dropped with `WITH (FORCE)` (Postgres 13+),
which terminates the connections a crashed test run leaves behind — without it the drop
fails with `PG::ObjectInUse`.

Names that match neither a checkout nor `fleetyards_dev_*` / `fleetyards_test_*` are
reported as unrecognised and left alone (`fleetyards_stack_scratch`, for instance).

### Redis

`info keyspace` lists the databases holding keys. Anything outside `db0–db3` and the
bands of the live worktrees' recorded slots is flushed with `flushdb`. A slot with no
`.env.local` to read is not reserved, so its band shows as orphaned — correct, since a
worktree that never ran `bin/setup` never wrote to Redis either.

---

## Never touched

- The main checkout, its databases, and `db0–db3`.
- `dumps/`, `storage/`, `data/sc_data/raw`, `data/sc_data/parsed` — `bin/setup` symlinks
  these from the main checkout into every worktree, so one download serves all of them.
  Deleting them from a worktree deletes the shared original.
- Remote branches. This skill is local-only; it never pushes and never deletes on the
  remote.
- Docker volumes. `bin/setup --fresh` wipes those, and it affects every worktree at once.

## Error Handling

- **Postgres or Redis unreachable** → the section reports it and the rest of the audit
  still runs. Start the services with `docker compose up -d`.
- **`gh` unauthenticated** → every branch falls back to `ASK`. Say so rather than
  presenting a report that looks like nothing can go.
- **`git worktree remove` refuses** → the tree is dirty or locked and the audit
  misjudged it; report the error, do not force.
- **A `DROP` the user disagrees with** → treat it as a bug in the classification and say
  which signal produced it, rather than working around it by hand.
