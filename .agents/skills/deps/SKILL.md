---
name: deps
description: Triages the open Dependabot PR queue — classifies each bump, checks CI and intentional pins, merges the safe ones and reports what needs a human decision
---

# Deps Skill

Works through the open Dependabot pull requests on `fleetyards/fleetyards`. Merges patch and minor bumps whose CI is green, and stops with a recommendation for everything else.

## When to Use

- "triage the deps", "deal with the dependabot PRs", "merge the safe dependency updates"
- When the `dependencies` queue has built up. Dependabot runs **daily** here with limits of 10 bundler / 10 npm / 5 docker / 5 github-actions, so it builds up faster than in the other repos.

## Repo facts

- Ecosystems: `bundler`, `npm`, `docker`, `github-actions`. Labels are configured explicitly: `dependencies` plus one of `ruby`, `javascript`, `docker`, `github-actions`.
- npm bumps are grouped for `tailwindcss` / `@tailwindcss/*` and `playwright` / `@playwright/*`.
- **Squash only** (`mergeCommitAllowed: false`). Branches are deleted on merge.
- `main` is protected by the **"Main branch protection" ruleset** — 11 required status checks plus a **merge queue**. The classic `branches/main/protection` API returns 404 here; that means "no *classic* protection", not "unprotected". Query rulesets instead:

  ```bash
  gh api repos/fleetyards/fleetyards/rulesets --jq '.[].id' | while read id; do
    gh api "repos/fleetyards/fleetyards/rulesets/$id" \
      --jq '.rules[] | select(.type=="required_status_checks") | .parameters.required_status_checks[].context'
  done
  ```

- Auto-merge and update-branch are both enabled, so `--auto` is available.
- Ruby gems are vendored: bundler PRs also touch `vendor/cache/*.gem`. Normal, not a red flag.
- PR titles are conventional commits and become the squash subject, which feeds release-please's CHANGELOG. Never rewrite the title on merge.

---

## Workflow

### 1. Pull the queue

```bash
gh pr list --repo fleetyards/fleetyards --label dependencies --limit 50 \
  --json number,title,labels,mergeStateStatus,files \
  --jq '.[] | "\(.number)\t\(.mergeStateStatus)\t\(.title)"'
```

If the queue is empty, say so and stop.

### 2. Classify each PR

Parse `bump <name> from <old> to <new>` out of the title:

| Condition | Class |
|-----------|-------|
| `old.major != new.major` | **major** |
| `old.major == 0` and `old.minor != new.minor` | **major** (0.x minors are breaking) |
| `old.minor != new.minor` | minor |
| otherwise | patch |

A grouped PR (`tailwindcss`, `playwright`) carries several packages — classify it by its **highest** bump class, reading the versions out of the PR body.

### 3. Run the safety gates

A PR is **safe to merge** only if every gate passes.

#### Gate A — bump class is patch or minor

Majors always go to the report for a human, even with green CI.

#### Gate B — CI is green

```bash
gh pr view <number> --repo fleetyards/fleetyards \
  --json statusCheckRollup \
  --jq '[.statusCheckRollup[] | select(.conclusion != "SUCCESS" and .conclusion != "SKIPPED" and .conclusion != "NEUTRAL")] | map("\(.name): \(.conclusion // .status)") | .[]'
```

Empty output means green. A `PENDING` check means "come back later", not "merge it" — though with auto-merge available you may enqueue it instead (step 4).

The ruleset already requires the important checks, so GitHub will block a red merge. Still check explicitly: it gives a useful report and catches non-required checks that failed.

#### Gate C — no intentional pin is being undone

This is the gate that matters most, and CI will not catch it.

For **bundler** PRs, check whether the PR touches `Gemfile` itself:

```bash
gh pr diff <number> --repo fleetyards/fleetyards | grep -E '^(diff --git|[-+]gem )'
```

- Only `Gemfile.lock` and `vendor/cache/*` changed → fine.
- The `gem` line tightens a pessimistic constraint to the new minor (`"~> 4.0"` → `"~> 4.1"`) → fine.
- An **upper bound is removed or loosened** → stop and read the comment above the pin. Deliberate pins here carry a comment explaining the constraint and the condition for lifting it.

```bash
grep -B4 'gem "<name>"' Gemfile   # unanchored: gems inside group blocks are indented
```

Pins in `Gemfile` at the time of writing:

- `gem "redis", "< 6"` — ActionCable's redis pubsub adapter declares `>= 4, < 6`, so redis 6 raises `Gem::LoadError` on boot. Hold until Rails ships the redis-client-based adapter (8.2+).
- `gem "kamal", "2.11.0"` — 2.12.0 intermittently resets the second back-to-back `kamal app exec` SSH connection in the pre-deploy hook (`Errno::ECONNRESET`).

For **npm** PRs a `package.json` change is expected on every bump and is not a signal by itself. Look instead for an **exact** version (no `^`/`~`) of the package being bumped — an exact pin is usually deliberate.

Check `git log` for a prior manual pin, the strongest evidence a bump has been rejected before:

```bash
git log --oneline -5 --grep="<package-name>"
```

#### Gate D — mergeable state

`BEHIND` means the PR needs a rebase. Ask Dependabot and re-check next run rather than blocking:

```bash
gh pr comment <number> --repo fleetyards/fleetyards --body "@dependabot rebase"
```

`DIRTY` (conflicting) is best fixed with `@dependabot recreate`. `UNKNOWN` means GitHub is still computing mergeability — re-poll before deciding. `BLOCKED` means a required check has not passed.

### 4. Merge the safe ones

```bash
gh pr merge <number> --repo fleetyards/fleetyards --squash
```

Because `main` has a merge queue, this enqueues the PR rather than merging it on the spot. Confirm it landed rather than assuming. If checks are still pending but everything else passes, `--squash --auto` is the better call.

Keep the generated squash subject — it is already a valid conventional commit and release-please parses it.

Merge one at a time. Each bundler merge pushes the remaining bundler PRs `BEHIND`; don't re-run the gates on the whole queue after every merge — merge the batch, then post `@dependabot rebase` on the bundler PRs still open at the end.

### 5. Report

Group by outcome:

```
Merged / enqueued (N)
  #4360  patch  ruby  oj 3.17.5 → 3.17.6

Held — needs a decision (N)
  #4343  major  ruby  redis 5.4.1 → 6.0.0
         Deletes the deliberate `gem "redis", "< 6"` pin. CI is green, but the
         ActionCable adapter declares < 6. Hold until Rails 8.2.

Rebasing (N)
  #4361  minor  ruby  openapi-ruby 4.0.1 → 4.1.0 — was BEHIND, asked for rebase

Red CI (N)
```

For each held major, say *why* in one line and what would unblock it — read the release notes in the PR body (`gh pr view <n> --json body`) so the reason is concrete rather than "it's a major".

Do not merge anything in the held list without the user saying so.

---

## Error Handling

- **`gh` not authenticated** → tell the user to run `gh auth login` and stop.
- **Merge rejected** → report the error, leave the PR open, continue with the rest of the queue.
- **Most of the queue still running CI** → merge what is green, list the pending ones, suggest re-running later.
- **Failure looks like flake** (e2e especially) → do not merge; offer `gh run rerun <run-id> --failed` and re-check.
