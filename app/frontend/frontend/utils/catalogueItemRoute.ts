import { type RouteLocationRaw } from "vue-router";

const DETAIL_ROUTES: Record<string, string> = {
  Component: "component",
  Equipment: "equipment-item",
  Commodity: "commodity",
  Model: "ship",
  Blueprint: "blueprint",
  GameMission: "mission",
};

type CatalogueRef = {
  type?: string | null;
  slug?: string | null;
  // The fleet a contract or an event belongs to.
  fleetSlug?: string | null;
  // False for a record the catalogue leaves out, such as a hidden equipment
  // variant, whose page would 404.
  listed?: boolean;
};

// Where a catalogue record has its page, for any of the references that point
// at one -- a recipe's output, a ledger entry, a stock position, a contract
// line. A reference the catalogue cannot resolve is an absent link rather than
// a broken one.
export const catalogueItemRoute = (
  ref?: CatalogueRef | null,
): RouteLocationRaw | undefined => {
  if (!ref?.slug) return undefined;

  if (ref.type === "User") {
    return { name: "hangar-public", params: { username: ref.slug } };
  }

  if (ref.type === "FleetContract" || ref.type === "FleetEvent") {
    if (!ref.fleetSlug) return undefined;

    return ref.type === "FleetContract"
      ? {
          name: "fleet-contract",
          params: { slug: ref.fleetSlug, contract: ref.slug },
        }
      : {
          name: "fleet-event",
          params: { slug: ref.fleetSlug, event: ref.slug },
        };
  }

  const name = ref?.type ? DETAIL_ROUTES[ref.type] : undefined;

  return name && ref?.slug && ref.listed !== false
    ? { name, params: { slug: ref.slug } }
    : undefined;
};
