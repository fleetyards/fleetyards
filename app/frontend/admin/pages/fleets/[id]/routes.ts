import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "edit",
    name: "admin-fleet-edit",
    component: () => import("@/admin/pages/fleets/[id]/edit.vue"),
    meta: {
      title: "admin.fleets.edit",
      activeRoute: "admin-fleets",
      needsAuthentication: true,
    },
  },
  {
    path: "members",
    name: "admin-fleet-members",
    component: () => import("@/admin/pages/fleets/[id]/members.vue"),
    meta: {
      title: "admin.fleets.members",
      activeRoute: "admin-fleets",
      needsAuthentication: true,
    },
  },
  {
    path: "roles",
    name: "admin-fleet-roles",
    component: () => import("@/admin/pages/fleets/[id]/roles.vue"),
    meta: {
      title: "admin.fleets.roles",
      activeRoute: "admin-fleets",
      needsAuthentication: true,
    },
  },
  {
    path: "inventories",
    name: "admin-fleet-inventories",
    component: () => import("@/admin/pages/fleets/[id]/inventories.vue"),
    meta: {
      title: "admin.fleets.inventories",
      activeRoute: "admin-fleets",
      needsAuthentication: true,
    },
  },
  {
    path: "history",
    name: "admin-fleet-history",
    component: () => import("@/admin/pages/fleets/[id]/history.vue"),
    meta: {
      title: "admin.fleets.history",
      activeRoute: "admin-fleets",
      needsAuthentication: true,
    },
  },
];
