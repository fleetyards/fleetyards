export const routes = [
  {
    component: () => import('@/frontend/pages/Stations/Starsystems/index.vue'),
    meta: {
      backgroundImage: 'bg-0',
      title: 'starsystems',
    },
    name: 'starsystems',
    path: '/starsystems/',
  },
  {
    component: () => import('@/frontend/pages/Stations/Starsystem/index.vue'),
    meta: {
      backgroundImage: 'bg-0',
    },
    name: 'starsystem',
    path: '/starsystems/:slug/',
  },
  {
    component: () =>
      import('@/frontend/pages/Stations/CelestialObject/index.vue'),
    meta: {
      backgroundImage: 'bg-0',
    },
    name: 'celestial-object',
    path: '/starsystems/:starsystem/celestial-objects/:slug/',
  },
  {
    component: () => import('@/frontend/pages/Stations/ShopList/index.vue'),
    meta: {
      backgroundImage: 'bg-2',
      title: 'shops',
    },
    name: 'shops',
    path: '/shops/',
  },
  {
    component: () => import('@/frontend/pages/Stations/Show/index.vue'),
    meta: {
      backgroundImage: 'bg-0',
    },
    name: 'station',
    path: ':slug/',
  },
  {
    component: () => import('@/frontend/pages/Stations/Show/Images/index.vue'),
    meta: {
      backgroundImage: 'bg-0',
    },
    name: 'station-images',
    path: ':slug/images/',
  },
  {
    component: () => import('@/frontend/pages/Stations/Shop/index.vue'),
    meta: {
      backgroundImage: 'bg-2',
    },
    name: 'shop',
    path: ':stationSlug/shops/:slug/',
  },
]

export default routes
