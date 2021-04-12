export const routes = [
  {
    path: 'changes/',
    name: 'roadmap-changes',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.roadmap" */ 'frontend/pages/Roadmap/Changes'
      ),
    meta: {
      title: 'roadmap.changes',
    },
  },
  {
    path: 'ships/',
    name: 'roadmap-ships',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.roadmap.ships" */ 'frontend/pages/Roadmap/Ships'
      ),
    meta: {
      title: 'roadmap.ships',
    },
  },
  {
    path: 'progress-tracker/',
    name: 'roadmap-progress-tracker',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.roadmap.progress-tracker" */ 'frontend/pages/Roadmap/ProgressTracker'
      ),
    meta: {
      search: 'search',
      title: 'roadmap.progressTracker',
    },
  },
]

export default routes
