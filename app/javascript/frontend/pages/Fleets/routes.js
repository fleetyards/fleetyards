import { routes as SettingsRoutes } from 'frontend/pages/Fleets/Settings/routes'

export const routes = [
  {
    path: 'add/',
    name: 'fleet-add',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.fleets-add" */
        'frontend/pages/Fleets/Add'
      ),
    meta: {
      needsAuthentication: true,
      title: 'fleets.add',
      backgroundImage: 'bg-8',
    },
  },
  {
    path: 'preview/',
    name: 'fleet-preview',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.fleets-preview" */
        'frontend/pages/Fleets/Preview'
      ),
    meta: {
      title: 'fleets.preview',
      backgroundImage: 'bg-8',
    },
  },
  {
    path: 'invites/',
    name: 'fleet-invites',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.fleets-invites" */
        'frontend/pages/Fleets/Invites'
      ),
    meta: {
      needsAuthentication: true,
      title: 'fleets.invites',
      backgroundImage: 'bg-8',
    },
  },
  {
    path: 'invites/:token/',
    name: 'fleet-invite',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.fleets-invites" */
        'frontend/pages/Fleets/Invite'
      ),
    meta: {
      needsAuthentication: true,
      backgroundImage: 'bg-8',
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
    meta: {
      backgroundImage: 'bg-8',
    },
  },
  {
    path: ':slug/ships/',
    name: 'fleet-ships',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.ships" */
        'frontend/pages/Fleets/Ships'
      ),
    meta: {
      backgroundImage: 'bg-8',
    },
  },
  {
    path: ':slug/fleetchart/',
    name: 'fleet-fleetchart',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.fleets" */
        'frontend/pages/Fleets/Fleetchart'
      ),
    meta: {
      backgroundImage: 'bg-8',
    },
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
      backgroundImage: 'bg-8',
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
      backgroundImage: 'bg-8',
    },
    redirect: {
      name: 'fleet-settings-fleet',
    },
    children: SettingsRoutes,
  },
  {
    path: ':slug/stats/',
    name: 'fleet-stats',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.fleets" */
        'frontend/pages/Fleets/Stats'
      ),
    meta: {
      needsAuthentication: true,
      backgroundImage: 'bg-8',
    },
  },
]

export default routes
