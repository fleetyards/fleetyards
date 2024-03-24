import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "starsystems",
    component: () => import("@/frontend/pages/starsystems/index.vue"),
    meta: {
      title: "starsystems",
      backgroundImage: "bg-0",
    },
  },
  {
    path: "/starsystems/:slug/",
    name: "starsystem",
    component: () => import("@/frontend/pages/starsystems/[slug].vue"),
    meta: {
      backgroundImage: "bg-0",
    },
  },
  {
    path: "/starsystems/:starsystem/celestial-objects/:slug/",
    name: "celestial-object",
    component: () =>
      import(
        "@/frontend/pages/starsystems/[slug]/celestial-objects/[slug].vue"
      ),
    meta: {
      backgroundImage: "bg-0",
    },
  },
];

export default routes;
