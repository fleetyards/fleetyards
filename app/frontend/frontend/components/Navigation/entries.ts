import { SHIP_GLYPH } from "@/shared/glyphs/ships";
import type { Glyph } from "@/shared/components/DuotoneGlyph/glyph";
import { FeatureFlagName } from "@/services/fyApi";
import { CATALOGUE_TENANTS } from "@/frontend/pages/catalogue/tenants";

/**
 * A page the navigation links to. The key doubles as the row's test id, so it
 * equals the route name.
 */
export interface NavEntry {
  key: string;
  route: string;
  labelKey: string;
  icon: string | Glyph;
  requiresAuth?: boolean;
  featureFlag?: FeatureFlagName;
  // Routes that are this page too -- a detail page is a sibling of its list,
  // so matching on the name alone would leave the list unmarked there.
  activeRoutes?: string[];
}

/**
 * Rows a section folds behind one row of its own, so a long section stays short
 * until the reader asks for more.
 */
export interface NavSubsection {
  key: string;
  labelKey: string;
  icon: string | Glyph;
  entries: NavEntry[];
}

export type NavSectionItem = NavEntry | NavSubsection;

export const isSubsection = (item: NavSectionItem): item is NavSubsection =>
  "entries" in item;

export const HOME_ENTRY: NavEntry = {
  key: "home",
  route: "home",
  labelKey: "nav.home",
  icon: "fa-duotone fa-home-alt",
};

/*
 * What the reader looks at most stays on top; the assets kept in the hangar and
 * what was pledged for each fold behind a row of their own.
 */
export const HANGAR_ITEMS: NavSectionItem[] = [
  {
    key: "hangar",
    route: "hangar",
    labelKey: "nav.hangar.overview",
    icon: "fa-duotone fa-warehouse",
    requiresAuth: true,
  },
  {
    key: "hangar-wishlist",
    route: "hangar-wishlist",
    labelKey: "nav.hangar.wishlist",
    icon: "fa-duotone fa-wand-sparkles",
    requiresAuth: true,
  },
  {
    key: "hangar-stats",
    route: "hangar-stats",
    labelKey: "nav.hangar.stats",
    icon: "fa-duotone fa-chart-pie",
    requiresAuth: true,
  },
  {
    key: "hangar-plans",
    route: "hangar-plans",
    labelKey: "nav.hangar.plans",
    icon: "fa-duotone fa-compass-drafting",
    requiresAuth: true,
    featureFlag: FeatureFlagName.HANGAR_PLANNER,
    activeRoutes: ["hangar-plan", "hangar-plan-slots", "hangar-plan-compare"],
  },
  {
    key: "hangar-assets-menu",
    labelKey: "nav.hangar.assets",
    icon: "fa-duotone fa-layer-group",
    entries: [
      {
        key: "hangar-blueprints",
        route: "hangar-blueprints",
        labelKey: "nav.hangar.blueprints",
        icon: "fa-duotone fa-notes",
        requiresAuth: true,
      },
      {
        key: "hangar-inventories",
        route: "hangar-inventories",
        labelKey: "nav.hangar.inventories",
        icon: "fa-duotone fa-boxes-stacked",
        requiresAuth: true,
        activeRoutes: [
          "hangar-inventory",
          "hangar-inventory-item",
          "hangar-transfers",
        ],
      },
    ],
  },
  {
    key: "hangar-pledge-items-menu",
    labelKey: "nav.hangar.pledgeItems",
    icon: "fa-duotone fa-box-open",
    entries: [
      {
        key: "hangar-paints",
        route: "hangar-paints",
        labelKey: "nav.hangar.paints",
        icon: "fa-duotone fa-paint-roller",
        requiresAuth: true,
      },
      {
        key: "hangar-flair",
        route: "hangar-flair",
        labelKey: "nav.hangar.flair",
        icon: "fa-duotone fa-trophy-star",
        requiresAuth: true,
      },
      {
        key: "hangar-equipment",
        route: "hangar-equipment",
        labelKey: "nav.hangar.equipment",
        icon: "fa-duotone fa-shirt",
        requiresAuth: true,
      },
      {
        key: "hangar-ship-components",
        route: "hangar-ship-components",
        labelKey: "nav.hangar.shipComponents",
        icon: "fa-duotone fa-microchip",
        requiresAuth: true,
      },
      {
        key: "hangar-upgrades",
        route: "hangar-upgrades",
        labelKey: "nav.hangar.upgrades",
        icon: "fa-duotone fa-arrow-up",
        requiresAuth: true,
      },
      {
        key: "hangar-buybacks",
        route: "hangar-buybacks",
        labelKey: "nav.hangar.buybacks",
        icon: "fa-duotone fa-rotate-left",
        requiresAuth: true,
      },
    ],
  },
];

