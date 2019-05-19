import Images from 'admin/pages/Images'

export const routes = [
  {
    path: '/models/:uuid/images',
    name: 'model-images',
    component: () => import(/* webpackChunkName: "page.admin.model-images" */ 'admin/pages/Models/Images'),
  }, {
    path: '/stations/:uuid/images',
    name: 'station-images',
    component: () => import(/* webpackChunkName: "page.admin.station-images" */ 'admin/pages/Stations/Images'),
  }, {
    path: '/images',
    name: 'images',
    component: Images,
  },
]

export default routes
