import { routes as SettingsRoutes } from 'frontend/pages/Fleets/Settings/routes'

export const routes = [
  {
    path: 'add/',
    name: 'fleet-add',
    component: () => import(/* webpackChunkName: "frontend.page.fleets" */ 'frontend/pages/Fleets/Add'),
    meta: {
      needsAuthentication: true,
      title: 'fleets.add',
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-8.jpg'),
    },
  }, {
    path: 'preview/',
    name: 'fleet-preview',
    component: () => import(/* webpackChunkName: "frontend.page.fleets" */ 'frontend/pages/Fleets/Preview'),
    meta: {
      title: 'fleets.preview',
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-8.jpg'),
    },
  }, {
    path: 'invites/',
    name: 'fleet-invites',
    component: () => import(/* webpackChunkName: "frontend.page.fleets" */ 'frontend/pages/Fleets/Invites'),
    meta: {
      needsAuthentication: true,
      title: 'fleets.invites',
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-8.jpg'),
    },
  }, {
    path: ':slug/',
    name: 'fleet',
    component: () => import(/* webpackChunkName: "frontend.page.fleets" */ 'frontend/pages/Fleets/Show'),
    meta: {
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-8.jpg'),
    },
  }, {
    path: ':slug/members/',
    name: 'fleet-members',
    component: () => import(/* webpackChunkName: "frontend.page.fleets" */ 'frontend/pages/Fleets/Members'),
    meta: {
      needsAuthentication: true,
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-2.jpg'),
    },
  }, {
    path: ':slug/settings/',
    name: 'fleet-settings',
    component: () => import(/* webpackChunkName: "frontend.page.fleets" */ 'frontend/pages/Fleets/Settings'),
    meta: {
      needsAuthentication: true,
      // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-8.jpg'),
    },
    redirect: {
      name: 'fleet-settings-fleet',
    },
    children: SettingsRoutes,
  },
]

export default routes
