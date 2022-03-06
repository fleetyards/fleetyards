export const routes = [
  {
    component: () => import('@/frontend/pages/Fleets/Settings/Fleet/index.vue'),
    meta: {
      needsAuthentication: true,
      title: 'fleet.settings.fleet',
    },
    name: 'fleet-settings-fleet',
    path: 'fleet/',
  },
  {
    component: () =>
      import('@/frontend/pages/Fleets/Settings/Membership/index.vue'),
    meta: {
      needsAuthentication: true,
      title: 'fleet.settings.membership',
    },
    name: 'fleet-settings-membership',
    path: 'membership/',
  },
]

export default routes
