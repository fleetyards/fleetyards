export const routes = [
  {
    path: '/models/:uuid/images',
    name: 'model-images',
    component: () =>
      import(
        /* webpackChunkName: "page.admin.model-images" */ 'admin/pages/Models/Images/index.vue'
      ),
  },
  {
    path: '/stations/:uuid/images',
    name: 'station-images',
    component: () =>
      import(
        /* webpackChunkName: "page.admin.station-images" */ 'admin/pages/Stations/Images/index.vue'
      ),
  },
  {
    path: '/shops/:shopId/commodities',
    name: 'shop-commodities',
    component: () =>
      import(
        /* webpackChunkName: "page.admin.shop-commodities" */ 'admin/pages/Shops/Commodities/index.vue'
      ),
  },
  {
    path: '/shop-commodities/confirmation',
    name: 'shop-commodity-confirmations',
    component: () =>
      import(
        /* webpackChunkName: "page.admin.shop-commodities" */ 'admin/pages/ShopCommodities/Confirmation/index.vue'
      ),
  },
  {
    path: '/commodity-prices/confirmation',
    name: 'commodity-price-confirmations',
    component: () =>
      import(
        /* webpackChunkName: "page.admin.commodity-prices" */ 'admin/pages/CommodityPrices/Confirmation/index.vue'
      ),
  },
  {
    path: '/images',
    name: 'images',
    component: () =>
      import(
        /* webpackChunkName: "page.admin.images" */ 'admin/pages/Images/index.vue'
      ),
  },
]

export default routes
