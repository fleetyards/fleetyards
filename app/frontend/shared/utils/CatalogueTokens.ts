// `[*Name*]` or `[*type:Name*]`: a catalogue item named inline in markdown.
// The name cannot hold `*`, `]` or a line break, which is what keeps a token
// from swallowing the text around it.
export const CATALOGUE_TOKEN_TYPES = [
  "component",
  "equipment",
  "commodity",
  "ship",
  "blueprint",
  "mission",
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

// The icon a linked token shows in front of its name, by the prefix a token
// is written with or the type the lookup answers -- the catalogue's own icons.
// A token written without a prefix is one of the first three, which only the
// lookup can tell apart.
const ICONS: Record<string, string> = {
  component: "fa-duotone fa-microchip",
  equipment: "fa-duotone fa-shirt",
  commodity: "fa-duotone fa-boxes-stacked",
  ship: "fa-duotone fa-starship",
  blueprint: "fa-duotone fa-notes",
  mission: "fa-duotone fa-scroll",
  Component: "fa-duotone fa-microchip",
  Equipment: "fa-duotone fa-shirt",
  Commodity: "fa-duotone fa-boxes-stacked",
  Model: "fa-duotone fa-starship",
  Blueprint: "fa-duotone fa-notes",
  GameMission: "fa-duotone fa-scroll",
};

export const catalogueTokenIcon = (typeOrPrefix?: string | null) =>
  (typeOrPrefix && ICONS[typeOrPrefix]) || "fa-duotone fa-cube";

export const catalogueTokenPrefix = (token: string) => {
  const [prefix, ...rest] = token.split(":");
  const lowered = prefix.trim().toLowerCase();

  return rest.length &&
    CATALOGUE_TOKEN_TYPES.includes(lowered as CatalogueTokenType)
    ? lowered
    : undefined;
};
