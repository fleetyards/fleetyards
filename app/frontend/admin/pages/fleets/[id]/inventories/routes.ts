import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "inventories/:inventoryId",
    name: "admin-fleet-inventory",
    component: () =>
      import("@/admin/pages/fleets/[id]/inventories/[inventoryId].vue"),
    meta: {
      title: "admin.fleets.inventory",
      activeRoute: "admin-fleets",
      needsAuthentication: true,
    },
  },
  {
    path: "inventories/:inventoryId/items/:itemId",
    name: "admin-fleet-inventory-item",
    component: () =>
      import("@/admin/pages/fleets/[id]/inventories/[inventoryId]/items/[itemId].vue"),
    meta: {
      title: "admin.fleets.inventoryItem",
      activeRoute: "admin-fleets",
      needsAuthentication: true,
    },
  },
];
