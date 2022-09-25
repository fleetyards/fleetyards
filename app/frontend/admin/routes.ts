export const routes = [
  {
    path: "/models/:uuid/images",
    name: "model-images",
    component: () => import("@/admin/pages/Models/Images/index.vue"),
  },
  {
    path: "/stations/:uuid/images",
    name: "station-images",
    component: () => import("@/admin/pages/Stations/Images/index.vue"),
  },
  {
    path: "/shops/:shopId/commodities",
    name: "shop-commodities",
    component: () => import("@/admin/pages/Shops/Commodities/index.vue"),
  },
  {
    path: "/shop-commodities/confirmation",
    name: "shop-commodity-confirmations",
    component: () =>
      import("@/admin/pages/ShopCommodities/Confirmation/index.vue"),
  },
  {
    path: "/commodity-prices/confirmation",
    name: "commodity-price-confirmations",
    component: () =>
      import("@/admin/pages/CommodityPrices/Confirmation/index.vue"),
  },
  {
    path: "/images",
    name: "images",
    component: () => import("@/admin/pages/Images/index.vue"),
  },
];

export default routes;
