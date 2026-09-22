import type { RouteMeta, RouteRecordRaw } from "vue-router";

const meta: RouteMeta = {
  needsAuthentication: true,
  nav: "editTabs",
  activeRoute: "fleet-squadrons",
  access: ["fleet:squadrons:update", "fleet:squadrons:manage", "fleet:manage"],
  customTitle: true,
};

/*
 * Split by what each half is: the written squadron, and its pictures. They have
 * nothing to say to each other, and three file fields under three text fields
 * made one long form where neither half was findable.
 */
export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "fleet-squadron-edit",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/squadrons/[squadron]/edit/index.vue"),
    meta: { ...meta, title: "fleets.squadrons.edit.details" },
  },
  {
    path: "images/",
    name: "fleet-squadron-edit-images",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/squadrons/[squadron]/edit/images.vue"),
    meta: { ...meta, title: "fleets.squadrons.edit.images" },
  },
];
