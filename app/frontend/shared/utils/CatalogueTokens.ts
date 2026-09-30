// `[*Name*]` or `[*type:Name*]`: a catalogue item named inline in markdown.
// The name cannot hold `*`, `]` or a line break, which is what keeps a token
// from swallowing the text around it.
export const CATALOGUE_TOKEN_TYPES = [
  "component",
  "equipment",
  "commodity",
] as const;

export type CatalogueTokenType = (typeof CATALOGUE_TOKEN_TYPES)[number];

export const CATALOGUE_TOKEN_PATTERN = /\[\*([^*\]\n]+?)\*\]/g;

// The name a token shows: the text after a known prefix, or all of it.
export const catalogueTokenName = (token: string) => {
  const [prefix, ...rest] = token.split(":");

  return rest.length &&
    CATALOGUE_TOKEN_TYPES.includes(
      prefix.trim().toLowerCase() as CatalogueTokenType,
    )
    ? rest.join(":").trim()
    : token.trim();
};

export const catalogueTokenText = (token: string) => `[*${token}*]`;
