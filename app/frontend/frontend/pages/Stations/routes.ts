import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "/starsystems/",
    name: "starsystems",
    component: () => import("@/frontend/pages/Stations/Starsystems/index.vue"),
    meta: {
      title: "starsystems",
      backgroundImage: "bg-0",
    },
  },
  {
    path: "/starsystems/:slug/",
    name: "starsystem",
    component: () => import("@/frontend/pages/Stations/Starsystem/index.vue"),
    meta: {
      backgroundImage: "bg-0",
    },
  },
  {
    path: "/starsystems/:starsystem/celestial-objects/:slug/",
    name: "celestial-object",
    component: () =>
      import("@/frontend/pages/Stations/CelestialObject/index.vue"),
    meta: {
      backgroundImage: "bg-0",
    },
  },
  {
    path: "/shops/",
    name: "shops",
    component: () => import("@/frontend/pages/Stations/ShopList/index.vue"),
    meta: {
      title: "shops",
      backgroundImage: "bg-2",
      quickSearch: "searchCont",
    },
  },
  {
    path: ":slug/",
    name: "station",
    component: () => import("@/frontend/pages/Stations/Show/index.vue"),
    meta: {
      backgroundImage: "bg-0",
    },
  },
  {
    path: ":slug/images/",
    name: "station-images",
    component: () => import("@/frontend/pages/Stations/Show/Images/index.vue"),
    meta: {
      backgroundImage: "bg-0",
    },
  },
  {
    path: ":stationSlug/shops/:slug/",
    name: "shop",
    component: () => import("@/frontend/pages/Stations/Shop/index.vue"),
    meta: {
      backgroundImage: "bg-2",
    },
  },
];

export default routes;
