import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-locations",
    component: () => import("@/admin/pages/locations/index.vue"),
    strict: true,
    meta: {
      needsAuthentication: true,
      access: ["locations"],
    },
  },
  // Read only, like missions: a load replaces every fact.
  {
    path: ":id/",
    name: "admin-location",
    component: () => import("@/admin/pages/locations/[id].vue"),
    meta: {
      title: "admin.locations.show",
      customTitle: true,
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-locations",
      access: ["locations"],
    },
  },
];
