# Minimal Markdown editor (Tiptap) for fleet descriptions and the captain's log

Working plan for #5331. Decisions live in the issue body. Deleted before the PR merges.

Stacked on #5330 (`fix/fleet-description-xss`), which introduces the Markdown description and the `:::center` block.

## Goal

A shared `FormMarkdownEditor` that edits a Markdown string through Tiptap, used by every fleet-written description (fleet, events, missions, contracts, squadrons), whose output the `Markdown` renderer displays the way the editor showed it.

## Open questions

- **Image insertion.** The editor keeps existing `![](…)` images (fleets already have them). Whether the toolbar should *offer* inserting one by URL is still open in the issue — until it is decided, no image button.

## What changed

### Phase 1 — Renderer parity with Tiptap's serializer
Probed with the real extension (jsdom): Tiptap writes CommonMark escapes and entities that the renderer shows literally.
1. Backslash escapes (`\[`, `\*`, `\_`, …) render as the character and take no part in formatting.
2. Entity references (`&amp;`, `&lt;`, `&gt;`, `&quot;`, `&#39;`, numeric) decode before escaping.
3. Tests for both, plus the exact strings Tiptap produced for the migrated descriptions.

### Phase 2 — Editor
1. `extensions.ts`: StarterKit limited to what the renderer displays (paragraph, heading 1–3, bullet list, bold, italic, inline code, link, hard break); ordered list, blockquote, strike, underline, code block, horizontal rule off. Image (inline: false). `Center` node through `createBlockMarkdownSpec`. Link validated with the renderer's policy (http(s) or a same-origin path).
2. `FormMarkdownEditor` mirroring `FormTextarea`: vee-validate `useField`, label, error, code-point counter against `maxlength`, `v-model` string.
3. Toolbar: bold, italic, heading, bullet list, link, centre. Buttons with `aria-pressed` and labels; the link button opens an inline URL field (no `window.prompt`).
4. Editor content styled with the renderer's rules so what is edited looks like what is shown.

### Phase 3 — Wiring
1. Fleet settings description (`pages/fleets/[slug]/settings/fleet.vue`).
2. Admin fleet edit (`admin/pages/fleets/[id]/edit.vue`).
3. Event (description, briefing, occurrence override, ship, team), mission (description, ship, team), contract and squadron description inputs.
4. Their displays: full text through `Markdown`, table rows and panel ledes through `markdownToPlainText`, the ICS export through `MarkdownPlainText`.

### Phase 4 — Tests
1. Round-trip every supported node through the editor unchanged.
2. Serialized output rendered by `Markdown` gives the expected structure (parity).
3. Component: v-model in and out, counter, toolbar toggles, link validation.

## Intent Verification

- [ ] **v-model Markdown** — the component takes and emits a Markdown string
- [ ] **Round-trip** — bold, italic, headings, bullet lists, links, images and `:::center` survive load and save unchanged
- [ ] **Parity** — `Markdown` renders the editor's output as the editor showed it (no stray `\`, `&amp;`)
- [ ] **Fleet settings** — the description uses the editor; character count kept
- [ ] **Accessible toolbar** — keyboard reachable, labelled, pressed state; usable on touch
- [ ] **Vitest** — round-trips for every supported node

## Key files

| File | Role |
|------|------|
| `app/frontend/shared/components/Markdown/index.vue` | Renderer; gains escapes and entities |
| `app/frontend/shared/components/base/FormMarkdownEditor/` | New editor component, extensions, toolbar |
| `app/frontend/shared/components/base/FormTextarea/index.vue` | Field behaviour to mirror (vee-validate, counter) |
| `app/frontend/frontend/pages/fleets/[slug]/settings/fleet.vue` | First consumer |
| `app/frontend/admin/pages/fleets/[id]/edit.vue` | Admin consumer |
| `app/frontend/translations/*/labels.json` | Toolbar labels, all 7 locales |

## Not in scope (deferred)

- **Inline `[*…*]` tokens** — the serializer escapes the brackets and parses the inside as italic (`\[*Attrition-3*\]`), so tokens need their own inline node before they ship. Belongs to the inline-token phase of the stats popover work, which already exists as an issue.
- **Captain's log** — reuses the component once the log exists.

## Discovery Log

- **2026-09-30** Tiptap 3.31.3 (`@tiptap/markdown`): soft line breaks, headings, lists, links, images round-trip unchanged. `:::center` round-trips with blank lines added inside (`:::center\n\n…\n\n:::`), which the renderer already reads. `createBlockMarkdownSpec` only matches `:::name` without a space, which is why #5330 writes `:::center`.
- **2026-09-30** The serializer escapes `[`, `]`, `*`, `_` with backslashes and writes `&`, `<`, `>` as entities. Typed HTML in the source is parsed on load (inert DOMParser) and saved back as Markdown or dropped.
- **2026-09-30** Hard breaks serialize as two trailing spaces; the renderer trims lines and joins a paragraph with `<br>`, so they display.
- **2026-09-30** A block StarterKit has switched off is flattened on load (`1. a\n2. b` → `1. a 2. b`). Stored descriptions use numbered lists (1) and `----` underlined headings (2), so ordered lists and rules stay on and the renderer learned them; quote, strike and code block stay off (none stored).
- **2026-09-30** StarterKit's trailing node leaves an empty paragraph after a closing image or block; `toMarkdown` trims it.
- **2026-09-30** `@tiptap/vue-3` publishes editor state to templates two animation frames after a change, so toolbar pressed state lags a command by two frames (tests wait for it).

## Progress
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [x] Phase 4
- [ ] Browser check of the editor in the fleet settings and an event modal
