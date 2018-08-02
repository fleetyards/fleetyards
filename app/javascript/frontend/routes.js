import Home from 'frontend/pages/Home'
import Impressum from 'frontend/pages/Impressum'
import PrivacyPolicy from 'frontend/pages/PrivacyPolicy'
import Models from 'frontend/pages/Models'
import Model from 'frontend/pages/Models/Show'
import CompareModels from 'frontend/pages/Compare/Models'
import NotFound from 'frontend/pages/NotFound'
import Images from 'frontend/pages/Images'
import Hangar from 'frontend/pages/Hangar'
import PublicHangar from 'frontend/pages/Hangar/Public'
import Fleets from 'frontend/pages/Fleets'
import Fleet from 'frontend/pages/Fleets/Show'
import Cargo from 'frontend/pages/Cargo'
import Commodities from 'frontend/pages/Commodities'
import Login from 'frontend/pages/Login'
import RequestPassword from 'frontend/pages/RequestPassword'
import ChangePassword from 'frontend/pages/ChangePassword'
import Signup from 'frontend/pages/Signup'
import Confirm from 'frontend/pages/Confirm'
import Settings from 'frontend/pages/Settings'
import { routes as SettingsRoutes } from 'frontend/pages/Settings/routes'

export const routes = [
  {
    path: '/',
    name: 'home',
    component: Home,
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-0.jpg'),
    },
  }, {
    path: '/impressum',
    name: 'impressum',
    component: Impressum,
  }, {
    path: '/privacy-policy',
    name: 'privacy-policy',
    component: PrivacyPolicy,
  }, {
    path: '/ships',
    name: 'models',
    component: Models,
  }, {
    path: '/compare/ships',
    name: 'compare-models',
    component: CompareModels,
  }, {
    path: '/ships/:slug',
    name: 'model',
    component: Model,
  }, {
    path: '/images',
    name: 'images',
    component: Images,
  }, {
    path: '/hangar',
    name: 'hangar',
    component: Hangar,
    meta: {
      needsAuthentication: true,
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-5.jpg'),
    },
  }, {
    path: '/hangar/:user',
    name: 'hangar-public',
    component: PublicHangar,
    meta: {
      hideNavigation: true,
    },
  }, {
    path: '/fleets',
    name: 'fleets',
    component: Fleets,
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-2.jpg'),
    },
  }, {
    path: '/fleets/:sid',
    name: 'fleet',
    component: Fleet,
    meta: {
      hideNavigation: true,
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-2.jpg'),
    },
  }, {
    path: '/cargo',
    name: 'cargo',
    component: Cargo,
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-5.jpg'),
    },
  }, {
    path: '/commodities',
    name: 'commodities',
    component: Commodities,
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-5.jpg'),
    },
  }, {
    path: '/commodities/:id',
    name: 'commoditiesSaved',
    component: Commodities,
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-5.jpg'),
    },
  }, {
    path: '/settings',
    name: 'settings',
    component: Settings,
    meta: {
      needsAuthentication: true,
    },
    redirect: {
      name: 'settings-profile',
    },
    children: SettingsRoutes,
  }, {
    path: '/password/update',
    name: 'change-user-password',
    component: ChangePassword,
    meta: {
      needsAuthentication: true,
    },
  }, {
    path: '/sign-up',
    name: 'signup',
    component: Signup,
    meta: {
      hideNavigation: true,
    },
  }, {
    path: '/login',
    name: 'login',
    component: Login,
    meta: {
      hideNavigation: true,
    },
  }, {
    path: '/password/request',
    name: 'request-password',
    component: RequestPassword,
    meta: {
      hideNavigation: true,
    },
  }, {
    path: '/password/update/:token',
    name: 'change-password',
    component: ChangePassword,
    meta: {
      hideNavigation: true,
    },
  }, {
    path: '/confirm/:token',
    name: 'confirm',
    component: Confirm,
  }, {
    path: '/404',
    name: '404',
    component: NotFound,
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-404.jpg'),
    },
  }, {
    path: '*',
    component: NotFound,
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-404.jpg'),
    },
  },
]

export default routes
