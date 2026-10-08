# Collapsible details/summary blocks in markdown

Working plan for #5491. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A `<details>`/`<summary>` section, written GitHub's way, renders as a collapsible section and can be inserted and edited in the markdown editor.

## What changed

### Phase 1 — Renderer
1. `readDetails` in `Markdown.ts` reads one section: the opening line, its summary, and its body (nesting counted, fenced code skipped). Exported so the editor tokenizer agrees with it.
2. `renderMarkdown` emits `<details><summary>…</summary>…</details>`. `markdownToPlainText` separates the summary from the body.

### Phase 2 — Editor
1. `@tiptap/extension-details` gives the node view, keyboard handling and `setDetails`/`unsetDetails`. Its `:::details` markdown is replaced with a tokenizer built on `readDetails` and a serialiser that writes GitHub's form.
2. `protectHtml` leaves the details lines as tags.
3. Toolbar button (toggle), translations in all 7 locales, styles shared by the editor and the page.

## Intent Verification

- [ ] Rendered section is closed by default, the summary is inline and the body is full markdown
- [ ] Editor round-trips `<details>` text unchanged after the first save
- [ ] Toolbar inserts and removes a section
- [ ] Nested sections round-trip and render
- [ ] Other `<…>` text is still literal

## Key files

| File | Role |
|------|------|
| `app/frontend/shared/utils/Markdown.ts` | Renderer and `readDetails` |
| `app/frontend/shared/components/base/FormMarkdownEditor/extensions.ts` | Editor nodes and `protectHtml` |
| `app/frontend/shared/components/base/FormMarkdownEditor/index.vue` | Toolbar |
| `app/frontend/shared/components/Markdown/content.scss` | Shared look |

## Not in scope (deferred)
- **Mail and push bodies** — Redcarpet's `filter_html` strips the tags, so the summary and body show as plain text. That is acceptable for a notification.

## Discovery Log

- **2026-10-08** `@tiptap/extension-details` 3.31.4 is MIT. Its markdown spec writes nested `:::details`/`:::detailsSummary` containers, so it has to be overridden.

## Progress
- [x] Phase 1
- [x] Phase 2
