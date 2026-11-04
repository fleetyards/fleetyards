import type { RouteLocationRaw } from "vue-router";

// A value the record is filed under -- category, type. Each is a link where
// the list can be narrowed by it.
export interface ItemCardFacet {
  key: string;
  label: string;
  to?: RouteLocationRaw;
}

export interface ItemCardStat {
  label: string;
  value: string;
}

export interface ItemCardMaker {
  name: string;
  // Shown where there is no logo, so the pill stays the size of a mark.
  code?: string;
  logo?: string;
  to?: RouteLocationRaw;
}
