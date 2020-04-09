import { routes as SettingsRoutes } from 'frontend/pages/Fleets/Settings/routes'

export const routes = [
  {
    path: 'add/',
    name: 'fleet-add',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.fleets" */
        'frontend/pages/Fleets/Add'
      ),
    meta: {
      needsAuthentication: true,
      title: 'fleets.add',
    },
  },
  {
    path: 'preview/',
    name: 'fleet-preview',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.fleets" */
        'frontend/pages/Fleets/Preview'
      ),
    meta: {
      title: 'fleets.preview',
    },
  },
  {
    path: 'invites/',
    name: 'fleet-invites',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.fleets" */
        'frontend/pages/Fleets/Invites'
      ),
    meta: {
      needsAuthentication: true,
      title: 'fleets.invites',
    },
  },
  {
    path: ':slug/',
    name: 'fleet',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.fleets" */
        'frontend/pages/Fleets/Show'
      ),
  },
  {
    path: ':slug/members/',
    name: 'fleet-members',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.fleets" */
        'frontend/pages/Fleets/Members'
      ),
    meta: {
      needsAuthentication: true,
    },
  },
  {
    path: ':slug/settings/',
    name: 'fleet-settings',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.fleets" */
        'frontend/pages/Fleets/Settings'
      ),
    meta: {
      needsAuthentication: true,
    },
    redirect: {
      name: 'fleet-settings-fleet',
    },
    children: SettingsRoutes,
  },
]

export default routes
