export const routes = [
  {
    path: '/profile/',
    name: 'settings-profile',
    component: () => import(/* webpackChunkName: "frontend.page.settings" */ 'frontend/pages/Settings/Profile'),
    meta: {
      title: 'settings.index',
      needsAuthentication: true,
    },
  }, {
    path: '/verify/',
    name: 'settings-verify',
    component: () => import(/* webpackChunkName: "frontend.page.settings" */ 'frontend/pages/Settings/Verify'),
    meta: {
      title: 'verify',
      needsAuthentication: true,
    },
  }, {
    path: '/account/',
    name: 'settings-account',
    component: () => import(/* webpackChunkName: "frontend.page.settings" */ 'frontend/pages/Settings/Account'),
    meta: {
      title: 'settings.account',
      needsAuthentication: true,
    },
  }, {
    path: '/hangar/',
    name: 'settings-hangar',
    component: () => import(/* webpackChunkName: "frontend.page.settings" */ 'frontend/pages/Settings/Hangar'),
    meta: {
      title: 'settings.hangar',
      needsAuthentication: true,
    },
  }, {
    path: '/change-password/',
    name: 'settings-change-password',
    component: () => import(/* webpackChunkName: "frontend.page.settings" */ 'frontend/pages/Settings/ChangePassword'),
    meta: {
      title: 'changePassword',
      needsAuthentication: true,
    },
  },
]

export default routes
