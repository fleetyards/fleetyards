export const routes = [
  {
    path: 'members',
    name: 'fleet-members',
    component: () => import(/* webpackChunkName: "page.fleet-members" */ 'frontend/pages/Fleets/Members'),
    meta: {
    // eslint-disable-next-line global-require
      backgroundImage: require('images/bg-2.jpg'),
      needsAuthentication: true,
    },
  },
]

export default routes
