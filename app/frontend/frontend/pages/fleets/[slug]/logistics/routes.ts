import type { RouteRecordRaw } from "vue-router";
import { FeatureFlagName } from "@/services/fyApi";

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
    // The ledger is a place you can link somebody to, so it is a route.
    path: "transactions/",
    name: "fleet-logistics-transactions",
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
    // Where `TransferNotifier` sends a fleet's inventory managers.
    path: "transfers/",
    name: "fleet-logistics-transfers",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/logistics/transfers.vue"),
    meta: {
      backgroundImage: "bg-8",
      title: "fleets.logistics.transfers",
      needsAuthentication: true,
      access: [
        "fleet:inventories:update",
        "fleet:inventories:manage",
        "fleet:manage",
      ],
      feature: FeatureFlagName.INVENTORY_TRANSFERS,
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
    path: "inventories/:inventory/transactions/",
    name: "fleet-logistics-inventory-transactions",
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
