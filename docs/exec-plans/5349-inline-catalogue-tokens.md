# Inline catalogue tokens ([*Item Name*]) in Markdown descriptions

Working plan for #5349. Decisions live in the issue body. Deleted before the PR merges.

Stacked on #5338 (`feat/5331-markdown-editor-tiptap`): the Markdown editor, renderer and plain-text readings this builds on.

## Goal

`[*Name*]` / `[*type:Name*]` in any Markdown text renders as a link to the item with its stats card, is edited as an inline chip, and is inserted from an autocomplete on `[*`.

## Open questions

- None blocking. The rendering approach and autocomplete scope are decided in the issue.

## What changed

### Phase 1 — Lookup API
1. `GET /v1/catalogue/lookup?names[]=` — resolves up to 100 names (`Name` or `type:Name`) against the public catalogues (`Component.with_facts(true).catalogued`, `Equipment.visible(true)`, `Commodity.with_facts(true)`), case-insensitively. Answers `{name, type, slug}` for each name that resolves to exactly one item; everything else is left out.
2. `GET /v1/catalogue/search?q=` — name search across the three for the autocomplete, limited, returning only names that resolve to one item within their catalogue, flagged when the name exists in another catalogue too (so the token gets its prefix).
3. Service object holding the resolution rules; schema components; openapi integration tests; regenerate schema and client.

### Phase 2 — Parsing and rendering
1. `shared/utils/CatalogueTokens.ts`: the token grammar (one place, used by renderer, editor and plain text).
2. `renderMarkdown` turns a token into `<span class="catalogue-token" data-catalogue-token="…">Name</span>` (escaped) — not inside code spans or fences.
3. `Markdown` component: collects the placeholders after render, looks them up in one request (vue-query, keyed by the sorted names), and teleports a `CatalogueItemPopover` into each resolved one.
4. `markdownToPlainText` reads a token as its name (falls out of the placeholder's text); Ruby `MarkdownPlainText` strips `[*type:Name*]` to `Name`.

### Phase 3 — Editor
1. Inline atom node `catalogueToken {type, name}` with a markdown tokenizer and serializer that round-trip `[*type:Name*]`, rendered as a chip.
2. Autocomplete on `[*` (Tiptap suggestion) listing search results in a floating list; Enter / click inserts the node; keyboard navigable.
3. `protectHtml`/escaping unaffected (tokens contain no `<`).

### Phase 4 — Tests and checks
1. Ruby: lookup/search resolution (unique, ambiguous, unknown, prefixed, cross-catalogue, hidden/retired), integration tests.
2. Vitest: grammar, renderer placeholders (incl. code spans), Markdown component (one request, resolved → popover, unresolved → text), editor node round trip, autocomplete insertion.
3. Playwright: token typed via autocomplete on the visual-tests page renders a link with its card.

## Intent Verification

- [ ] **Resolved token** — renders as a link with the stats card on hover / tap
- [ ] **Unknown / ambiguous** — renders as plain text, no error
- [ ] **One request per block** — however many tokens
- [ ] **Editor chip** — round-trips unchanged through save and reload
- [ ] **Autocomplete** — `[*` opens it; inserts the token, prefixed when needed
- [ ] **Plain text** — previews and calendar show the item's name

## Key files

| File | Role |
|------|------|
| `app/controllers/api/v1/catalogue_controller.rb` | lookup + search (new) |
| `app/services/catalogue/token_resolver.rb` | resolution rules (new) |
| `app/frontend/shared/utils/CatalogueTokens.ts` | token grammar (new) |
| `app/frontend/shared/utils/Markdown.ts` | placeholder rendering |
| `app/frontend/shared/components/Markdown/index.vue` | lookup + teleported popovers |
| `app/frontend/frontend/components/CatalogueItemPopover/` | the card (from #5329) |
| `app/frontend/shared/components/base/FormMarkdownEditor/` | token node + autocomplete |
| `app/lib/markdown_plain_text.rb` | calendar text |

## Not in scope (deferred)

- **Tokens in game-file text** — game descriptions carry no such markup.

## Discovery Log

- **2026-10-01** Public-catalogue name collisions measured on the production dump: components 153 repeated names / 3,190 items (generic per-ship parts), equipment 20 / 4,565, commodities 0 / 232, cross-catalogue 2 (mercury, slam).
- **2026-10-01** `CatalogueItemPopover` lives under `frontend/components`, but `Markdown` is in `shared/` (also used by admin). The popover must be injected into `Markdown` from the frontend app rather than imported by the shared component — to be settled in Phase 2.

## Progress
- [ ] Phase 1
- [ ] Phase 2
- [ ] Phase 3
- [ ] Phase 4
