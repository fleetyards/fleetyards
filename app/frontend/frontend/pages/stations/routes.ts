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
    path: ":slug/",
    name: "station",
    component: () => import("@/frontend/pages/stations/[slug].vue"),
    meta: {
      backgroundImage: "bg-0",
    },
  },
  {
    path: ":slug/images/",
    name: "station-images",
    component: () => import("@/frontend/pages/stations/[slug]/images.vue"),
    meta: {
      backgroundImage: "bg-0",
    },
  },
  {
    path: ":slug/shops/:shopSlug/",
    name: "shop",
    component: () =>
      import("@/frontend/pages/stations/[slug]/shops/[shopSlug].vue"),
    meta: {
      backgroundImage: "bg-2",
    },
  },
];

export default routes;
