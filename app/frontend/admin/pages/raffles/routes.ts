import type { RouteRecordRaw } from "vue-router";
import { routes as raffleRoutes } from "@/admin/pages/raffles/[id]/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "admin-raffles",
    component: () => import("@/admin/pages/raffles/index.vue"),
    strict: true,
    meta: {
      mobileBack: true,
      title: "admin.raffles.index",
      needsAuthentication: true,
      access: ["raffles"],
    },
  },
  {
    path: "create/",
    name: "admin-raffle-create",
    component: () => import("@/admin/pages/raffles/create.vue"),
    meta: {
      title: "admin.raffles.new",
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-raffles",
    },
  },
  {
    path: ":id/",
    component: () => import("@/admin/pages/raffles/[id].vue"),
    children: raffleRoutes,
    redirect: { name: raffleRoutes[0].name },
    meta: {
      needsAuthentication: true,
      nav: "hidden",
      activeRoute: "admin-raffles",
    },
  },
];
