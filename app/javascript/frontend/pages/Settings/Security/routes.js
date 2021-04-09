export const routes = [
  {
    path: '/',
    name: 'settings-security-status',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.settings.security" */ 'frontend/pages/Settings/Security/Status'
      ),
    meta: {
      title: 'settings.security',
      needsAuthentication: true,
    },
  },
  {
    path: 'two-factor/enable/',
    name: 'settings-two-factor-enable',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.settings.security" */ 'frontend/pages/Settings/Security/TwoFactorEnable'
      ),
    meta: {
      title: 'settings.twoFactor.enable',
      needsAuthentication: true,
    },
  },
  {
    path: 'two-factor/disable/',
    name: 'settings-two-factor-disable',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.settings.security" */ 'frontend/pages/Settings/Security/TwoFactorDisable'
      ),
    meta: {
      title: 'settings.twoFactor.disable',
      needsAuthentication: true,
    },
  },
  {
    path: 'two-factor/backup-codes/',
    name: 'settings-two-factor-backup-codes',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.settings.security" */ 'frontend/pages/Settings/Security/TwoFactorBackupCodes'
      ),
    meta: {
      title: 'settings.twoFactor.backupCodes',
      needsAuthentication: true,
    },
  },
]

export default routes
