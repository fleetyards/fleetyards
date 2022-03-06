export const routes = [
  {
    component: () =>
      import(
        /* webpackChunkName: "page.admin.model-images" */ '@/admin/pages/Models/Images/index.vue'
      ),
    name: 'model-images',
    path: '/models/:uuid/images',
  },
  {
    component: () =>
      import(
        /* webpackChunkName: "page.admin.station-images" */ '@/admin/pages/Stations/Images/index.vue'
      ),
    name: 'station-images',
    path: '/stations/:uuid/images',
  },
  {
    component: () =>
      import(
        /* webpackChunkName: "page.admin.shop-commodities" */ '@/admin/pages/Shops/Commodities/index.vue'
      ),
    name: 'shop-commodities',
    path: '/shops/:shopId/commodities',
  },
  {
    component: () =>
      import(
        /* webpackChunkName: "page.admin.shop-commodities" */ '@/admin/pages/ShopCommodities/Confirmation/index.vue'
      ),
    name: 'shop-commodity-confirmations',
    path: '/shop-commodities/confirmation',
  },
  {
    component: () =>
      import(
        /* webpackChunkName: "page.admin.commodity-prices" */ '@/admin/pages/CommodityPrices/Confirmation/index.vue'
      ),
    name: 'commodity-price-confirmations',
    path: '/commodity-prices/confirmation',
  },
  {
    component: () =>
      import(
        /* webpackChunkName: "page.admin.images" */ '@/admin/pages/Images/index.vue'
      ),
    name: 'images',
    path: '/images',
  },
]

export default routes
