import { SHIP_GLYPH } from "@/shared/glyphs/ships";
import type { Glyph } from "@/shared/components/DuotoneGlyph/glyph";
import { FeatureFlagName } from "@/services/fyApi";
import { CATALOGUE_TENANTS } from "@/frontend/pages/catalogue/tenants";

/**
 * A page the navigation can link to, and that a reader can pin to the top of
 * it.
 *
 * The key is what a favorite is stored as on the account, so it must not
 * change once shipped: a renamed key silently drops the page from every list
 * that pinned it. It equals the route name today only because route names are
 * already stable, lowercase and dashed.
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

export const HOME_ENTRY: NavEntry = {
  key: "home",
  route: "home",
  labelKey: "nav.home",
  icon: "fa-duotone fa-home-alt",
};

/*
 * Grouped by what the reader is doing: looking at the hangar, the assets kept in
 * it, and what was pledged for. The section draws a divider between groups.
 */
export const HANGAR_GROUPS: NavEntry[][] = [
  [
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
  ],
  [
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
  [
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
];

export const SHIPS_GROUPS: NavEntry[][] = [
  [
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
      labelKey: "nav.compare.ships",
      icon: "fa-duotone fa-code-compare",
    },
    {
      key: "images",
      route: "images",
      labelKey: "nav.images",
      icon: "fa-duotone fa-images",
    },
  ],
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

export const TOOLS_GROUPS: NavEntry[][] = [
  [
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
  ],
  [
    {
      key: "stats",
      route: "stats",
      labelKey: "nav.stats",
      icon: "fa-duotone fa-chart-bar",
    },
  ],
];

/**
 * Every page a reader can pin. The favorites section resolves stored keys
 * against this list, so a key nobody knows any more is simply not shown.
 */
export const NAV_ENTRIES: NavEntry[] = [
  HOME_ENTRY,
  ...HANGAR_GROUPS.flat(),
  ...SHIPS_GROUPS.flat(),
  ...CATALOGUE_ENTRIES,
  LOCATIONS_ENTRY,
  FLEET_DIRECTORY_ENTRY,
  ...TOOLS_GROUPS.flat(),
];

const ENTRIES_BY_KEY = new Map(NAV_ENTRIES.map((entry) => [entry.key, entry]));

export const findNavEntry = (key: string) => ENTRIES_BY_KEY.get(key);

export const isEntryActive = (entry: NavEntry, routeName: string) =>
  entry.route === routeName || !!entry.activeRoutes?.includes(routeName);

export const isAnyEntryActive = (groups: NavEntry[][], routeName: string) =>
  groups.some((group) =>
    group.some((entry) => isEntryActive(entry, routeName)),
  );
