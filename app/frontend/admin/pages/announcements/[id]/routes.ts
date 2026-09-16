import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "edit",
    name: "admin-announcement-edit",
    component: () => import("@/admin/pages/announcements/[id]/edit.vue"),
    meta: {
      title: "admin.announcements.edit",
      activeRoute: "admin-announcements",
      needsAuthentication: true,
    },
  },
];
