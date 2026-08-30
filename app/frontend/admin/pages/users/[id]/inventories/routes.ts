import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "inventories/:inventoryId",
    name: "admin-user-inventory",
    component: () =>
      import("@/admin/pages/users/[id]/inventories/[inventoryId].vue"),
    meta: {
      title: "admin.users.inventory",
      activeRoute: "users",
      activeTab: "admin-user-inventories",
      needsAuthentication: true,
    },
  },
  {
    path: "inventories/:inventoryId/items/:itemId",
    name: "admin-user-inventory-item",
    component: () =>
      import("@/admin/pages/users/[id]/inventories/[inventoryId]/items/[itemId].vue"),
    meta: {
      title: "admin.users.inventoryItem",
      activeRoute: "users",
      activeTab: "admin-user-inventories",
      needsAuthentication: true,
    },
  },
];
