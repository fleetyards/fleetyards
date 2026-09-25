import { type RouteLocationRaw } from "vue-router";

const DETAIL_ROUTES: Record<string, string> = {
  Component: "component",
  Equipment: "equipment-item",
  Commodity: "commodity",
};

type CatalogueRef = {
  type?: string | null;
  slug?: string | null;
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
  const name = ref?.type ? DETAIL_ROUTES[ref.type] : undefined;

  return name && ref?.slug && ref.listed !== false
    ? { name, params: { slug: ref.slug } }
    : undefined;
};
