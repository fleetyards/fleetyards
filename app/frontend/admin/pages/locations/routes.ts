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
  // A load replaces every fact; only how a place is drawn is edited.
  {
    path: ":id/edit/",
    name: "admin-location-edit",
    component: () => import("@/admin/pages/locations/[id]/edit.vue"),
    meta: {
      customTitle: true,
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-locations",
      access: ["locations"],
    },
  },
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
