import { routes as SettingsRoutes } from '@/frontend/pages/Fleets/Settings/routes'

export const routes = [
  {
    path: 'add/',
    name: 'fleet-add',
    component: () => import('@/frontend/pages/Fleets/Add/index.vue'),
    meta: {
      needsAuthentication: true,
      title: 'fleets.add',
      backgroundImage: 'bg-8',
    },
  },
  {
    path: 'preview/',
    name: 'fleet-preview',
    component: () => import('@/frontend/pages/Fleets/Preview/index.vue'),
    meta: {
      title: 'fleets.preview',
      backgroundImage: 'bg-8',
    },
  },
  {
    path: 'invites/',
    name: 'fleet-invites',
    component: () => import('@/frontend/pages/Fleets/Invites/index.vue'),
    meta: {
      needsAuthentication: true,
      title: 'fleets.invites',
      backgroundImage: 'bg-8',
    },
  },
  {
    path: 'invites/:token/',
    name: 'fleet-invite',
    component: () => import('@/frontend/pages/Fleets/Invite/index.vue'),
    meta: {
      needsAuthentication: true,
      backgroundImage: 'bg-8',
    },
  },
  {
    path: ':slug/',
    name: 'fleet',
    component: () => import('@/frontend/pages/Fleets/Show/index.vue'),
    meta: {
      backgroundImage: 'bg-8',
    },
  },
  {
    path: ':slug/ships/',
    name: 'fleet-ships',
    component: () => import('@/frontend/pages/Fleets/Ships/index.vue'),
    meta: {
      backgroundImage: 'bg-8',
    },
  },
  {
    path: ':slug/fleetchart/',
    name: 'fleet-fleetchart',
    redirect: {
      name: 'fleet-ships',
      query: { fleetchart: true },
    },
  },
  {
    path: ':slug/members/',
    name: 'fleet-members',
    component: () => import('@/frontend/pages/Fleets/Members/index.vue'),
    meta: {
      needsAuthentication: true,
      backgroundImage: 'bg-8',
    },
  },
  {
    path: ':slug/settings/',
    name: 'fleet-settings',
    component: () => import('@/frontend/pages/Fleets/Settings/index.vue'),
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
    component: () => import('@/frontend/pages/Fleets/Stats/index.vue'),
    meta: {
      needsAuthentication: true,
      backgroundImage: 'bg-8',
    },
  },
]

export default routes
