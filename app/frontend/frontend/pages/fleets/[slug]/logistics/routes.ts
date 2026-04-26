import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "fleet-logistics",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/logistics/index.vue"),
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.logistics.index",
      needsAuthentication: true,
      access: [
        "fleet:inventories:read",
        "fleet:inventories:manage",
        "fleet:manage",
      ],
      customTitle: true,
    },
  },
  {
    path: "inventories/",
    name: "fleet-logistics-inventories",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/logistics/inventories/index.vue"),
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.logistics.inventories",
      needsAuthentication: true,
      access: [
        "fleet:inventories:manage",
        "fleet:inventories:create",
        "fleet:manage",
      ],
      customTitle: true,
    },
  },
  {
    path: "inventories/:inventory/",
    name: "fleet-logistics-inventory",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/logistics/inventories/[inventory].vue"),
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.logistics.inventories",
      needsAuthentication: true,
      access: [
        "fleet:inventories:read",
        "fleet:inventories:manage",
        "fleet:manage",
      ],
      customTitle: true,
    },
  },
];
