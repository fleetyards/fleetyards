---
name: resolve-loaners-import
description: Resolves a Missing Loaners GitHub issue by analyzing missing models/loaners and updating loaner_loader.rb mappings
---

# Resolve Loaners Import Skill

Processes a "Missing Loaners" GitHub issue created by `Loaders::LoanerJob`. Analyzes missing models and missing loaners, then updates `app/lib/rsi/loaner_loader.rb` with the needed mappings.

## When to Use

- When the user references a "Missing Loaners" GitHub issue (e.g., "resolve loaners import #3550")
- When the user pastes a GitHub issue URL containing loaner import results

---

## Workflow

### 1. Fetch the issue

Extract the issue number from the argument and fetch it:

```bash
gh issue view <number> --repo fleetyards/fleetyards --json number,title,body
```

Parse the issue body into two sections:
- **Missing Models** — the model itself was not found in the DB; loaners listed for reference
- **Missing Loaners** — the model exists but a loaner model could not be found

If the issue has neither section populated, tell the user everything looks clean.

### 2. Read the current loader

```
app/lib/rsi/loaner_loader.rb
```

Understand the existing:
- `models_mapping` — maps import model names (from RSI support page) to arrays of DB model names
- `model_mapping` — maps individual loaner model names to DB model names
- Local variables for model families (e.g., `x1_variants`, `zeus_variants`, `pulse_variants`)

### 3. Analyze missing models

For each entry in the "Missing Models" section (format: `**<name>** — Loaners: <loaners>`):

| Pattern | Cause | Fix |
|---------|-------|-----|
| Name differs from DB name (e.g., "Carrack / Carrack Expedition") | `models_mapping` needs an entry | Add `models_mapping` entry mapping to correct DB name(s) |
| Name matches existing mapping | Model doesn't exist in DB yet (not a loader issue) | Flag to user |
| Name is a variant group (e.g., "Fury Variants") | Group not mapped | Add `models_mapping` entry with all variant DB names |

### 4. Analyze missing loaners

For each entry in the "Missing Loaners" section (format: `**<loaner_name>** — For Model: <model> (<model_id>)`):

| Pattern | Cause | Fix |
|---------|-------|-----|
| Loaner name differs from DB name (e.g., "F7C Hornet" vs "F7C Hornet Mk I") | `model_mapping` needs an entry | Add `model_mapping` entry |
| Loaner name matches DB model | Something else is wrong | Investigate further |
| Loaner model doesn't exist in DB | Not a loader issue | Flag to user |

**To verify model names exist**, query the Fleetyards API:

```bash
curl -s "https://api.fleetyards.net/v1/models?q%5Bname_cont%5D=<search>" | python3 -c "import sys,json; [print(m['name']) for m in json.load(sys.stdin)]"
```

### 5. Categorize needed changes

Group changes into:

1. **New local variables** — when a new ship family needs a reusable array (e.g., `pulse_variants = ["Pulse", "Pulse LX"]`)
2. **Variable updates** — when existing variant arrays have outdated model names
3. **New `models_mapping` entries** — mapping RSI page model names to DB model name arrays (in `models_map` hash)
4. **New `model_mapping` entries** — mapping individual loaner names to DB model names (in `model_map` hash)
5. **No action needed** — model genuinely doesn't exist in DB yet

### 6. Present the plan

Show the user a summary of proposed changes organized by category. For example:

```
## Proposed changes to loaner_loader.rb

### New variables
- `pulse_variants = ["Pulse", "Pulse LX"]` — for Pulse family

### Variable updates
- `zeus_variants`: add "Zeus Mk II MR" variant

### New models_mapping entries
- "Pulse (+ LX)" => pulse_variants
- "Spirit A1" => ["A1 Spirit"]

### New model_mapping entries
- "F7C Hornet" => "F7C Hornet Mk I"
- "Hercules C2" => "C2 Hercules"

### Skipped (no action)
- "Some Ship" — model not in DB yet
```

Wait for user confirmation before applying changes.

### 7. Apply changes

Edit `app/lib/rsi/loaner_loader.rb`:

- Add new local variables near related existing ones in `models_mapping` method
- Add `models_map` entries near related existing entries (group by ship family)
- Add `model_map` entries in `model_mapping` method near related existing entries
- Keep consistent formatting with the rest of the file

### 8. Lint

```bash
bundle exec standardrb --fix app/lib/rsi/loaner_loader.rb
```

### 9. Close the issue

After changes are merged or committed, close the issue:

```bash
gh issue close <number> --comment "Resolved: added mappings for <summary of changes>"
```

---

## Reference: Import data flow

The loaner loader fetches the RSI support page HTML containing a table of ships and their loaners.

For each row:
- The model name (first column) is looked up via `models_mapping` which returns an array of DB model names
- Each loaner name (comma-separated in last column) is looked up via `model_mapping` which returns a single DB model name
- `Model.where(name: ...)` is queried for both

If the model is not found → goes into `missing_models`.
If a loaner model is not found → goes into `missing_loaners`.

## Reference: Common variant groups

These local variables in `models_mapping` represent multi-variant ship families:

- `x1_variants` — X1, X1 Velocity, X1 Force
- `zeus_variants` — Zeus Mk II MR, CL, ES
- `pulse_variants` — Pulse, Pulse LX
- `ironclad_variants` — Ironclad, Ironclad Assault
- `terrapin_variants` — Terrapin, Terrapin Medic

## Error Handling

- **Issue not found** — tell the user and stop
- **No missing models or loaners** — tell the user the import was clean
- **Model not in API** — flag it as "model doesn't exist yet, no loader fix possible"
- **Ambiguous model name** — ask the user which ship family it belongs to
