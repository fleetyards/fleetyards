import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "stations",
    component: () => import("@/frontend/pages/stations/index.vue"),
    meta: {
      title: "stations",
      quickSearch: "searchCont",
      backgroundImage: "bg-0",
    },
  },
  {
    path: "/starsystems/",
    name: "starsystems",
    component: () => import("@/frontend/pages/stations/Starsystems/index.vue"),
    meta: {
      title: "starsystems",
      backgroundImage: "bg-0",
    },
  },
  {
    path: "/starsystems/:slug/",
    name: "starsystem",
    component: () => import("@/frontend/pages/stations/Starsystem/index.vue"),
    meta: {
      backgroundImage: "bg-0",
    },
  },
  {
    path: "/starsystems/:starsystem/celestial-objects/:slug/",
    name: "celestial-object",
    component: () =>
      import("@/frontend/pages/stations/CelestialObject/index.vue"),
    meta: {
      backgroundImage: "bg-0",
    },
  },
  {
    path: "/shops/",
    name: "shops",
    component: () => import("@/frontend/pages/stations/ShopList/index.vue"),
    meta: {
      title: "shops",
      backgroundImage: "bg-2",
      quickSearch: "searchCont",
    },
  },
  {
    path: ":slug/",
    name: "station",
    component: () => import("@/frontend/pages/stations/Show/index.vue"),
    meta: {
      backgroundImage: "bg-0",
    },
  },
  {
    path: ":slug/images/",
    name: "station-images",
    component: () => import("@/frontend/pages/stations/Show/Images/index.vue"),
    meta: {
      backgroundImage: "bg-0",
    },
  },
  {
    path: ":stationSlug/shops/:slug/",
    name: "shop",
    component: () => import("@/frontend/pages/stations/Shop/index.vue"),
    meta: {
      backgroundImage: "bg-2",
    },
  },
];

export default routes;
