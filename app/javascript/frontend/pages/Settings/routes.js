export const routes = [
  {
    path: 'profile',
    name: 'settings-profile',
    component: () => import(/* webpackChunkName: "frontend.page.settings.profile" */ 'frontend/pages/Settings/Profile'),
    meta: {
      needsAuthentication: true,
    },
  }, {
    path: 'verify',
    name: 'settings-verify',
    component: () => import(/* webpackChunkName: "frontend.page.settings.verify" */ 'frontend/pages/Settings/Verify'),
    meta: {
      needsAuthentication: true,
    },
  }, {
    path: 'account',
    name: 'settings-account',
    component: () => import(/* webpackChunkName: "frontend.page.settings.account" */ 'frontend/pages/Settings/Account'),
    meta: {
      needsAuthentication: true,
    },
  }, {
    path: 'change-password',
    name: 'settings-change-password',
    component: () => import(/* webpackChunkName: "frontend.page.settings.change-password" */ 'frontend/pages/Settings/ChangePassword'),
    meta: {
      needsAuthentication: true,
    },
  },
]

export default routes
