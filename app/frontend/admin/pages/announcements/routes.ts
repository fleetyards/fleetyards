import type { RouteRecordRaw } from "vue-router";
import { routes as announcementRoutes } from "@/admin/pages/announcements/[id]/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-announcements",
    component: () => import("@/admin/pages/announcements/index.vue"),
    strict: true,
    meta: {
      title: "admin.announcements.index",
      needsAuthentication: true,
      access: ["announcements"],
    },
  },
  {
    path: "create/",
    name: "admin-announcement-create",
    component: () => import("@/admin/pages/announcements/create.vue"),
    meta: {
      title: "admin.announcements.new",
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-announcements",
    },
  },
  {
    path: ":id/",
    component: () => import("@/admin/pages/announcements/[id].vue"),
    children: announcementRoutes,
    redirect: { name: announcementRoutes[0].name },
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-announcements",
    },
  },
];
