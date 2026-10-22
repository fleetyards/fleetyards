# Dedication plaque generator as a tool for every ship

Working plan for #5900. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A public `/tools/plaque/` page that draws a plaque for any catalogue ship, shares or downloads it as a PNG, and lets a signed-in user attach it to one of their ships of that model.

## What changed

### Phase 1 — API
1. `Manufacturer` payload: `shortName`, `shipyard` (jbuilder + `V1::Schemas::Manufacturer`, cache key bump)
2. `HangarQuery`: `modelSlugIn`
3. Integration tests for both; regenerate the schema

### Phase 2 — Share the editor's pieces
1. Extract the style picker out of `PlaqueEditModal` into `Vehicles/PlaqueStylePicker`
2. Extract the lines into `Vehicles/PlaqueFields`
3. Extract the link-preview capture and upload into `usePlaqueImageUpload`
4. `PlaqueEditModal` spec stays green unchanged

### Phase 3 — Share sheet
1. `PlaqueDownloadBtn` gains a `share` mode that always goes through `navigator.share({ files })`, shown only where `canShare` accepts a PNG

### Phase 4 — The tool
1. Route `plaque-tool` at `tools/plaque/`, ToolsNav entry
2. Page: model picker, name and registry, `PlaqueFields`, style picker, preview, Share / Download
3. `PlaqueAttachModal`: user's purchased ships of the model, overwrite confirmation, save + picture upload
4. Translations in all 7 locales

## Intent Verification

- [ ] **Public tool** — `/tools/plaque/` renders signed out, Tools nav links to it
- [ ] **Any ship** — picking a model redraws the plaque with its maker's emblem, short name and shipyard
- [ ] **Share/Download** — Share only where the browser can share files; Download always
- [ ] **Attach** — signed-in, lists only purchased ships of the model; overwrite asks first; saves lines + style + picture
- [ ] **Editor unchanged** — `PlaqueEditModal` spec passes untouched

## Key files

| File | Role |
|------|------|
| `app/frontend/frontend/components/Vehicles/PlaqueEditModal/index.vue` | Hangar editor, source of the extracted pieces |
| `app/frontend/frontend/components/Vehicles/Plaque/index.vue` | The plaque itself |
| `app/frontend/frontend/components/Vehicles/Plaque/download.ts` | Rendering, download, share |
| `app/frontend/frontend/pages/tools/routes.ts` | Tools routes |
| `app/views/api/v1/manufacturers/_manufacturer.jbuilder` | Manufacturer payload |
| `app/api_components/v1/schemas/queries/hangar_query.rb` | Hangar filters |

## Not in scope (deferred)

## Discovery Log

- **2026-10-22** Only the manufacturer and model fragments got a cache version bump; the 15 other fragments embedding the manufacturer partial pick the new fields up within the store's 1-day expiry, and both fields are optional in the schema.
- **2026-10-22** The catalogue's manufacturer payload carries neither short name nor shipyard; the plaque took both from the vehicle payload. The hangar query had no model filter; its permit list is derived from the schema, so declaring the property is enough.

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [x] Phase 4
