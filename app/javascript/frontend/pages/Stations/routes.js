import Starsystems from 'frontend/pages/Stations/Starsystems'
import Starsystem from 'frontend/pages/Stations/Starsystem'
import Planet from 'frontend/pages/Stations/Planet'
import Station from 'frontend/pages/Stations/Show'
import Shop from 'frontend/pages/Stations/Shop'

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
    path: '/planets/:slug',
    name: 'planet',
    component: Planet,
  }, {
    path: ':slug',
    name: 'station',
    component: Station,
  }, {
    path: ':station/:slug',
    name: 'shop',
    component: Shop,
  },
]

export default routes
