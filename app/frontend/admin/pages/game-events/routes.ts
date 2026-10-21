import type { RouteRecordRaw } from "vue-router";
import { routes as gameEventRoutes } from "@/admin/pages/game-events/[id]/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-game-events",
    component: () => import("@/admin/pages/game-events/index.vue"),
    strict: true,
    meta: {
      mobileBack: true,
      title: "admin.gameEvents.index",
      needsAuthentication: true,
      access: ["game_events"],
    },
  },
  {
    path: "create/",
    name: "admin-game-event-create",
    component: () => import("@/admin/pages/game-events/create.vue"),
    meta: {
      title: "admin.gameEvents.new",
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-game-events",
    },
  },
  {
    path: ":id/",
    component: () => import("@/admin/pages/game-events/[id].vue"),
    children: gameEventRoutes,
    redirect: { name: gameEventRoutes[0].name },
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-game-events",
    },
  },
];
