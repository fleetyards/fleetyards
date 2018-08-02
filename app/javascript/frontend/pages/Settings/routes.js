import Profile from 'frontend/pages/Settings/Profile'
import Account from 'frontend/pages/Settings/Account'
import ChangePassword from 'frontend/pages/Settings/ChangePassword'

export const routes = [
  {
    path: 'profile',
    name: 'settings-profile',
    component: Profile,
    meta: {
      needsAuthentication: true,
    },
  }, {
    path: 'account',
    name: 'settings-account',
    component: Account,
    meta: {
      needsAuthentication: true,
    },
  }, {
    path: 'change-password',
    name: 'settings-change-password',
    component: ChangePassword,
    meta: {
      needsAuthentication: true,
    },
  },
]

export default routes
