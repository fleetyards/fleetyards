export const routes = [
  {
    path: "trade-routes/",
    name: "trade-routes",
    component: () => import("@/frontend/pages/Tools/TradeRoutes/index.vue"),
    meta: {
      title: "tools.tradeRoutes",
      backgroundImage: "bg-7",
    },
  },
  {
    path: "travel-times/",
    name: "travel-times",
    component: () => import("@/frontend/pages/Tools/TravelTimes/index.vue"),
    meta: {
      title: "tools.travelTimes",
      backgroundImage: "bg-8",
    },
  },
];

export default routes;
