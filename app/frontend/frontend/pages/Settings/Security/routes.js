export const routes = [
  {
    component: () =>
      import('@/frontend/pages/Settings/Security/Status/index.vue'),
    meta: {
      needsAuthentication: true,
      title: 'settings.security',
    },
    name: 'settings-security-status',
    path: '/',
  },
  {
    component: () =>
      import('@/frontend/pages/Settings/Security/TwoFactorEnable/index.vue'),
    meta: {
      needsAuthentication: true,
      title: 'settings.twoFactor.enable',
    },
    name: 'settings-two-factor-enable',
    path: 'two-factor/enable/',
  },
  {
    component: () =>
      import('@/frontend/pages/Settings/Security/TwoFactorDisable/index.vue'),
    meta: {
      needsAuthentication: true,
      title: 'settings.twoFactor.disable',
    },
    name: 'settings-two-factor-disable',
    path: 'two-factor/disable/',
  },
  {
    component: () =>
      import(
        '@/frontend/pages/Settings/Security/TwoFactorBackupCodes/index.vue'
      ),
    meta: {
      needsAuthentication: true,
      title: 'settings.twoFactor.backupCodes',
    },
    name: 'settings-two-factor-backup-codes',
    path: 'two-factor/backup-codes/',
  },
]

export default routes
