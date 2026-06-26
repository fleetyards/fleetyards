import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-destroyed-fleets",
    component: () => import("@/admin/pages/destroyed-fleets/index.vue"),
    strict: true,
    meta: {
      needsAuthentication: true,
      access: ["fleets"],
    },
  },
];
