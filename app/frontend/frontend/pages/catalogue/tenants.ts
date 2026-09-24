import type { RouteRecordRaw } from "vue-router";
import { routes as blueprintsRoutes } from "@/frontend/pages/blueprints/routes";
import { routes as commoditiesRoutes } from "@/frontend/pages/commodities/routes";
import { routes as componentsRoutes } from "@/frontend/pages/components/routes";
import { routes as missionsRoutes } from "@/frontend/pages/missions/routes";

export type CatalogueTenant = {
  // The segment under `/catalogue/`, and the `nav.catalogue.*` key.
  key: string;
  icon: string;
  // A detail page is a sibling of its list rather than a child of it, so
  // vue-router's own active matching does not light the list's tab there. The
  // tenant names both of its routes and the nav asks it which one is showing.
  listRoute: string;
  detailRoutes: string[];
  component: RouteRecordRaw["component"];
  children: RouteRecordRaw[];
};

// The order of this list is the order of the section: the nav renders the
// tenants top to bottom in it, and `/catalogue/` lands on the first of them.
// Both read the list rather than naming a tenant themselves, so moving one to
// the front moves the section entry with it -- the redirect used to name
// `components` by hand and went on pointing there after blueprints had pages.
//
// A tenant joins the list once its *pages* exist, not once its API does: a tab
// pointing at a route with no page lands on the app's generic not-found, which
// is worse than the tab being absent. Equipment is the one still to come.
export const CATALOGUE_TENANTS: CatalogueTenant[] = [
  {
    key: "blueprints",
    icon: "fa-duotone fa-notes",
    listRoute: "blueprints",
    detailRoutes: ["blueprint"],
    component: () => import("@/frontend/pages/blueprints.vue"),
    children: blueprintsRoutes,
  },
  {
    key: "components",
    icon: "fa-duotone fa-microchip",
    listRoute: "components",
    detailRoutes: ["component", "component-history"],
    component: () => import("@/frontend/pages/components.vue"),
    children: componentsRoutes,
  },
  {
    key: "commodities",
    icon: "fa-duotone fa-boxes-stacked",
    listRoute: "commodities",
    detailRoutes: ["commodity"],
    component: () => import("@/frontend/pages/commodities.vue"),
    children: commoditiesRoutes,
  },
  {
    key: "missions",
    icon: "fa-duotone fa-scroll",
    listRoute: "missions",
    detailRoutes: ["mission"],
    component: () => import("@/frontend/pages/missions.vue"),
    children: missionsRoutes,
  },
];

export const catalogueEntryRoute = CATALOGUE_TENANTS[0].listRoute;

export const catalogueTenantRoutes: RouteRecordRaw[] = CATALOGUE_TENANTS.map(
  (tenant) => ({
    path: `/catalogue/${tenant.key}/`,
    component: tenant.component,
    children: tenant.children,
  }),
);

export const isTenantActive = (tenant: CatalogueTenant, routeName: string) =>
  tenant.listRoute === routeName || tenant.detailRoutes.includes(routeName);
