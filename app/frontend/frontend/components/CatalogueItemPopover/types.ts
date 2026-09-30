import {
  type Commodity,
  type Component,
  type Equipment,
} from "@/services/fyApi";

// The shape every catalogue reference already has -- a recipe's output, a
// stock position's item, a contract line -- and the one `catalogueItemRoute`
// reads.
export interface CatalogueItemRef {
  type?: string | null;
  slug?: string | null;
  name?: string | null;
  // False for a record the catalogue leaves out, whose page would 404.
  listed?: boolean;
}

export type CatalogueRecord = Component | Equipment | Commodity;
