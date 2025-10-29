import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "edit",
    name: "admin-model-paint-edit",
    component: () => import("@/admin/pages/models/paints/[id]/edit.vue"),
    meta: {
      title: "admin.modelPaints.edit",
      activeRoute: "admin-models-paints",
      needsAuthentication: true,
    },
  },
];
