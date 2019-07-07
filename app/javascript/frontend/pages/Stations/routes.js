export const routes = [
  {
    path: '/starsystems',
    name: 'starsystems',
    component: () => import(/* webpackChunkName: "frontend.page.starsystems" */ 'frontend/pages/Stations/Starsystems'),
    meta: {
      title: 'starsystems',
    },
  }, {
    path: '/starsystems/:slug',
    name: 'starsystem',
    component: () => import(/* webpackChunkName: "frontend.page.starsystem" */ 'frontend/pages/Stations/Starsystem'),
  }, {
    path: '/celestial-objects/:slug',
    name: 'celestialObject',
    component: () => import(/* webpackChunkName: "frontend.page.celestial-object" */ 'frontend/pages/Stations/CelestialObject'),
  }, {
    path: '/shops',
    name: 'shops',
    component: () => import(/* webpackChunkName: "frontend.page.station.shops" */ 'frontend/pages/Stations/ShopList'),
    meta: {
      title: 'shops',
    },
  }, {
    path: ':slug',
    name: 'station',
    component: () => import(/* webpackChunkName: "frontend.page.station" */ 'frontend/pages/Stations/Show'),
  }, {
    path: ':station/shops/:slug',
    name: 'shop',
    component: () => import(/* webpackChunkName: "frontend.page.stations.shop" */ 'frontend/pages/Stations/Shop'),
  },
]

export default routes
