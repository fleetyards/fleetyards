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
      href: "/pghero",
    },
  },
  {
    path: "features/",
    name: "admin-features",
    component: () => import("@/admin/pages/maintenance/features.vue"),
    meta: {
      title: "admin.maintenance.features",
      icon: "fad fa-circle-star",
      needsAuthentication: true,
      access: ["features"],
    },
  },
  {
    path: "features/:name",
    name: "admin-feature",
    component: () => import("@/admin/pages/features/[name].vue"),
    meta: {
      title: "admin.features.show",
      needsAuthentication: true,
      access: ["features"],
      nav: "hidden",
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
      href: "/workers",
    },
  },
  {
    path: "tasks/",
    name: "tasks",
    component: () => import("@/admin/pages/maintenance/tasks.vue"),
    meta: {
      title: "admin.maintenance.tasks",
      icon: "fad fa-clipboard-list-check",
      needsAuthentication: true,
      access: ["maintenance"],
      href: "/maintenance_tasks",
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
