export const routes = [
  {
    path: 'profile',
    name: 'settings-profile',
    component: () => import(/* webpackChunkName: "frontend.page.settings.profile" */ 'frontend/pages/Settings/Profile'),
    meta: {
      title: 'settings',
      needsAuthentication: true,
    },
  }, {
    path: 'verify',
    name: 'settings-verify',
    component: () => import(/* webpackChunkName: "frontend.page.settings.verify" */ 'frontend/pages/Settings/Verify'),
    meta: {
      title: 'verify',
      needsAuthentication: true,
    },
  }, {
    path: 'account',
    name: 'settings-account',
    component: () => import(/* webpackChunkName: "frontend.page.settings.account" */ 'frontend/pages/Settings/Account'),
    meta: {
      title: 'account',
      needsAuthentication: true,
    },
  }, {
    path: 'change-password',
    name: 'settings-change-password',
    component: () => import(/* webpackChunkName: "frontend.page.settings.change-password" */ 'frontend/pages/Settings/ChangePassword'),
    meta: {
      title: 'changePassword',
      needsAuthentication: true,
    },
  },
]

export default routes
