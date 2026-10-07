# Discord /item command with autocomplete

Working plan for #5479. Decisions live in the issue body. Deleted before the PR merges.

## Goal

`/item <name>` in Discord answers with an embed for a component, equipment item, commodity or blueprint, and its `name` option suggests items as you type.

## What changed

### Phase 1 — Autocomplete plumbing
1. `InteractionsController` answers interaction type 4 (autocomplete) inline with a type 8 response, asking the invoked command's handler class for choices via `.autocomplete(option, value)`.
2. A handler without `.autocomplete`, an unknown command, or a raising handler answers with no choices.
3. Registry test: every option declaring `autocomplete: true` belongs to a handler that answers `.autocomplete`.

### Phase 2 — `/item`
1. `Catalogue::TokenResolver#search` takes `within:` to limit the catalogues searched.
2. `Discord::Commands::Item`: resolves the picked token (or the typed name) through `TokenResolver`, falling back to a short candidate list from `search`.
3. One embed per type with the stored facts the site's hover card shows, a price, and a link to the item page.
4. Strings in all seven `config/locales/*/discord.yml`.

## Intent Verification

- [ ] `/item` with a picked suggestion answers with that item's embed
- [ ] `/item` with a typed unique name resolves; an ambiguous one lists candidates; an unknown one says so
- [ ] An autocomplete request is answered with type 8 and at most 25 choices whose name and value fit 100 characters
- [ ] Every new string exists in all seven locales

## Key files

| File | Role |
|------|------|
| `app/controllers/discord/interactions_controller.rb` | Autocomplete answered inline |
| `lib/discord/commands/registry.rb` | `/item` definition |
| `lib/discord/commands/item.rb` | The command and its suggestions |
| `app/services/catalogue/token_resolver.rb` | Name resolution shared with markdown tokens |
| `config/locales/*/discord.yml` | Strings |

## Not in scope (deferred)
- **`/where <item>`**: shops and prices for an item. Its own issue.
- **`/location <name>`**: a place card. Its own issue.

## Discovery Log

- **2026-10-08** Initial research and plan creation. Discord has no deferred response for autocomplete, so it is the only interaction answered inline.
- **2026-10-08** A component's hover-card key figure is computed in the frontend per category; the embed keeps to stored facts (decision in the issue). Game icons are mostly SVG with no raster variant, so they get no thumbnail.

## Progress
- [x] Phase 1
- [x] Phase 2
