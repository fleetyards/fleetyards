import SecurityRoutes from './Security/routes'

export const routes = [
  {
    component: () => import('@/frontend/pages/Settings/Profile/index.vue'),
    meta: {
      needsAuthentication: true,
      title: 'settings.index',
    },
    name: 'settings-profile',
    path: 'profile/',
  },
  {
    component: () => import('@/frontend/pages/Settings/Account/index.vue'),
    meta: {
      needsAuthentication: true,
      title: 'settings.account',
    },
    name: 'settings-account',
    path: 'account/',
  },
  {
    component: () =>
      import('@/frontend/pages/Settings/Notifications/index.vue'),
    meta: {
      needsAuthentication: true,
      title: 'settings.notifications',
    },
    name: 'settings-notifications',
    path: 'notifications/',
  },
  {
    component: () => import('@/frontend/pages/Settings/Hangar/index.vue'),
    meta: {
      needsAuthentication: true,
      title: 'settings.hangar',
    },
    name: 'settings-hangar',
    path: 'hangar/',
  },
  {
    children: SecurityRoutes,
    component: () => import('@/frontend/pages/Settings/Security/index.vue'),
    meta: {
      needsAuthentication: true,
    },
    name: 'settings-security',
    path: 'security/',
    redirect: {
      name: 'settings-security-status',
    },
  },
]

export default routes
