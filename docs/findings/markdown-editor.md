# Markdown Editor: What Tiptap Writes and What the Renderer Must Read

**Date:** 2026-09-30 (Tiptap 3.31.3, `@tiptap/markdown`; tracked in #5331)

User-written descriptions are stored as Markdown, edited through `FormMarkdownEditor` (Tiptap) and shown through `shared/utils/Markdown.ts`. The two are separate parsers, and a mismatch between them does not look like an error: it is a description that looks right in the editor and wrong on the page, or one that silently changes when someone opens and saves it. Read this before adding a node to the editor or a rule to the renderer.

## The contract

- **Every block the renderer shows must exist as a node in the editor**, whether or not the toolbar offers it. Tiptap flattens a block it has no node for when the Markdown is loaded (`1. a\n2. b` became `1. a 2. b` with ordered lists switched off; a quote lost its `>`), and the next save writes the flattened text back. Underline is the only StarterKit mark left out, because Markdown cannot write it.
- **Everything the editor can write must render the way the editor shows it.** Round-trip tests in `FormMarkdownEditor/extensions.spec.ts` render the editor's output with the real renderer for this reason.
- **The URL rule is shared** (`shared/utils/MarkdownUrls.ts`): the renderer uses it to decide what becomes a link or an image, and the editor uses it to refuse what the page would not show.

## What Tiptap's serializer writes

| Input | Written as | Why the renderer cares |
| --- | --- | --- |
| `[`, `]`, `*`, `_`, `` ` `` typed as text | `\[`, `\]`, `\*`, `\_`, `` \` `` | Backslash escapes must be read as the character, before code spans are split (an escaped backtick opens nothing) and before links are matched |
| `&`, `<`, `>` typed as text | `&amp;`, `&lt;`, `&gt;` | Entities must be decoded, or the page shows `&amp;` |
| A centred block | `:::center\n\n…\n\n:::` | `createBlockMarkdownSpec` only matches `:::name` **without** a space after the colons; `::: center` opens as plain text |
| A hard break | two trailing spaces | The renderer trims lines and joins a paragraph with `<br>`, so it shows |
| A nested list | indented by two spaces | The renderer nests lists by indentation |
| An underlined (setext) heading | `## Heading` | Stored fleet descriptions use `----` underlines, so the renderer reads both forms |

## Traps

- **URLs have to be checked after escapes are resolved.** The renderer replaces escapes and entities with placeholders before formatting. If a URL is checked while the placeholders are still in it, `[x](/\/host)` or `[x](/&#47;host)` passes as a same-origin path and reaches the browser as `//host`. `formatText` resolves the URL before calling the shared rule. The rule also refuses whitespace and control characters, which browsers strip while parsing a URL.
- **Markdown reads `<word>` as an HTML tag, and the editor drops a tag it has no node for.** `protectHtml` passes `<` outside code as `&lt;` when content is loaded, so typed text like `<RSI handle>` survives a save.
- **The trailing node.** StarterKit keeps an empty paragraph after a closing image or block so there is somewhere to type. It would serialize as trailing blank lines; `toMarkdown` trims it.
- **Reactivity lags by two frames.** `@tiptap/vue-3` publishes editor state to templates through a ref that triggers two `requestAnimationFrame`s after a change, so a toolbar's pressed state lags a command. Tests wait two frames.
- **Loading is not a change.** Tiptap does not emit an update when content is set at creation, so opening a description does not dirty the form, even though its serialized form may differ (escapes, entities) from what is stored.

## Where it is used

The fleet description (settings and admin), events (description, briefing, occurrence overrides, ships, teams), missions (description, ships, teams), contracts and squadrons. Full text renders through `Markdown`; table rows and panel ledes use `markdownToPlainText`; the calendar export uses `MarkdownPlainText` (Ruby, Redcarpet `StripDown`).
