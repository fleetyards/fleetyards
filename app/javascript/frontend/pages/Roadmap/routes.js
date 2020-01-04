export const routes = [
  {
    path: 'changes/',
    name: 'roadmap-changes',
    component: () => import(/* webpackChunkName: "frontend.page.roadmap" */ 'frontend/pages/Roadmap/Changes'),
    meta: {
      title: 'roadmap.changes',
    },
  }, {
    path: 'ships/',
    name: 'roadmap-ships',
    component: () => import(/* webpackChunkName: "frontend.page.roadmap" */ 'frontend/pages/Roadmap/Ships'),
    meta: {
      title: 'roadmap.ships',
    },
  },
]

export default routes
