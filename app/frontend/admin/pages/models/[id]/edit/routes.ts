import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-model-edit",
    component: () => import("@/admin/pages/models/[id]/edit/index.vue"),
    meta: {
      title: "admin.models.edit.index",
      needsAuthentication: true,
      nav: "editTabs",
      activeRoute: "admin-models",
    },
  },
  {
    path: "metrics/",
    name: "admin-model-edit-metrics",
    component: () => import("@/admin/pages/models/[id]/edit/metrics.vue"),
    meta: {
      title: "admin.models.edit.metrics",
      activeRoute: "admin-models",
      nav: "editTabs",
      needsAuthentication: true,
    },
  },
  {
    path: "cargo-and-fuel/",
    name: "admin-model-edit-cargo-and-fuel",
    component: () =>
      import("@/admin/pages/models/[id]/edit/cargo-and-fuel.vue"),
    meta: {
      title: "admin.models.edit.cargoAndFuel",
      activeRoute: "admin-models",
      nav: "editTabs",
      needsAuthentication: true,
    },
  },
  {
    path: "prices/",
    name: "admin-model-edit-prices",
    component: () => import("@/admin/pages/models/[id]/edit/prices.vue"),
    meta: {
      title: "admin.models.edit.prices",
      activeRoute: "admin-models",
      nav: "editTabs",
      needsAuthentication: true,
    },
  },
  {
    path: "fleetchart/",
    name: "admin-model-edit-fleetchart",
    component: () => import("@/admin/pages/models/[id]/edit/fleetchart.vue"),
    meta: {
      title: "admin.models.edit.fleetchart",
      activeRoute: "admin-models",
      nav: "editTabs",
      needsAuthentication: true,
    },
  },
  {
    path: "hardpoints/",
    name: "admin-model-edit-hardpoints",
    component: () => import("@/admin/pages/models/[id]/edit/hardpoints.vue"),
    meta: {
      title: "admin.models.edit.hardpoints",
      activeRoute: "admin-models",
      nav: "editTabs",
      needsAuthentication: true,
    },
  },
  {
    path: "docks/",
    name: "admin-model-edit-docks",
    component: () => import("@/admin/pages/models/[id]/edit/docks.vue"),
    meta: {
      title: "admin.models.edit.docks",
      activeRoute: "admin-models",
      nav: "editTabs",
      needsAuthentication: true,
    },
  },
  {
    path: "videos/",
    name: "admin-model-edit-videos",
    component: () => import("@/admin/pages/models/[id]/edit/videos.vue"),
    meta: {
      title: "admin.models.edit.videos",
      activeRoute: "admin-models",
      nav: "editTabs",
      needsAuthentication: true,
    },
  },
];
