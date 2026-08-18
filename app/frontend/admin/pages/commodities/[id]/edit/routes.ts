import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-commodity-edit",
    component: () => import("@/admin/pages/commodities/[id]/edit/index.vue"),
    meta: {
      title: "admin.commodities.edit.index",
      customTitle: true,
      needsAuthentication: true,
      nav: "editTabs",
      activeRoute: "admin-commodities",
    },
  },
];
