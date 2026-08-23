import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-equipment-edit",
    component: () => import("@/admin/pages/equipment/[id]/edit/index.vue"),
    meta: {
      title: "admin.equipment.edit.index",
      customTitle: true,
      needsAuthentication: true,
      nav: "editTabs",
      activeRoute: "admin-equipment",
    },
  },
  {
    path: "prices/",
    name: "admin-equipment-edit-prices",
    component: () => import("@/admin/pages/equipment/[id]/edit/prices.vue"),
    meta: {
      title: "admin.equipment.edit.prices",
      customTitle: true,
      activeRoute: "admin-equipment",
      nav: "editTabs",
      needsAuthentication: true,
    },
  },
];
