export const routes = [
  {
    path: '/starsystems',
    name: 'starsystems',
    component: () => import(/* webpackChunkName: "page.starsystems" */ 'frontend/pages/Stations/Starsystems'),
  }, {
    path: '/starsystems/:slug',
    name: 'starsystem',
    component: () => import(/* webpackChunkName: "page.starsystem" */ 'frontend/pages/Stations/Starsystem'),
  }, {
    path: '/celestial-objects/:slug',
    name: 'celestialObject',
    component: () => import(/* webpackChunkName: "page.celestial-object" */ 'frontend/pages/Stations/CelestialObject'),
  }, {
    path: '/shops',
    name: 'shops',
    component: () => import(/* webpackChunkName: "page.station.shops" */ 'frontend/pages/Stations/ShopList'),
  }, {
    path: ':slug',
    name: 'station',
    component: () => import(/* webpackChunkName: "page.station" */ 'frontend/pages/Stations/Show'),
  }, {
    path: ':station/shops/:slug',
    name: 'shop',
    component: () => import(/* webpackChunkName: "page.stations.shop" */ 'frontend/pages/Stations/Shop'),
  },
]

export default routes
