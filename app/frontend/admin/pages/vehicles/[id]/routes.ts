import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "edit",
    name: "admin-vehicle-edit",
    component: () => import("@/admin/pages/vehicles/[id]/edit.vue"),
    meta: {
      title: "admin.vehicles.edit",
      activeRoute: "admin-vehicles",
      needsAuthentication: true,
    },
  },
];
