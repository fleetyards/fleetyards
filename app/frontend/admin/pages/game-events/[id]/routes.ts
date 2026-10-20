import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "edit",
    name: "admin-game-event-edit",
    component: () => import("@/admin/pages/game-events/[id]/edit.vue"),
    meta: {
      title: "admin.gameEvents.edit",
      activeRoute: "admin-game-events",
      needsAuthentication: true,
    },
  },
];
