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
    // The inventory list moved onto the logistics page itself. The path stays so
    // links people already shared keep resolving.
    path: "inventories/",
    name: "fleet-logistics-inventories",
    redirect: { name: "fleet-logistics" },
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
  {
    path: "inventories/:inventory/items/:item/",
    name: "fleet-logistics-inventory-item",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/logistics/inventories/[inventory]/[item].vue"),
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
