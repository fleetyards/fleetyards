export const routes = [
  {
    path: '/starsystems/',
    name: 'starsystems',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.stations" */ 'frontend/pages/Stations/Starsystems'
      ),
    meta: {
      title: 'starsystems',
      backgroundImage: 'bg-0',
    },
  },
  {
    path: '/starsystems/:slug/',
    name: 'starsystem',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.stations" */ 'frontend/pages/Stations/Starsystem'
      ),
    meta: {
      backgroundImage: 'bg-0',
    },
  },
  {
    path: '/starsystems/:starsystem/celestial-objects/:slug/',
    name: 'celestial-object',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.stations" */ 'frontend/pages/Stations/CelestialObject'
      ),
    meta: {
      backgroundImage: 'bg-0',
    },
  },
  {
    path: '/shops/',
    name: 'shops',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.stations" */ 'frontend/pages/Stations/ShopList'
      ),
    meta: {
      title: 'shops',
      backgroundImage: 'bg-2',
    },
  },
  {
    path: ':slug/',
    name: 'station',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.stations" */ 'frontend/pages/Stations/Show'
      ),
    meta: {
      backgroundImage: 'bg-0',
    },
  },
  {
    path: ':slug/images/',
    name: 'station-images',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.stations" */ 'frontend/pages/Stations/Show/Images'
      ),
    meta: {
      backgroundImage: 'bg-0',
    },
  },
  {
    path: ':stationSlug/shops/:slug/',
    name: 'shop',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.stations" */ 'frontend/pages/Stations/Shop'
      ),
    meta: {
      backgroundImage: 'bg-2',
    },
  },
]

export default routes
