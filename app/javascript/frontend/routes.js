import { routes as StationsRoutes } from 'frontend/pages/Stations/routes'
import { routes as SettingsRoutes } from 'frontend/pages/Settings/routes'

export const routes = [
  {
    path: '/',
    name: 'home',
    component: () => import(/* webpackChunkName: "page.home" */ 'frontend/pages/Home'),
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-6.jpg'),
    },
  }, {
    path: '/impressum',
    name: 'impressum',
    component: () => import(/* webpackChunkName: "page.impressum" */ 'frontend/pages/Impressum'),
  }, {
    path: '/privacy-policy',
    name: 'privacy-policy',
    component: () => import(/* webpackChunkName: "page.privacyPolicy" */ 'frontend/pages/PrivacyPolicy'),
  }, {
    path: '/ships',
    name: 'models',
    component: () => import(/* webpackChunkName: "page.ships" */ 'frontend/pages/Models'),
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-8.jpg'),
    },
  }, {
    path: '/compare/ships',
    name: 'compare-models',
    component: () => import(/* webpackChunkName: "page.compare-ships" */ 'frontend/pages/Compare/Models'),
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-8.jpg'),
    },
  }, {
    path: '/ships/:slug',
    name: 'model',
    component: () => import(/* webpackChunkName: "page.ship" */ 'frontend/pages/Models/Show'),
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-8.jpg'),
    },
  }, {
    path: '/ships/:slug/images',
    name: 'model-images',
    component: () => import(/* webpackChunkName: "page.ship-images" */ 'frontend/pages/Models/Show/Images'),
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-8.jpg'),
    },
  }, {
    path: '/ships/:slug/videos',
    name: 'model-videos',
    component: () => import(/* webpackChunkName: "page.ship-videos" */ 'frontend/pages/Models/Show/Videos'),
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-8.jpg'),
    },
  }, {
    path: '/stats',
    name: 'stats',
    component: () => import(/* webpackChunkName: "page.stats" */ 'frontend/pages/Stats'),
  }, {
    path: '/images',
    name: 'images',
    component: () => import(/* webpackChunkName: "page.images" */ 'frontend/pages/Images'),
  }, {
    path: '/hangar',
    name: 'hangar',
    component: () => import(/* webpackChunkName: "page.hangar" */ 'frontend/pages/Hangar'),
    meta: {
      needsAuthentication: true,
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-5.jpg'),
    },
  }, {
    path: '/hangar/:user',
    name: 'hangar-public',
    component: () => import(/* webpackChunkName: "page.hangar-public" */ 'frontend/pages/Hangar/Public'),
  }, {
    path: '/fleets',
    name: 'fleets',
    component: () => import(/* webpackChunkName: "page.fleets" */ 'frontend/pages/Fleets'),
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-2.jpg'),
    },
  }, {
    path: '/fleets/:sid',
    name: 'fleet',
    component: () => import(/* webpackChunkName: "page.fleet" */ 'frontend/pages/Fleets/Show'),
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-2.jpg'),
    },
  }, {
    path: '/stations',
    name: 'stations',
    component: () => import(/* webpackChunkName: "page.stations" */ 'frontend/pages/Stations'),
    children: StationsRoutes,
  }, {
    path: '/cargo',
    name: 'cargo',
    component: () => import(/* webpackChunkName: "page.cargo" */ 'frontend/pages/Cargo'),
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-7.jpg'),
    },
  }, {
    path: '/commodities',
    name: 'commodities',
    component: () => import(/* webpackChunkName: "page.commodities" */ 'frontend/pages/Commodities'),
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-7.jpg'),
    },
  }, {
    path: '/commodities/:id',
    name: 'commoditiesSaved',
    component: () => import(/* webpackChunkName: "page.commodities" */ 'frontend/pages/Commodities'),
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-7.jpg'),
    },
  }, {
    path: '/roadmap',
    name: 'roadmap',
    component: () => import(/* webpackChunkName: "page.roadmap" */ 'frontend/pages/Roadmap'),
  }, {
    path: '/roadmap/changes',
    name: 'roadmap-changes',
    component: () => import(/* webpackChunkName: "page.roadmap" */ 'frontend/pages/Roadmap/Changes'),
  }, {
    path: '/settings',
    name: 'settings',
    component: () => import(/* webpackChunkName: "page.settings" */ 'frontend/pages/Settings'),
    meta: {
      needsAuthentication: true,
    },
    redirect: {
      name: 'settings-profile',
    },
    children: SettingsRoutes,
  }, {
    path: '/sign-up',
    name: 'signup',
    component: () => import(/* webpackChunkName: "page.signup" */ 'frontend/pages/Signup'),
  }, {
    path: '/login',
    name: 'login',
    component: () => import(/* webpackChunkName: "page.login" */ 'frontend/pages/Login'),
  }, {
    path: '/password/request',
    name: 'request-password',
    component: () => import(/* webpackChunkName: "page.request-password" */ 'frontend/pages/RequestPassword'),
  }, {
    path: '/password/update/:token',
    name: 'change-password',
    component: () => import(/* webpackChunkName: "page.change-password" */ 'frontend/pages/ChangePassword'),
  }, {
    path: '/confirm/:token',
    name: 'confirm',
    component: () => import(/* webpackChunkName: "page.confirm" */ 'frontend/pages/Confirm'),
  }, {
    path: '/404',
    name: '404',
    component: () => import(/* webpackChunkName: "page.404" */ 'frontend/pages/NotFound'),
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-404.jpg'),
    },
  }, {
    path: '*',
    component: () => import(/* webpackChunkName: "page.404" */ 'frontend/pages/NotFound'),
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-404.jpg'),
    },
  },
]

export default routes
