---
name: resolve-paints-import
description: Resolves a Paints Import Results GitHub issue by analyzing missing models/errors and updating paints_importer.rb mappings
---

# Resolve Paints Import Skill

Processes a "Paints Import Results" GitHub issue created by the `Loaders::PaintsImportJob`. Analyzes missing models and errored paints, then updates `app/lib/paints_importer.rb` with the needed mappings.

## When to Use

- When the user references a "Paints Import Results" GitHub issue (e.g., "resolve paints import #3521")
- When the user pastes a GitHub issue URL containing paint import results

---

## Workflow

### 1. Fetch the issue

Extract the issue number from the argument and fetch it:

```bash
gh issue view <number> --repo fleetyards/fleetyards --json number,title,body
```

Parse the issue body into three sections:
- **New Paints** — successfully imported (informational, no action needed)
- **New Paints with Errors** — created but image download or other error occurred
- **Missing Models** — paint skipped because no matching Model was found

If the issue has no "Missing Models" or "New Paints with Errors" sections, tell the user everything looks clean.

### 2. Read the current importer

```
app/lib/paints_importer.rb
```

Understand the existing:
- `models_mapping` — maps import model names to arrays of DB model names
- `paint_mapping` — normalizes paint names (strips model prefixes, fixes typos)
- Variable definitions (aurora, hercules, mercury, mxc, mole, etc.)

### 3. Analyze missing models

For each entry in the "Missing Models" section, determine the category:

| Pattern | Cause | Fix |
|---------|-------|-----|
| Single name like "Hercules Fortuna" | `model_name` not in `models_map` | Add `models_map` entry |
| Array like `["Aurora CL", ...] ArcCorp` | Mapping found but DB model names are outdated | Update the variable definition |
| Doubled name like "MXC Foo MXC Foo" | No " - " separator in import data; `model_name == paint_name` | Add both `models_map` AND `paint_map` entries |
| `[TEMP` prefix | Garbage/test data | Skip, no action needed |
| Name matches existing mapping | Model doesn't exist in DB yet (not an importer issue) | Flag to user |

**To verify model names exist**, query the Fleetyards API:

```bash
curl -s "https://api.fleetyards.net/v1/models?q%5Bname_cont%5D=<search>" | python3 -c "import sys,json; [print(m['name']) for m in json.load(sys.stdin)]"
```

### 4. Categorize needed changes

Group changes into:

1. **New variable definitions** — when a new ship family needs a reusable array (e.g., `mxc = %w[MTC MDC]`)
2. **Variable updates** — when existing arrays have outdated model names (e.g., old Aurora names)
3. **New `models_map` entries** — simple model name to variable mapping
4. **New `paint_map` entries** — for unsplit names where paint_name contains the model prefix
5. **No action needed** — model genuinely doesn't exist in DB yet, or garbage data

### 5. Present the plan

Show the user a summary of proposed changes organized by category. For example:

```
## Proposed changes to paints_importer.rb

### New variables
- `mxc = %w[MTC MDC]` — for M*C vehicle family

### Variable updates
- `aurora`: update to Mk I names ["Aurora Mk I CL", ...]

### New models_map entries
- "Hercules" => hercules
- "Mercury" => mercury
- "MXC" => mxc

### New paint_map entries
- "MXC Citizens for Prosperity Liberation" => "Citizens for Prosperity Liberation"

### Skipped (no action)
- [TEMP MTC CFP — garbage data
- "Some Model Foo" — model not in DB yet
```

Wait for user confirmation before applying changes.

### 6. Apply changes

Edit `app/lib/paints_importer.rb`:

- Add new variables near related existing ones (alphabetical within the variable block)
- Add `models_map` entries near related existing entries (group by ship family)
- Add `paint_map` entries near related existing entries
- Keep consistent formatting with the rest of the file

### 7. Lint

```bash
bundle exec standardrb --fix app/lib/paints_importer.rb
```

### 8. Close the issue

After changes are merged or committed, close the issue:

```bash
gh issue close <number> --comment "Resolved: added mappings for <summary of changes>"
```

---

## Reference: Import data flow

The paint importer splits raw paint names on " - ":
- Left side = `model_name` (looked up in `models_mapping`)
- Right side = `paint_name` (looked up in `paint_mapping`)

If no " - " separator exists, both `model_name` and `paint_name` are the full string.

The `models_mapping` returns either:
- A mapped array of DB model names (if key exists in `models_map`)
- The raw name as-is (fallback)

Then `Model.where(name: model_names)` is queried. If empty, the paint goes into `model_not_found`.

## Reference: Common ship families

These are the variable names used for multi-variant ships. When adding new M*C vehicles or other family members, update the relevant variable:

- `aurora` — Aurora Mk I variants (CL, ES, LN, LX, MR)
- `aurora_mk2` — Aurora Mk II (single model)
- `hercules` — C2/M2/A2 Hercules
- `mercury` — Mercury, Mercury Star Runner
- `mxc` — MTC, MDC (and future M*C vehicles)
- `mole` — MOLE
- `freelancer` — Freelancer, DUR, MAX, MIS
- `connie` — Constellation variants
- `cutlass` — Cutlass Black, Blue, Red, Steel
- `hornet_mk1` / `hornet_mk2` — Hornet variant families
- `series_100` / `series_600` — Origin series
- `vanguard`, `gladius`, `avenger`, `sabre`, `spirit`, `fury`, `scorpius`, etc.

## Error Handling

- **Issue not found** — tell the user and stop
- **No missing models or errors** — tell the user the import was clean
- **Model not in API** — flag it as "model doesn't exist yet, no importer fix possible"
- **Ambiguous model name** — ask the user which ship family it belongs to
