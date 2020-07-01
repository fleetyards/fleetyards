export const routes = [
  {
    path: '/models/:uuid/images',
    name: 'model-images',
    component: () =>
      import(
        /* webpackChunkName: "page.admin.model-images" */ 'admin/pages/Models/Images/index.vue'
      ),
  },
  {
    path: '/stations/:uuid/images',
    name: 'station-images',
    component: () =>
      import(
        /* webpackChunkName: "page.admin.station-images" */ 'admin/pages/Stations/Images/index.vue'
      ),
  },
  {
    path: '/images',
    name: 'images',
    component: () =>
      import(
        /* webpackChunkName: "page.admin.images" */ 'admin/pages/Images/index.vue'
      ),
  },
]

export default routes
