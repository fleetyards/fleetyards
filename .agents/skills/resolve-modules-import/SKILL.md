---
name: resolve-modules-import
description: Resolves a Modules Import Results GitHub issue by analyzing missing models and updating modules_importer.rb mappings
---

# Resolve Modules Import Skill

Processes a "Modules Import Results" GitHub issue created by `Loaders::ModulesImportJob`. Analyzes missing models and errored modules, then updates `app/lib/modules_importer.rb` with the needed mappings.

## When to Use

- When the user references a "Modules Import Results" GitHub issue (e.g., "resolve modules import #3560")
- When the user pastes a GitHub issue URL containing module import results

---

## Workflow

### 1. Fetch the issue

Extract the issue number from the argument and fetch it:

```bash
gh issue view <number> --repo fleetyards/fleetyards --json number,title,body
```

Parse the issue body into three sections:
- **New Modules** — successfully imported (informational, no action needed)
- **New Modules with Errors** — created but an error occurred
- **Missing Models** — module skipped because no matching Model was found

If the issue has no "Missing Models" or "New Modules with Errors" sections, tell the user everything looks clean.

### 2. Read the current importer

```
app/lib/modules_importer.rb
```

Understand the existing:
- `model_mapping` — maps import model names (first word of component name) to DB model names
- `module_mapping` — normalizes module names (various casing/naming conventions to canonical names)
- `sc_key_mapping` — maps module names to Star Citizen data keys for enrichment

### 3. Analyze missing models

For each entry in the "Missing Models" section (format: `**<model_name> <module_name>**`):

| Pattern | Cause | Fix |
|---------|-------|-----|
| `model_name` not in `model_mapping` and doesn't match DB | Needs a `model_mapping` entry | Add `model_mapping` entry |
| `model_name` matches DB model (case-insensitive/slug) | Something else is wrong | Investigate further |
| Model doesn't exist in DB at all | Not an importer issue | Flag to user |

The importer splits the component name: first word = `model_name`, remainder = `module_name`.

**To verify model names exist**, query the Fleetyards API:

```bash
curl -s "https://api.fleetyards.net/v1/models?q%5Bname_cont%5D=<search>" | python3 -c "import sys,json; [print(m['name']) for m in json.load(sys.stdin)]"
```

### 4. Analyze errored modules

For entries in "New Modules with Errors", investigate what went wrong:
- Check if the module name needs normalization via `module_mapping`
- Check if there's a matching `sc_key_mapping` that could be added for enrichment

### 5. Categorize needed changes

Group changes into:

1. **New `model_mapping` entries** — mapping import model names to DB model names
2. **New `module_mapping` entries** — normalizing module name variants to canonical names
3. **New `sc_key_mapping` entries** — mapping module names to Star Citizen data keys
4. **No action needed** — model genuinely doesn't exist in DB yet

### 6. Present the plan

Show the user a summary of proposed changes organized by category. For example:

```
## Proposed changes to modules_importer.rb

### New model_mapping entries
- "Retaliator" => "Retaliator"

### New module_mapping entries
- "RETALIATOR FRONT LIVING MODULE" => "Front Living Module"
- "Personnel Module - Bow" => "Front Living Module"

### New sc_key_mapping entries
- "front torpedo bay" => "AEGS_Retaliator_Module_Front_Bomber"

### Skipped (no action)
- "SomeShip SomeModule" — model not in DB yet
```

Wait for user confirmation before applying changes.

### 7. Apply changes

Edit `app/lib/modules_importer.rb`:

- Add `model_mapping` entries in the `mapping` hash inside `model_mapping` method
- Add `module_mapping` entries in the `mapping` hash inside `module_mapping` method
- Add `sc_key_mapping` entries in the hash inside `sc_key_mapping` method
- Keep consistent formatting with the rest of the file

### 8. Lint

```bash
bundle exec standardrb --fix app/lib/modules_importer.rb
```

### 9. Close the issue

After changes are merged or committed, close the issue:

```bash
gh issue close <number> --comment "Resolved: added mappings for <summary of changes>"
```

---

## Reference: Import data flow

The modules importer reads `Imports::HangarSync` records containing JSON arrays of hangar items.

For items with `type: "component"`:
1. The full name is cleaned (en-dash → hyphen, non-breaking space → space)
2. First word = `model_name` (looked up via `model_mapping`)
3. Remainder after removing model_name = `module_name` (looked up via `module_mapping`)
4. `Model.find_by(name/slug)` is queried with the mapped model_name

If the model is not found → goes into `model_not_found`.
If creation fails → goes into `new_with_error`.

After successful creation, `enrich_from_sc_data` checks `sc_key_mapping` for a matching Star Citizen data key and runs the ScData loader if found.

## Reference: Current module families

The importer currently handles modules primarily for the Retaliator:
- Front/Rear Living Module
- Front/Rear Torpedo Bay
- Front/Rear Cargo Module
- Front/Rear Dropship Module

Module names come in many variants (uppercase, mixed case, with/without ship prefix, different naming conventions like "Personnel Module" vs "Living Module", "Drop Ship Module" vs "Dropship Module").

## Error Handling

- **Issue not found** — tell the user and stop
- **No missing models or errors** — tell the user the import was clean
- **Model not in API** — flag it as "model doesn't exist yet, no importer fix possible"
- **Ambiguous model name** — ask the user which model it belongs to
