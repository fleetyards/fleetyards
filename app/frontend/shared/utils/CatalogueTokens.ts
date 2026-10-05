import type { Icon } from "@/shared/components/DuotoneGlyph/glyph";
import { SHIP_GLYPH } from "@/shared/glyphs/ships";
// `[*Name*]` or `[*type:Name*]`: a catalogue item named inline in markdown,
// or a fleet's contract or event, `[*contract:FID/Title*]`, or a user,
// `[*user:handle*]`. The name cannot hold `*`, `]` or a line break, which is
// what keeps a token from swallowing the text around it.
export const CATALOGUE_TOKEN_TYPES = [
  "component",
  "equipment",
  "commodity",
  "ship",
  "blueprint",
  "mission",
  "location",
  "contract",
  "event",
  "user",
] as const;

// The prefixes whose name starts with the FID of the fleet it belongs to.
const FLEET_PREFIXES: string[] = ["contract", "event"];

export type CatalogueTokenType = (typeof CATALOGUE_TOKEN_TYPES)[number];

export const CATALOGUE_TOKEN_PATTERN = /\[\*([^*\]\n]+?)\*\]/g;

// The name a token shows: the text after a known prefix, or all of it. A
// contract or an event shows its title without the fleet's FID.
export const catalogueTokenName = (token: string) => {
  const prefix = catalogueTokenPrefix(token);
  if (!prefix) return token.trim();

  const name = token.slice(token.indexOf(":") + 1).trim();
  const slash = name.indexOf("/");

  return FLEET_PREFIXES.includes(prefix) && slash >= 0
    ? name.slice(slash + 1).trim()
    : name;
};

export const catalogueTokenText = (token: string) => `[*${token}*]`;

// The icon a linked token shows in front of its name, by the prefix a token
// is written with or the type the lookup answers -- the catalogue's own icons.
// A token written without a prefix is one of the first three, which only the
// lookup can tell apart.
const ICONS: Record<string, Icon> = {
  component: "fa-duotone fa-microchip",
  equipment: "fa-duotone fa-shirt",
  commodity: "fa-duotone fa-boxes-stacked",
  ship: SHIP_GLYPH,
  blueprint: "fa-duotone fa-notes",
  mission: "fa-duotone fa-scroll",
  location: "fa-duotone fa-planet-ringed",
  contract: "fa-duotone fa-clipboard-list",
  event: "fa-duotone fa-calendar-day",
  user: "fa-duotone fa-user",
  Component: "fa-duotone fa-microchip",
  Equipment: "fa-duotone fa-shirt",
  Commodity: "fa-duotone fa-boxes-stacked",
  Model: SHIP_GLYPH,
  Blueprint: "fa-duotone fa-notes",
  GameMission: "fa-duotone fa-scroll",
  Location: "fa-duotone fa-planet-ringed",
  FleetContract: "fa-duotone fa-clipboard-list",
  FleetEvent: "fa-duotone fa-calendar-day",
  User: "fa-duotone fa-user",
};

export const catalogueTokenIcon = (typeOrPrefix?: string | null): Icon =>
  (typeOrPrefix && ICONS[typeOrPrefix]) || "fa-duotone fa-cube";

export const catalogueTokenPrefix = (token: string) => {
  const [prefix, ...rest] = token.split(":");
  const lowered = prefix.trim().toLowerCase();

  return rest.length &&
    CATALOGUE_TOKEN_TYPES.includes(lowered as CatalogueTokenType)
    ? lowered
    : undefined;
};
