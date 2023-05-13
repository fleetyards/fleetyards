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
];

export default routes;
