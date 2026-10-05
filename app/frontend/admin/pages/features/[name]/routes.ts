import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-feature",
    component: () => import("@/admin/pages/features/[name]/overview.vue"),
    meta: {
      title: "admin.features.overview",
      needsAuthentication: true,
      access: ["features"],
    },
  },
  {
    path: "users/",
    name: "admin-feature-users",
    component: () => import("@/admin/pages/features/[name]/users.vue"),
    meta: {
      title: "admin.features.users",
      needsAuthentication: true,
      access: ["features"],
    },
  },
  {
    path: "fleets/",
    name: "admin-feature-fleets",
    component: () => import("@/admin/pages/features/[name]/fleets.vue"),
    meta: {
      title: "admin.features.fleets",
      needsAuthentication: true,
      access: ["features"],
    },
  },
  {
    path: "history/",
    name: "admin-feature-history",
    component: () => import("@/admin/pages/features/[name]/history.vue"),
    meta: {
      title: "admin.features.history",
      needsAuthentication: true,
      access: ["features"],
    },
  },
];
