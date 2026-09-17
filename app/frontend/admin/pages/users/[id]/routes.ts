import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "edit",
    name: "admin-user-edit",
    component: () => import("@/admin/pages/users/[id]/edit.vue"),
    meta: {
      title: "admin.users.edit",
      activeRoute: "users",
      needsAuthentication: true,
    },
  },
  {
    path: "inventories",
    name: "admin-user-inventories",
    component: () => import("@/admin/pages/users/[id]/inventories.vue"),
    meta: {
      title: "admin.users.inventories",
      activeRoute: "users",
      needsAuthentication: true,
    },
  },
  {
    path: "supporter-contributions",
    name: "admin-user-supporter-contributions",
    component: () =>
      import("@/admin/pages/users/[id]/supporter-contributions.vue"),
    meta: {
      title: "admin.users.supporterContributions",
      activeRoute: "users",
      needsAuthentication: true,
      access: ["supporters"],
    },
  },
  {
    path: "fleets",
    name: "admin-user-fleets",
    component: () => import("@/admin/pages/users/[id]/fleets.vue"),
    meta: {
      title: "admin.users.fleets",
      activeRoute: "users",
      needsAuthentication: true,
    },
  },
];
