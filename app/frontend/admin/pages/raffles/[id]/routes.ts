import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "entries",
    name: "admin-raffle-entries",
    component: () => import("@/admin/pages/raffles/[id]/entries.vue"),
    meta: {
      title: "admin.raffles.entries",
      activeRoute: "admin-raffles",
      needsAuthentication: true,
    },
  },
  {
    path: "edit",
    name: "admin-raffle-edit",
    component: () => import("@/admin/pages/raffles/[id]/edit.vue"),
    meta: {
      title: "admin.raffles.edit",
      activeRoute: "admin-raffles",
      needsAuthentication: true,
    },
  },
];
