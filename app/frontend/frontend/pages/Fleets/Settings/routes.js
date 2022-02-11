export const routes = [
  {
    path: 'fleet/',
    name: 'fleet-settings-fleet',
    component: () => import('@/frontend/pages/Fleets/Settings/Fleet'),
    meta: {
      title: 'fleet.settings.fleet',
      needsAuthentication: true,
    },
  },
  {
    path: 'membership/',
    name: 'fleet-settings-membership',
    component: () => import('@/frontend/pages/Fleets/Settings/Membership'),
    meta: {
      title: 'fleet.settings.membership',
      needsAuthentication: true,
    },
  },
]

export default routes
