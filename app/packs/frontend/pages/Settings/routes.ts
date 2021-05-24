import SecurityRoutes from './Security/routes'

export const routes = [
  {
    path: 'profile/',
    name: 'settings-profile',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.settings" */ 'frontend/pages/Settings/Profile/index.vue'
      ),
    meta: {
      title: 'settings.index',
      needsAuthentication: true,
    },
  },
  {
    path: 'account/',
    name: 'settings-account',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.settings" */ 'frontend/pages/Settings/Account/index.vue'
      ),
    meta: {
      title: 'settings.account',
      needsAuthentication: true,
    },
  },
  {
    path: 'notifications/',
    name: 'settings-notifications',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.settings" */ 'frontend/pages/Settings/Notifications/index.vue'
      ),
    meta: {
      title: 'settings.notifications',
      needsAuthentication: true,
    },
  },
  {
    path: 'hangar/',
    name: 'settings-hangar',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.settings" */ 'frontend/pages/Settings/Hangar/index.vue'
      ),
    meta: {
      title: 'settings.hangar',
      needsAuthentication: true,
    },
  },
  {
    path: 'security/',
    name: 'settings-security',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.settings.security" */ 'frontend/pages/Settings/Security/index.vue'
      ),
    meta: {
      needsAuthentication: true,
    },
    redirect: {
      name: 'settings-security-status',
    },
    children: SecurityRoutes,
  },
]

export default routes
