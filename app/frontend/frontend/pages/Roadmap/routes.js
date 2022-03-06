export const routes = [
  {
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.roadmap" */ '@/frontend/pages/Roadmap/Changes/index.vue'
      ),
    meta: {
      title: 'roadmap.changes',
    },
    name: 'roadmap-changes',
    path: 'changes/',
  },
  {
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.roadmap.ships" */ '@/frontend/pages/Roadmap/Ships/index.vue'
      ),
    meta: {
      title: 'roadmap.ships',
    },
    name: 'roadmap-ships',
    path: 'ships/',
  },
]

export default routes
