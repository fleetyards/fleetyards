import type { Component, InjectionKey } from "vue";

// What a resolved catalogue token becomes: the app that has item pages
// provides its link-with-stats-card, which takes `{ type, slug, name }` as
// `item`. Without one -- the admin app -- a token stays the item's name.
export const MARKDOWN_CATALOGUE_TOKEN: InjectionKey<Component> = Symbol(
  "markdownCatalogueToken",
);
