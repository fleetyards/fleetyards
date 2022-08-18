export const routes = [
  {
    path: 'fleet/',
    name: 'fleet-settings-fleet',
    component: () => import('@/frontend/pages/Fleets/Settings/Fleet/index.vue'),
    meta: {
      title: 'fleet.settings.fleet',
      needsAuthentication: true,
    },
  },
  {
    path: 'membership/',
    name: 'fleet-settings-membership',
    component: () =>
      import('@/frontend/pages/Fleets/Settings/Membership/index.vue'),
    meta: {
      title: 'fleet.settings.membership',
      needsAuthentication: true,
    },
  },
]

export default routes
