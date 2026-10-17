---
name: review-loop
description: Reviews the current branch in rounds — local /code-review plus unresolved PR review threads when a PR exists — fixes what holds up, and after every round decides whether another is worth running; stops when a round finds nothing new or the rounds start circling the same changes
---

# Review Loop Skill

Runs review → triage → fix rounds on the current branch until the work settles. Every round ends with an explicit decision: another round, or stop. Stopping because the loop is going in circles is a valid result, not a failure. Report it.

## When to Use

- "review this in a loop", "keep reviewing until it's clean", "address the review comments"
- As the last step of an implementation task, before handing the PR back (see the memory `run-until-pr-reviewed`)

## Arguments

- Effort level for `/code-review` (`low`…`max`). Default `medium`. Lower it by one level each round after the first, never below `low`: later rounds should only check the fixes.
- `--max-rounds <n>`. Default 5. This is a hard cap, not a target.

---

## Sources

Each round collects findings from both sources:

1. **Local review:** the `code-review` skill on the branch diff against `origin/main`. If the branch is stacked, diff against its PR's base ref instead (`gh pr view --json baseRefName`). Rebasing a stack onto main inflates the diff.
2. **PR review threads**, only when the branch has an open PR (`gh pr view --json number,url` succeeds). Fetch the **unresolved, non-outdated** threads:

   ```bash
   gh api graphql -f query='
     query($n:Int!){repository(owner:"fleetyards",name:"fleetyards"){pullRequest(number:$n){
       reviewThreads(first:100){nodes{id isResolved isOutdated path line
         comments(first:20){nodes{databaseId author{login} body}}}}}}}' -F n=<number> \
     --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved|not) | select(.isOutdated|not)'
   ```

   Also read the top-level PR comments and review summaries (`gh pr view <n> --json comments,reviews`). Bots sometimes put findings there instead of in a thread.

   Skip a thread when the last comment is already a reply from us, unless the reviewer has answered since.

   **Devin** (`devin-ai-integration`) is the usual bot reviewer. Each comment starts with `<!-- devin-review-comment {...} -->` metadata. Its id prefix is `BUG_` for a claimed defect or `ANALYSIS_` for an observation. Treat `ANALYSIS_` as lower priority, since it often needs no code change. Devin resolves its own threads after a reply it accepts, so do not resolve its threads yourself. Human reviewers' threads are also never resolved by us.

## Round

### 1. Collect

Gather the findings from both sources. Give each one a **fingerprint**: `file` + the function or area it concerns + the kind of problem, in a few words (e.g. `fleet_membership.rb#health_scope — N+1`). Line numbers are not part of it, because they move between rounds.

### 2. Triage

Verify each finding against the code before you act on it. Classify it as:

- **fix:** the finding is real and in scope for this branch.
- **reject:** a false positive, or a disagreement with a stated repo convention. Write a one-line reason. Known false positives in this repo:
  - hand edits to `swagger/**/schema.yaml` (the memory `hand-editing-generated-schema-is-fine`; point at the passing `api-schema-check`)
  - code that follows AGENTS.md even where surrounding code differs (`docs-win-over-surrounding-code`)
- **out of scope:** a real problem that this branch didn't cause. Don't fix it here. Mention it in the report. Don't file an issue unless asked.

### 3. Fix

Apply the fixes. Keep commits small: one logical change per commit, conventional-commit subject, no AI trailer. Run the checks that cover what you touched: `bin/rails test <files>`, `pnpm test <files>`, `pnpm lint:ts` (use its exit code), and bare `bin/ruby-lint` after any Ruby or view change. Never run the full suite locally.

### 4. Answer the PR threads

If a PR exists, reply to every thread that you triaged this round. Replies end with 🤖.

- **fix:** say what changed and name the short sha.
- **reject:** give the reason, short and specific, with a reference where one exists (a CI run, a convention, a test).
- **out of scope:** say so, and say where it belongs.

```bash
gh api repos/fleetyards/fleetyards/pulls/<n>/comments/<first comment databaseId>/replies -f body='…'
```

Push the branch after the commits and before the replies, so a sha in a reply exists on the remote. Pushing to the PR's own branch is part of this task. Do not push anywhere else. After a push, check that the remote tip matches the local one (`git rev-parse HEAD @{u}`).

### 5. Log the round

Append an entry to the round log in the scratchpad (`review-loop.md`): each fingerprint with its verdict, the commits made, and the files and line ranges they changed. The loop check reads this log.

---

## Decide: another round?

Check these in order. The first one that matches decides.

**Stop: going in circles.** Any of these means the rounds are no longer converging:

- A finding matches the fingerprint of one that an earlier round **fixed**. The fix either didn't hold or caused the same problem again.
- A finding matches one that an earlier round **rejected**, and nothing new has been said. Don't flip a reject to a fix just because the finding was raised again.
- A fix would undo, or mostly restore, lines that an earlier round changed (A → B → A). Compare the planned hunk with the log before applying it.
- Two consecutive rounds changed the same area for the same kind of finding, e.g. naming, comment wording, or a style rewrite.
- The fixes are getting bigger while the findings get smaller (nits that need rewrites).

When it is going in circles: **do not apply the circling change**. Stop and report both positions, the earlier change and the newly proposed one, so the user can pick.

**Stop: settled.** The round produced no **fix** verdicts, or only cosmetic ones that you rejected with a reason. Don't wait for a bot or human review of the last push: threads that already exist were triaged this round, and anything that arrives later is handled in a new run.

**Stop: cap reached.** `--max-rounds` reached. Report what is still open.

**Otherwise, run another round.** It reviews only the commits made since the last round, plus any new PR threads.

---

## Report

Give one summary at the end:

- Rounds run and why it stopped (settled, going in circles, or cap reached).
- Fixes, as commit shas with a one-line description each.
- Rejections, each with its reason (these are where the user might disagree).
- Out-of-scope findings.
- If it stopped going in circles: the two competing versions of the change, side by side.
- PR threads still open, with links.
