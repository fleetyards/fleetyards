---
name: start-issue
description: Starts work on a GitHub issue — fetches details, assigns it, creates a branch, and summarises the issue
---

# Start Issue Skill

Kicks off work on a GitHub issue by assigning it, creating a properly named branch, and summarising everything known from the issue. Optionally creates a worktree with full setup and an exec-plan.

## When to Use

- When the user says "let's start issue #1234", "start #1234", "pick up issue #1234", or similar
- When the user provides a GitHub issue number or URL and wants to begin working on it

---

## Workflow

### 1. Parse the issue identifier

Extract the issue number from the argument:
- `#1234` or `1234` → issue number `1234`
- `https://github.com/fleetyards/fleetyards/issues/1234` → issue number `1234`

### 2. Fetch the issue

```bash
gh issue view <number> --repo fleetyards/fleetyards --json number,title,body,labels,milestone,assignees,type
```

Gather:
- **Title**
- **Body / description**
- **Labels** (to determine type)
- **Type** (if issue types are configured)
- **Assignees** (current)
- **Milestone**

If the issue does not exist, tell the user and stop.

### 3. Determine issue type

Decide the branch prefix based on issue signals:

| Signal | Prefix |
|--------|--------|
| Issue type is "Bug" or labels include `bug` | `fix` |
| Labels include `refactoring` | `refactor` |
| Everything else | `feat` |

### 4. Assign the issue to the current user

```bash
gh issue edit <number> --add-assignee @me
```

### 4b. Move the issue to "In Progress" on the project board

Issues live on ProjectV2 #3 ("Fleetyards"). Look up the issue's item on that project and set its Status to **In Progress**:

```bash
ITEM=$(gh api graphql -f query='{repository(owner:"fleetyards",name:"fleetyards"){issue(number:<number>){projectItems(first:5){nodes{id project{number}}}}}}' \
  --jq '.data.repository.issue.projectItems.nodes[] | select(.project.number==3).id')

gh api graphql -f item="$ITEM" -f query='mutation($item:ID!){updateProjectV2ItemFieldValue(input:{
  projectId:"PVT_kwDOAGoNC84AAZg-", itemId:$item,
  fieldId:"PVTSSF_lADOAGoNC84AAZg-zgANg84",
  value:{singleSelectOptionId:"47fc9ee4"}}){projectV2Item{id}}}'
```

If `ITEM` is empty the issue is not on the board — add it with `addProjectV2ItemById` first. If the call fails with a missing `project` scope, ask the user to run `gh auth refresh --hostname github.com --scopes project` in a real terminal, and continue without it.

### 5. Create the branch

Build the branch name:

```
<prefix>/<issue-number>-<english-short-description-in-kebab-case>
```

Rules:
- `<prefix>` is `feat`, `fix`, or `refactor` (from step 3)
- `<issue-number>` is the raw number (e.g. `1234`)
- `<english-short-description>` is derived from the issue title — lowercased, spaces replaced with hyphens, max ~6 words, no special characters
- Example: `feat/1234-add-calendar-sync-settings`

```bash
git fetch origin main
git branch <branch-name> origin/main
git push -u origin <branch-name>
```

If the branch already exists, ask the user whether to reuse it or create a fresh one.

### 6. Connect the branch to the issue

```bash
gh issue develop <number> --branch <branch-name> 2>/dev/null || true
```

### 7. Research and create the exec-plan

Spawn a `researcher` agent with the issue title, body, and labels to identify relevant files, patterns, and constraints.

Based on the issue details and research findings, create an exec-plan at:

```
docs/exec-plans/<branch-slug>.md
```

Where `<branch-slug>` is the part after the prefix slash (e.g. branch `feat/1234-add-calendar-sync` → `1234-add-calendar-sync`).

The plan is the working file for this branch only — it is deleted before the PR merges (see "Issues, PRs and exec-plans" in `AGENTS.md`). Decisions do not go in the plan: once the user settles one, record it in the `## Decisions` section of the issue body (`gh issue edit <number> --body-file <file>`) as `**Decided: …**` with the reasoning and rejected alternatives. The plan links to the issue instead of restating them.

```markdown
# [Issue title]

Working plan for #<number>. Decisions live in the issue body. Deleted before the PR merges.

## Goal
One sentence: what will exist when this is done.

## Open questions
- [Question the user still has to decide — move the answer to the issue body, then remove it here]

## What changed

### Phase 1 — [Phase name]
1. [Concrete change]
2. [Concrete change]

## Intent Verification

- [ ] **[Criterion]** — Observable, verifiable acceptance criteria from the issue

## Key files

| File | Role |
|------|------|
| `path/to/file` | Brief description |

## Not in scope (deferred)
- **[Item]** — Why deferred. Becomes its own issue before the PR merges.

## Discovery Log

- **[today's date]** Initial research and plan creation

## Progress
- [ ] Phase 1
```

If the issue is too vague to make concrete decisions, list the open questions in the plan and flag them to the user.

### 8. Summarise the issue

Print a summary of everything known from the issue:

- **Issue number and title**
- **Type** (bug / feature / refactor)
- **Full description** (from the issue body)
- **Labels**
- **Milestone** (if any)
- **Linked PRs or issues** (if any)
- **Acceptance criteria** (if mentioned in the body)
- **Branch name** that was created
- **Exec-plan path**
- **Brief plan overview** (goal + phases)

### 9. Ask about worktree setup

After presenting the summary, ask the user:

> Want me to create a worktree and run setup?

If the user declines or doesn't respond, stop here. If the user confirms, continue with steps 10-11.

---

## Worktree + Setup (optional, after user confirms)

### 10. Create the worktree

The worktree path is `.worktrees/<branch-slug>` relative to the repository root.

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || git worktree list --porcelain | head -1 | sed 's/worktree //')
git worktree add "$REPO_ROOT/.worktrees/<branch-slug>" <branch-name>
```

If the worktree already exists, ask the user whether to reuse it or remove and recreate.

### 11. Run setup in the worktree

```bash
cd "$REPO_ROOT/.worktrees/<branch-slug>"
bin/setup
```

Let the user know this may take several minutes.

Once complete, print the worktree details and the `cd` command:

```bash
cd .worktrees/<branch-slug>
```

---

## Error Handling

- **Issue not found** → tell the user and stop
- **Branch already exists** → ask whether to reuse or recreate
- **Worktree already exists** → ask whether to reuse or recreate
- **Assignment fails** → continue but warn the user
- **Setup fails** → show the error output, suggest running manually
- **Issue too vague for a plan** → create a skeleton plan with open questions, flag to the user
