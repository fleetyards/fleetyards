import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-blueprints",
    component: () => import("@/admin/pages/blueprints/index.vue"),
    strict: true,
    meta: {
      needsAuthentication: true,
      access: ["blueprints"],
    },
  },
  /*
   * No `create/` and no `[id]/edit/` tree: every blueprint fact lives on a
   * build the next load replaces, so there is nothing here a human can own.
   */
  {
    path: ":id/",
    name: "admin-blueprint",
    component: () => import("@/admin/pages/blueprints/[id].vue"),
    meta: {
      title: "admin.blueprints.show",
      customTitle: true,
      needsAuthentication: true,
      nav: "hidden",
      // The nav lights its rows by route name, and a detail page is a sibling
      // of the list rather than a child of it -- without this the Blueprints
      // row goes dark the moment you open a recipe.
      activeRoute: "admin-blueprints",
      access: ["blueprints"],
    },
  },
];