export const SHIPS_ITEMS: NavEntry[] = [
  {
    key: "ships",
    route: "ships",
    labelKey: "nav.ships.index",
    icon: SHIP_GLYPH,
    activeRoutes: ["ship", "ship-images", "ship-videos"],
  },
  {
    key: "compare",
    route: "compare",
    labelKey: "nav.compare.index",
    icon: "fa-duotone fa-code-compare",
  },
  {
    key: "images",
    route: "images",
    labelKey: "nav.images",
    icon: "fa-duotone fa-images",
  },
];

export const CATALOGUE_ENTRIES: NavEntry[] = CATALOGUE_TENANTS.map(
  (tenant) => ({
    key: tenant.listRoute,
    route: tenant.listRoute,
    labelKey: `nav.catalogue.${tenant.key}`,
    icon: tenant.icon,
    activeRoutes: tenant.detailRoutes,
  }),
);

// A shop is at a place, so its page belongs to the places too.
export const LOCATIONS_ENTRY: NavEntry = {
  key: "locations",
  route: "locations",
  labelKey: "nav.locations",
  icon: "fa-duotone fa-planet-ringed",
  activeRoutes: ["locations-places", "location", "shop"],
};

export const FLEET_DIRECTORY_ENTRY: NavEntry = {
  key: "fleet-directory",
  route: "fleet-directory",
  labelKey: "nav.fleets.directory",
  icon: "fa-duotone fa-magnifying-glass",
};

export const TOOLS_ITEMS: NavEntry[] = [
  {
    key: "tools",
    route: "tools",
    labelKey: "nav.tools.overview",
    icon: "fa-duotone fa-browsers",
  },
  {
    key: "travel-times",
    route: "travel-times",
    labelKey: "nav.tools.travelTimes",
    icon: "fa-duotone fa-gauge-high",
  },
  {
    key: "tours",
    route: "tours",
    labelKey: "nav.tools.tours",
    icon: "fa-duotone fa-coins",
    activeRoutes: ["tour", "tour-add", "tour-join"],
  },
  {
    key: "cargo-grids",
    route: "cargo-grids",
    labelKey: "nav.tools.cargoGrids",
    icon: "fa-duotone fa-thin fa-cubes",
  },
  {
    key: "plaque-tool",
    route: "plaque-tool",
    labelKey: "nav.tools.plaque",
    icon: "fa-duotone fa-award",
  },
  {
    key: "trade-routes",
    route: "trade-routes",
    labelKey: "nav.tools.tradeRoutes",
    icon: "fa-duotone fa-route",
  },
];

export const STATS_ENTRY: NavEntry = {
  key: "stats",
  route: "stats",
  labelKey: "nav.stats",
  icon: "fa-duotone fa-chart-bar",
};

export const NAV_ENTRIES: NavEntry[] = [
  HOME_ENTRY,
  ...HANGAR_ITEMS.flatMap((item) => (isSubsection(item) ? item.entries : item)),
  ...SHIPS_ITEMS,
  ...CATALOGUE_ENTRIES,
  LOCATIONS_ENTRY,
  FLEET_DIRECTORY_ENTRY,
  ...TOOLS_ITEMS,
  STATS_ENTRY,
];

export const isEntryActive = (entry: NavEntry, routeName: string) =>
  entry.route === routeName || !!entry.activeRoutes?.includes(routeName);

export const isAnyEntryActive = (
  items: NavSectionItem[],
  routeName: string,
): boolean =>
  items.some((item) =>
    isSubsection(item)
      ? isAnyEntryActive(item.entries, routeName)
      : isEntryActive(item, routeName),
  );
