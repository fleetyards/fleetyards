import { routes as SettingsRoutes } from '@/frontend/pages/Fleets/Settings/routes'

export const routes = [
  {
    component: () => import('@/frontend/pages/Fleets/Add/index.vue'),
    meta: {
      backgroundImage: 'bg-8',
      needsAuthentication: true,
      title: 'fleets.add',
    },
    name: 'fleet-add',
    path: 'add/',
  },
  {
    component: () => import('@/frontend/pages/Fleets/Preview/index.vue'),
    meta: {
      backgroundImage: 'bg-8',
      title: 'fleets.preview',
    },
    name: 'fleet-preview',
    path: 'preview/',
  },
  {
    component: () => import('@/frontend/pages/Fleets/Invites/index.vue'),
    meta: {
      backgroundImage: 'bg-8',
      needsAuthentication: true,
      title: 'fleets.invites',
    },
    name: 'fleet-invites',
    path: 'invites/',
  },
  {
    component: () => import('@/frontend/pages/Fleets/Invite/index.vue'),
    meta: {
      backgroundImage: 'bg-8',
      needsAuthentication: true,
    },
    name: 'fleet-invite',
    path: 'invites/:token/',
  },
  {
    component: () => import('@/frontend/pages/Fleets/Show/index.vue'),
    meta: {
      backgroundImage: 'bg-8',
    },
    name: 'fleet',
    path: ':slug/',
  },
  {
    component: () => import('@/frontend/pages/Fleets/Ships/index.vue'),
    meta: {
      backgroundImage: 'bg-8',
    },
    name: 'fleet-ships',
    path: ':slug/ships/',
  },
  {
    name: 'fleet-fleetchart',
    path: ':slug/fleetchart/',
    redirect: {
      name: 'fleet-ships',
      query: { fleetchart: true },
    },
  },
  {
    component: () => import('@/frontend/pages/Fleets/Members/index.vue'),
    meta: {
      backgroundImage: 'bg-8',
      needsAuthentication: true,
    },
    name: 'fleet-members',
    path: ':slug/members/',
  },
  {
    children: SettingsRoutes,
    component: () => import('@/frontend/pages/Fleets/Settings/index.vue'),
    meta: {
      backgroundImage: 'bg-8',
      needsAuthentication: true,
    },
    name: 'fleet-settings',
    path: ':slug/settings/',
    redirect: {
      name: 'fleet-settings-fleet',
    },
  },
  {
    component: () => import('@/frontend/pages/Fleets/Stats/index.vue'),
    meta: {
      backgroundImage: 'bg-8',
      needsAuthentication: true,
    },
    name: 'fleet-stats',
    path: ':slug/stats/',
  },
]

export default routes
