import { routes as StationsRoutes } from 'frontend/pages/Stations/routes'
import { routes as SettingsRoutes } from 'frontend/pages/Settings/routes'
import { routes as FleetsRoutes } from 'frontend/pages/Fleets/routes'
import { routes as RoadmapRoutes } from 'frontend/pages/Roadmap/routes'
import { routes as ToolsRoutes } from 'frontend/pages/Tools/routes'

export const routes = [
  {
    path: '/',
    name: 'home',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.home" */ 'frontend/pages/Home/index.vue'
      ),
    meta: {
      title: 'home',
    },
  },
  {
    path: '/search/',
    name: 'search',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.search" */ 'frontend/pages/Search/index.vue'
      ),
    meta: {
      title: 'search',
    },
  },
  {
    path: '/impressum/',
    name: 'impressum',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.impressum" */ 'frontend/pages/Impressum/index.vue'
      ),
    meta: {
      title: 'impressum',
    },
  },
  {
    path: '/privacy-policy/',
    name: 'privacy-policy',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.privacy" */ 'frontend/pages/PrivacyPolicy/index.vue'
      ),
    meta: {
      title: 'privacyPolicy',
    },
  },
  {
    path: '/hangar/',
    name: 'hangar',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.hangar" */ 'frontend/pages/Hangar/index.vue'
      ),
    meta: {
      needsAuthentication: true,
      quickSearch: 'nameCont',
      title: 'hangar.index',
      primaryAction: true,
      backgroundImage: 'bg-5',
    },
  },
  {
    path: '/hangar/preview',
    name: 'hangar-preview',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.hangar-preview" */ 'frontend/pages/Hangar/Preview/index.vue'
      ),
    meta: {
      title: 'hangar.preview',
      backgroundImage: 'bg-5',
    },
  },
  {
    path: '/hangar/fleetchart/',
    name: 'hangar-fleetchart',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.hangar-fleetchart" */ 'frontend/pages/Hangar/Fleetchart/index.vue'
      ),
    meta: {
      needsAuthentication: true,
      quickSearch: 'nameCont',
      title: 'hangar.fleetchart',
      primaryAction: true,
      backgroundImage: 'bg-5',
    },
  },
  {
    path: '/hangar/stats/',
    name: 'hangar-stats',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.hangar-stats" */ 'frontend/pages/Hangar/Stats/index.vue'
      ),
    meta: {
      needsAuthentication: true,
      title: 'hangar.stats',
      backgroundImage: 'bg-5',
    },
  },
  {
    path: '/hangar/:username/',
    name: 'hangar-public',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.hangar-public" */ 'frontend/pages/Hangar/Public/index.vue'
      ),
    meta: {
      backgroundImage: 'bg-5',
    },
  },
  {
    path: '/hangar/:username/fleetchart',
    name: 'hangar-public-fleetchart',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.hangar-public-fleetchart" */ 'frontend/pages/Hangar/PublicFleetchart/index.vue'
      ),
    meta: {
      backgroundImage: 'bg-5',
    },
  },
  {
    path: '/ships/',
    name: 'models',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.ships" */ 'frontend/pages/Models/index.vue'
      ),
    meta: {
      title: 'models.index',
      quickSearch: 'searchCont',
    },
  },
  {
    path: '/ships/fleetchart',
    name: 'models-fleetchart',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.ships-fleetchart" */ 'frontend/pages/Models/Fleetchart/index.vue'
      ),
    meta: {
      title: 'models.fleetchart',
      quickSearch: 'searchCont',
    },
  },
  {
    path: '/ships/compare/',
    name: 'models-compare',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.ships-compare" */ 'frontend/pages/Models/Compare/index.vue'
      ),
    meta: {
      title: 'compare.models',
    },
  },
  {
    path: '/ships/:slug/',
    name: 'model',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.ships-detail" */ 'frontend/pages/Models/Show/index.vue'
      ),
  },
  {
    path: '/ships/:slug/images/',
    name: 'model-images',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.ships-images" */ 'frontend/pages/Models/Show/Images/index.vue'
      ),
  },
  {
    path: '/ships/:slug/videos/',
    name: 'model-videos',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.ships-videos" */ 'frontend/pages/Models/Show/Videos/index.vue'
      ),
  },
  {
    path: '/stats/',
    name: 'stats',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.stats" */ 'frontend/pages/Stats/index.vue'
      ),
    meta: {
      title: 'stats',
    },
  },
  {
    path: '/fleets/',
    name: 'fleets',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.fleets" */ 'frontend/pages/Fleets/index.vue'
      ),
    children: FleetsRoutes,
    redirect: { name: FleetsRoutes[0].name },
    meta: {
      title: 'fleets',
      backgroundImage: 'bg-8',
    },
  },
  {
    path: '/images/',
    name: 'images',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.images" */ 'frontend/pages/Images/index.vue'
      ),
    meta: {
      title: 'images',
    },
  },
  {
    path: '/stations/',
    name: 'stations',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.stations" */ 'frontend/pages/Stations/index.vue'
      ),
    children: StationsRoutes,
    meta: {
      title: 'stations',
      quickSearch: 'searchCont',
      backgroundImage: 'bg-0',
    },
  },
  {
    path: '/tools/',
    name: 'tools',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.tools" */ 'frontend/pages/Tools/index.vue'
      ),
    children: ToolsRoutes,
    redirect: { name: ToolsRoutes[0].name },
    meta: {
      title: 'tools',
      backgroundImage: 'bg-7',
    },
  },
  {
    path: '/roadmap/',
    name: 'roadmap',
    children: RoadmapRoutes,
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.roadmap" */ 'frontend/pages/Roadmap/index.vue'
      ),
    meta: {
      title: 'roadmap.index',
    },
  },
  {
    path: '/settings/',
    name: 'settings',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.settings" */ 'frontend/pages/Settings/index.vue'
      ),
    meta: {
      needsAuthentication: true,
    },
    redirect: {
      name: 'settings-profile',
    },
    children: SettingsRoutes,
  },
  {
    path: '/sign-up/',
    name: 'signup',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.signup" */ 'frontend/pages/Signup/index.vue'
      ),
    meta: {
      title: 'signUp',
    },
  },
  {
    path: '/login/',
    name: 'login',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.login" */ 'frontend/pages/Login/index.vue'
      ),
    meta: {
      title: 'login',
    },
  },
  {
    path: '/password/request/',
    name: 'request-password',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.password" */ 'frontend/pages/RequestPassword/index.vue'
      ),
    meta: {
      title: 'requestPassword',
    },
  },
  {
    path: '/password/update/:token/',
    name: 'change-password',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.password" */ 'frontend/pages/ChangePassword/index.vue'
      ),
    meta: {
      title: 'changePassword',
    },
  },
  {
    path: '/confirm/:token/',
    name: 'confirm',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.signup" */ 'frontend/pages/Confirm/index.vue'
      ),
  },
  {
    path: '/404/',
    name: '404',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.404" */ 'frontend/pages/NotFound/index.vue'
      ),
    meta: {
      title: 'notFound',
      backgroundImage: 'bg-404',
    },
  },
  {
    path: '*',
    component: () =>
      import(
        /* webpackChunkName: "frontend.page.404" */ 'frontend/pages/NotFound/index.vue'
      ),
    meta: {
      title: 'notFound',
      backgroundImage: 'bg-404',
    },
  },
]

export default routes
