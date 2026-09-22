import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-missions",
    component: () => import("@/admin/pages/missions/index.vue"),
    strict: true,
    meta: {
      needsAuthentication: true,
      access: ["missions"],
    },
  },
  /*
   * No `create/` and no `[id]/edit/` tree: every mission fact lives on a build
   * the next load replaces, so there is nothing here a human can own.
   */
  {
    path: ":id/",
    name: "admin-mission",
    component: () => import("@/admin/pages/missions/[id].vue"),
    meta: {
      title: "admin.missions.show",
      customTitle: true,
      needsAuthentication: true,
      nav: "hidden",
      // The nav lights its rows by route name, and a detail page is a sibling
      // of the list rather than a child of it -- without this the Missions row
      // goes dark the moment you open one.
      activeRoute: "admin-missions",
      access: ["missions"],
    },
  },
];
