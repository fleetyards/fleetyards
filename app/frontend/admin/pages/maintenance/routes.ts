import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "pghero/",
    name: "pghero",
    component: () => import("@/admin/pages/maintenance/pghero.vue"),
    meta: {
      title: "admin.maintenance.pghero",
      icon: "fad fa-database",
      needsAuthentication: true,
      access: ["pghero"],
    },
  },
  {
    path: "features/",
    name: "features",
    component: () => import("@/admin/pages/maintenance/features.vue"),
    meta: {
      title: "admin.maintenance.features",
      icon: "fad fa-circle-star",
      needsAuthentication: true,
      access: ["features"],
    },
  },
  {
    path: "workers/",
    name: "workers",
    component: () => import("@/admin/pages/maintenance/workers.vue"),
    meta: {
      title: "admin.maintenance.workers",
      icon: "fad fa-list-timeline",
      needsAuthentication: true,
      access: ["workers"],
    },
  },
  {
    path: "tasks/",
    name: "tasks",
    component: () => import("@/admin/pages/maintenance/tasks.vue"),
    meta: {
      title: "admin.maintenance.tasks",
      icon: "fad fa-list-timeline",
      needsAuthentication: true,
      access: ["maintenance"],
    },
  },
  {
    path: "rsi-api-status/",
    name: "rsi-api-status",
    component: () => import("@/admin/pages/maintenance/rsi-api-status.vue"),
    meta: {
      title: "admin.maintenance.rsiApiStatus",
      icon: "fad fa-chart-line",
      needsAuthentication: true,
      access: ["rsi-api-status"],
    },
  },
];
