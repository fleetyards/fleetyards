---
name: start-task
description: Starts work on a new task — asks what the user wants to do, creates a GitHub issue, branch, exec-plan, and optionally a worktree
---

# Start Task Skill

Kicks off work on a new task by asking the user what they want to do, creating a GitHub issue, then following the same flow as `start-issue`: branch, assign, exec-plan, and optionally worktree + setup.

## When to Use

- When the user says "I want to work on something", "start a new task", "new feature", "new fix", or similar
- When the user describes work they want to do but there's no existing GitHub issue for it

---

## Workflow

### 1. Ask the user what they want to do

If the user hasn't already described the task, ask:

> What do you want to work on?

Wait for the user's response. Gather enough context to create a meaningful issue.

### 2. Clarify if needed

If the description is too vague to create a useful issue, ask follow-up questions:

- What area of the app does this affect?
- Is this a new feature, a bug fix, or a refactoring?
- Any specific acceptance criteria or expected behavior?

Keep it to 1-2 follow-up questions max — don't interrogate.

### 3. Determine issue type

Based on the user's description:

| Description | Type | Label |
|-------------|------|-------|
| Bug, broken behavior, regression | Bug | `bug` |
| Refactoring, cleanup, restructuring | Refactoring | `refactoring` |
| Everything else | Feature | (none required) |

### 4. Create the GitHub issue

```bash
gh issue create \
  --repo fleetyards/fleetyards \
  --title "<concise title>" \
  --body "<structured body>" \
  --assignee @me \
  [--label "bug" if applicable] \
  [--label "refactoring" if applicable]
```

The issue body should follow this structure:

```markdown
## Description

[Clear description of what needs to be done, based on the user's input]

## Acceptance Criteria

- [ ] [Criterion 1]
- [ ] [Criterion 2]

## Notes

[Any additional context from the conversation]
```

Show the created issue URL to the user.

### 5. Continue with the start-issue flow

From here, follow the exact same steps as the `start-issue` skill starting from **step 5** (assign is already done via `--assignee @me`):

- **Create the branch** (`feat/`, `fix/`, or `refactor/` prefix + issue number + kebab-case description)
- **Push the branch** and connect it to the issue
- **Research** the codebase and **create the exec-plan** at `docs/exec-plans/<branch-slug>.md`
- **Summarise** the issue with branch name, exec-plan path, and plan overview
- **Ask about worktree**: "Want me to create a worktree and run setup?"
- If confirmed: create worktree at `.worktrees/<branch-slug>` and run `bin/setup`

Refer to the `start-issue` skill for the detailed steps and templates.

---

## Error Handling

- **User description too vague** → ask follow-up questions (max 2)
- **Issue creation fails** → show the error, suggest the user create it manually
- **All other errors** → same as `start-issue` skill error handling
