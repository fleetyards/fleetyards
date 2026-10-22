---
name: resolve-foci-import
description: Resolves a "Focus wording we cannot place" GitHub issue by mapping each unknown part onto a focus key in Models::FocusMapping, or adding a new key
---

# Resolve Foci Import Skill

Processes a "Focus wording we cannot place" issue, opened by `Models::UnplacedFoci` after a ship matrix import or a game-file load. Each `###` section is one part of a focus, as the ship matrix (`rsi_focus`) or the game files (`sc_role`) word it, that `Models::FocusMapping` has no entry for.

## When to Use

- When the user references a "Focus wording we cannot place" issue (e.g. "resolve foci import #5950")
- When the user pastes the URL of one

---

## Workflow

### 1. Fetch the issue

```bash
gh issue view <number> --repo fleetyards/fleetyards --json number,title,body
```

Each `### <part>` heading is a lower-cased part; the list below it names the ships and the full wording each source gave.

### 2. Read the vocabulary

- `app/services/models/focus_mapping.rb` — `PARTS` maps a part onto keys; `TIERS` strips "light/medium/heavy" except on fighters; `SILENT` lists parts that say nothing a key does
- `app/models/model.rb` — `FOCI`, the keys in display order, and `FOCUS_UMBRELLAS`

### 3. Decide each part

| The part | Fix |
|----------|-----|
| A new spelling of something a key already says ("Freighter" for `freight`) | One `PARTS` line onto that key |
| A role a key already covers under another name ("Escort" for `fighter`) | One `PARTS` line, but **ask the user first**: it decides what the filter finds |
| Says nothing about what the ship is for ("Multi-Role") | Add it to `SILENT` |
| A genuinely new role | **Ask the user.** A new key goes into `FOCI` in display order, gets a label under `filter.model.focus.items.<key>` in all seven `config/locales/*/filter.yml`, and needs `bin/generate-schema` for the enum |
| Only stealth ("Stealth Bomber") | Already handled by the `stealth` flag; map the rest of the part |

### 4. Fix the ships already listed

A new `PARTS` line only applies to the next load that rewords a ship. For the ships in the issue, write a data migration in `db/data/` that sets their `foci` from the mapping (`::Model.normalize_value_for(:foci, ...)` adds the umbrellas), or ask the user to set them in admin.

### 5. Test and report

Add a case to `test/services/models/focus_mapping_test.rb` for each new line, run it with `PARALLEL_WORKERS=1 bin/rails test test/services/models`, and tell the user which parts were mapped, which need their decision, and which ships the data migration changes.
