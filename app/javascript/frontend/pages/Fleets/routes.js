export const routes = [
  {
    path: 'add/',
    name: 'fleet-add',
    component: () => import(/* webpackChunkName: "frontend.page.fleets" */ 'frontend/pages/Fleets/Add'),
  }, {
    path: ':slug/',
    name: 'fleet',
    component: () => import(/* webpackChunkName: "frontend.page.fleets" */ 'frontend/pages/Fleets/Show'),
  }, {
    path: ':slug/members/',
    name: 'fleet-members',
    component: () => import(/* webpackChunkName: "frontend.page.fleets" */ 'frontend/pages/Fleets/Members'),
  }, {
    path: ':slug/settings/',
    name: 'fleet-settings',
    component: () => import(/* webpackChunkName: "frontend.page.fleets" */ 'frontend/pages/Fleets/Settings'),
  },
]

export default routes
