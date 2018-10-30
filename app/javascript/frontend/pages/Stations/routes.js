import Starsystems from 'frontend/pages/Stations/Starsystems'
import Starsystem from 'frontend/pages/Stations/Starsystem'
import CelestialObject from 'frontend/pages/Stations/CelestialObject'
import Station from 'frontend/pages/Stations/Show'
import Shop from 'frontend/pages/Stations/Shop'
import Shops from 'frontend/pages/Stations/ShopList'

export const routes = [
  {
    path: '/starsystems',
    name: 'starsystems',
    component: Starsystems,
  }, {
    path: '/starsystems/:slug',
    name: 'starsystem',
    component: Starsystem,
  }, {
    path: '/celestial-objects/:slug',
    name: 'celestialObject',
    component: CelestialObject,
  }, {
    path: '/shops',
    name: 'shops',
    component: Shops,
  }, {
    path: ':slug',
    name: 'station',
    component: Station,
  }, {
    path: ':station/shops/:slug',
    name: 'shop',
    component: Shop,
  },
]

export default routes
