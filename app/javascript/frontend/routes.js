import { routes as StationsRoutes } from 'frontend/pages/Stations/routes'
import { routes as SettingsRoutes } from 'frontend/pages/Settings/routes'
import { routes as FleetsRoutes } from 'frontend/pages/Fleets/routes'
import { routes as RoadmapRoutes } from 'frontend/pages/Roadmap/routes'

export const routes = [
  {
    path: '/',
    name: 'home',
    component: () => import(/* webpackChunkName: "frontend.page.home" */ 'frontend/pages/Home'),
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-6.jpg'),
      title: 'home',
    },
  }, {
    path: '/search/',
    name: 'search',
    component: () => import(/* webpackChunkName: "frontend.page.home" */ 'frontend/pages/Search'),
    meta: {
      title: 'search',
    },
  }, {
    path: '/impressum/',
    name: 'impressum',
    component: () => import(/* webpackChunkName: "frontend.page.home" */ 'frontend/pages/Impressum'),
    meta: {
      title: 'impressum',
    },
  }, {
    path: '/privacy-policy/',
    name: 'privacy-policy',
    component: () => import(/* webpackChunkName: "frontend.page.home" */ 'frontend/pages/PrivacyPolicy'),
    meta: {
      title: 'privacyPolicy',
    },
  }, {
    path: '/cookie-policy/',
    name: 'cookie-policy',
    component: () => import(/* webpackChunkName: "frontend.page.home" */ 'frontend/pages/CookiePolicy'),
    meta: {
      title: 'cookiePolicy',
    },
  }, {
    path: '/hangar/',
    name: 'hangar',
    component: () => import(/* webpackChunkName: "frontend.page.hangar" */ 'frontend/pages/Hangar'),
    meta: {
      needsAuthentication: true,
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-5.jpg'),
      quickSearch: 'nameCont',
      title: 'hangar.index',
    },
  }, {
    path: '/hangar/preview',
    name: 'hangar-preview',
    component: () => import(/* webpackChunkName: "frontend.page.hangar" */ 'frontend/pages/Hangar/Preview'),
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-5.jpg'),
      title: 'hangar.preview',
    },
  }, {
    path: '/hangar/stats/',
    name: 'hangar-stats',
    component: () => import(/* webpackChunkName: "frontend.page.hangar" */ 'frontend/pages/Hangar/Stats'),
    meta: {
      needsAuthentication: true,
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-5.jpg'),
      title: 'hangar.stats',
    },
  }, {
    path: '/hangar/:user/',
    name: 'hangar-public',
    component: () => import(/* webpackChunkName: "frontend.page.hangar" */ 'frontend/pages/Hangar/Public'),
  }, {
    path: '/ships/',
    name: 'models',
    component: () => import(/* webpackChunkName: "frontend.page.ships" */ 'frontend/pages/Models'),
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-6.jpg'),
      title: 'models',
      quickSearch: 'searchCont',
    },
  }, {
    path: '/ships/compare/',
    name: 'models-compare',
    component: () => import(/* webpackChunkName: "frontend.page.ships" */ 'frontend/pages/Models/Compare'),
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-6.jpg'),
      title: 'compare.models',
    },
  }, {
    path: '/ships/:slug/',
    name: 'model',
    component: () => import(/* webpackChunkName: "frontend.page.ships" */ 'frontend/pages/Models/Show'),
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-6.jpg'),
    },
  }, {
    path: '/ships/:slug/images/',
    name: 'model-images',
    component: () => import(/* webpackChunkName: "frontend.page.ships" */ 'frontend/pages/Models/Show/Images'),
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-6.jpg'),
    },
  }, {
    path: '/ships/:slug/videos/',
    name: 'model-videos',
    component: () => import(/* webpackChunkName: "frontend.page.ships" */ 'frontend/pages/Models/Show/Videos'),
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-6.jpg'),
    },
  }, {
    path: '/stats/',
    name: 'stats',
    component: () => import(/* webpackChunkName: "frontend.page.stats" */ 'frontend/pages/Stats'),
    meta: {
      title: 'stats',
    },
  }, {
    path: '/fleets/',
    name: 'fleets',
    component: () => import(/* webpackChunkName: "frontend.page.fleets" */ 'frontend/pages/Fleets'),
    children: FleetsRoutes,
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-8.jpg'),
      title: 'fleets',
    },
  }, {
    path: '/images/',
    name: 'images',
    component: () => import(/* webpackChunkName: "frontend.page.images" */ 'frontend/pages/Images'),
    meta: {
      title: 'images',
    },
  }, {
    path: '/stations/',
    name: 'stations',
    component: () => import(/* webpackChunkName: "frontend.page.stations" */ 'frontend/pages/Stations'),
    children: StationsRoutes,
    meta: {
      title: 'stations',
      quickSearch: 'searchCont',
    },
  }, {
    path: '/trade-routes/',
    name: 'trade-routes',
    component: () => import(/* webpackChunkName: "frontend.page.stations" */ 'frontend/pages/TradeRoutes'),
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-7.jpg'),
      title: 'tradeRoutes',
    },
  }, {
    path: '/roadmap/',
    name: 'roadmap',
    children: RoadmapRoutes,
    component: () => import(/* webpackChunkName: "frontend.page.roadmap" */ 'frontend/pages/Roadmap'),
    meta: {
      title: 'roadmap.index',
    },
  }, {
    path: '/settings/',
    name: 'settings',
    component: () => import(/* webpackChunkName: "frontend.page.settings" */ 'frontend/pages/Settings'),
    meta: {
      needsAuthentication: true,
    },
    redirect: {
      name: 'settings-profile',
    },
    children: SettingsRoutes,
  }, {
    path: '/sign-up/',
    name: 'signup',
    component: () => import(/* webpackChunkName: "frontend.page.signup" */ 'frontend/pages/Signup'),
    meta: {
      title: 'signUp',
    },
  }, {
    path: '/login/',
    name: 'login',
    component: () => import(/* webpackChunkName: "frontend.page.login" */ 'frontend/pages/Login'),
    meta: {
      title: 'login',
    },
  }, {
    path: '/password/request/',
    name: 'request-password',
    component: () => import(/* webpackChunkName: "frontend.page.password" */ 'frontend/pages/RequestPassword'),
    meta: {
      title: 'requestPassword',
    },
  }, {
    path: '/password/update/:token/',
    name: 'change-password',
    component: () => import(/* webpackChunkName: "frontend.page.password" */ 'frontend/pages/ChangePassword'),
    meta: {
      title: 'changePassword',
    },
  }, {
    path: '/confirm/:token/',
    name: 'confirm',
    component: () => import(/* webpackChunkName: "frontend.page.signup" */ 'frontend/pages/Confirm'),
  }, {
    path: '/404/',
    name: '404',
    component: () => import(/* webpackChunkName: "frontend.page.404" */ 'frontend/pages/NotFound'),
    meta: {
      title: 'notFound',
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-404.jpg'),
    },
  }, {
    path: '*',
    component: () => import(/* webpackChunkName: "frontend.page.404" */ 'frontend/pages/NotFound'),
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-404.jpg'),
    },
  },
]

export default routes
