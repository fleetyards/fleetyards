# Markdown Editor: What Tiptap Writes and What the Renderer Must Read

**Date:** 2026-09-30 (Tiptap 3.31.3, `@tiptap/markdown`; tracked in #5331)

User-written descriptions are stored as Markdown, edited through `FormMarkdownEditor` (Tiptap) and shown through `shared/utils/Markdown.ts`. The two are separate parsers, and a mismatch between them does not look like an error: it is a description that looks right in the editor and wrong on the page, or one that silently changes when someone opens and saves it. Read this before adding a node to the editor or a rule to the renderer.

## The contract

- **Every block the renderer shows must exist as a node in the editor**, whether or not the toolbar offers it. Tiptap flattens a block it has no node for when the Markdown is loaded (`1. a\n2. b` became `1. a 2. b` with ordered lists switched off; a quote lost its `>`), and the next save writes the flattened text back. Underline is the only StarterKit mark left out, because Markdown cannot write it.
- **Everything the editor can write must render the way the editor shows it.** Round-trip tests in `FormMarkdownEditor/extensions.spec.ts` render the editor's output with the real renderer for this reason.
- **The URL rule is shared** (`shared/utils/MarkdownUrls.ts`): the renderer uses it to decide what becomes a link or an image, and the editor uses it to refuse what the page would not show.
- **Images come only from Fleetyards and RSI.** The page's content security policy (`img-src`) loads nothing else, and a third-party host would receive every reader's address. `isSafeMarkdownSrc` builds its allowlist from `window.FRONTEND_ENDPOINT`, `API_ENDPOINT` and `RSI_ENDPOINT`. An image from anywhere else renders as a link named by its description. A new picture gets in by upload: `POST /v1/markdown-images` takes a direct-upload blob and returns `…/v1/markdown-images/<id>`, which redirects to a re-encoded WebP rendition (never the original file). Text names an image by id, so the rendition can change without rewriting descriptions.
- **Images are deleted once no text names them.** `Cleanup::MarkdownImagesJob` (daily) deletes images older than a week that none of `MarkdownImage::REFERENCING_COLUMNS` mentions. It also scans the version history of the types an admin can revert a field on, so a revert never brings back a dead image. A new Markdown column must be registered there; a model test fails for any fleet or mission `description`/`briefing` column that is neither registered nor marked as plain text.

## What Tiptap's serializer writes

| Input                                     | Written as                       | Why the renderer cares                                                                                                                        |
| ----------------------------------------- | -------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `[`, `]`, `*`, `_`, `` ` `` typed as text | `\[`, `\]`, `\*`, `\_`, `` \` `` | Backslash escapes must be read as the character, before code spans are split (an escaped backtick opens nothing) and before links are matched |
| `&`, `<`, `>` typed as text               | `&amp;`, `&lt;`, `&gt;`          | Entities must be decoded, or the page shows `&amp;`                                                                                           |
| A centred block                           | `:::center\n\n…\n\n:::`          | `createBlockMarkdownSpec` only matches `:::name` **without** a space after the colons; `::: center` opens as plain text                       |
| A hard break                              | two trailing spaces              | The renderer trims lines and joins a paragraph with `<br>`, so it shows                                                                       |
| A nested list                             | indented by two spaces           | The renderer nests lists by indentation                                                                                                       |
| An underlined (setext) heading            | `## Heading`                     | Stored fleet descriptions use `----` underlines, so the renderer reads both forms                                                             |

## Catalogue tokens

`[*Name*]` and `[*type:Name*]` name a catalogue item inline. The grammar lives in `shared/utils/CatalogueTokens.ts` (and once more in Ruby, in `MarkdownPlainText`). The name can't hold `*`, `]` or a line break.

- **Renderer:** a token outside code becomes an inert `span[data-catalogue-token]` showing the name. It's marked on the escaped text and before the formatting rules, which would otherwise read its asterisks as emphasis.
- **`Markdown` component:** resolves every mark of a text through `GET /v1/catalogue/lookup` in one request, then teleports the injected `MARKDOWN_CATALOGUE_TOKEN` component (the frontend provides `CatalogueItemPopover`) into each resolved mark. Admin provides nothing, so tokens stay names there.
- **Editor:** `catalogueToken` is an inline atom node. Without it, the serializer escapes the brackets and parses the name as italic, and the first save rewrites the token.
- **Resolution** (`Catalogue::TokenResolver`): a name resolves only when exactly one listed item carries it. Components repeat many generic names ("Internal Tank" ×313), so the search offers only names that resolve (chosen in SQL with `HAVING count(*) = 1`, or a repeated name crowds out the rest), prefixed when another catalogue carries the name too.
- **Prefix-only types:** `ship:`, `blueprint:` and `mission:` resolve only with their prefix. A blueprint has the name of the item it crafts, and ships and missions can share item names, so letting them answer a bare name would turn tokens already written ambiguous. `BARE` in the resolver lists what a bare name can mean.
- **Reader-dependent types** (`Catalogue::RestrictedTokenResolver`): `[*contract:FID/Title*]`, `[*event:FID/Title*]` and `[*user:handle*]` resolve only for a reader the target's page lets in. For a contract or an event that's the whole gate the controller applies, not only the policy: an accepted membership in a kept fleet, the feature flag, the fleet subscription where it's enforced, then `show?`. An OAuth token without `fleet`/`fleet:read` resolves none. A user resolves through `User.with_hangar_readable_by`. A title is ambiguous if two of the fleet's records carry it, counting the ones the reader can't see, so a hidden duplicate can't redirect a token. Events break the tie on `FleetEvent.still_running`: a split series copies its title to the successor, and once the original's last occurrence has passed the successor is the only one running, so the token follows it. Until then both run and the title stays plain text. The lookup's cache is reset on login and logout, since its answer belongs to the reader.
- **Marking:** a linked token shows its type's icon, then `[Name]` (`CatalogueTokenLink`), and the editor chip looks the same. An unresolved token is its plain name without brackets, and CSS hides that name only once a link element sits beside it (`:has`), so a slow or failed chunk never leaves a blank.
- **Duotone icons in the editor:** ProseMirror sets `font-feature-settings: "liga" 0`, and a Font Awesome duotone icon draws its second layer through a ligature, so the glyph shows twice. The chip turns ligatures back on for its icon.

## Traps

- **URLs have to be checked after escapes are resolved.** The renderer replaces escapes and entities with placeholders before formatting. If a URL is checked while the placeholders are still in it, `[x](/\/host)` or `[x](/&#47;host)` passes as a same-origin path and reaches the browser as `//host`. `formatText` resolves the URL before calling the shared rule. The rule also refuses whitespace and control characters, which browsers strip while parsing a URL.
- **Markdown reads `<word>` as an HTML tag, and the editor drops a tag it has no node for.** `protectHtml` passes `<` outside code as `&lt;` when content is loaded, so typed text like `<RSI handle>` survives a save.
- **The trailing node.** StarterKit keeps an empty paragraph after a closing image or block so there is somewhere to type. It would serialize as trailing blank lines; `toMarkdown` trims it.
- **One app modal at a time.** `AppModal` holds a single component and replaces it on the next `open-modal`. The editor often sits inside one (event and mission ship and team modals), so its image upload is a native `<dialog>` in the top layer, reusing `AppModalInner` with `onClose`.
- **Reactivity lags by two frames.** `@tiptap/vue-3` publishes editor state to templates through a ref that triggers two `requestAnimationFrame`s after a change, so a toolbar's pressed state lags a command. Tests wait two frames.
- **Loading is not a change, and neither is focusing.** Tiptap does not emit on the content it is created with, but the first transaction (focusing the text is enough) lets StarterKit's trailing node append a paragraph, and the document then re-serializes with escapes and entities the stored text lacks. The editor records what the loaded document serializes to and, when an update produces exactly that, hands back the original text, so the form isn't dirtied and the stored text isn't rewritten.

## Where it is used

The fleet description (settings and admin), events (description, briefing, occurrence overrides, ships, teams), missions (description, ships, teams), contracts and squadrons. Full text renders through `Markdown`; table rows and panel ledes use `markdownToPlainText`; the calendar export uses `MarkdownPlainText` (Ruby, Redcarpet `StripDown`).
