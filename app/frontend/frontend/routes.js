import { routes as StationsRoutes } from '@/frontend/pages/Stations/routes'
import { routes as SettingsRoutes } from '@/frontend/pages/Settings/routes'
import { routes as FleetsRoutes } from '@/frontend/pages/Fleets/routes'
import { routes as RoadmapRoutes } from '@/frontend/pages/Roadmap/routes'
import { routes as ToolsRoutes } from '@/frontend/pages/Tools/routes'

export const routes = [
  {
    component: () => import('@/frontend/pages/Home/index.vue'),
    meta: {
      title: 'home',
    },
    name: 'home',
    path: '/',
  },
  {
    component: () => import('@/frontend/pages/Search/index.vue'),
    meta: {
      title: 'search',
    },
    name: 'search',
    path: '/search/',
  },
  {
    component: () => import('@/frontend/pages/Impressum/index.vue'),
    meta: {
      title: 'impressum',
    },
    name: 'impressum',
    path: '/impressum/',
  },
  {
    component: () => import('@/frontend/pages/PrivacyPolicy/index.vue'),
    meta: {
      title: 'privacyPolicy',
    },
    name: 'privacy-policy',
    path: '/privacy-policy/',
  },
  {
    component: () => import('@/frontend/pages/Hangar/index.vue'),
    meta: {
      backgroundImage: 'bg-5',
      needsAuthentication: true,
      primaryAction: true,
      quickSearch: 'nameCont',
      title: 'hangar.index',
    },
    name: 'hangar',
    path: '/hangar/',
  },
  {
    component: () => import('@/frontend/pages/Hangar/Preview/index.vue'),
    meta: {
      backgroundImage: 'bg-5',
      title: 'hangar.preview',
    },
    name: 'hangar-preview',
    path: '/hangar/preview',
  },
  {
    name: 'hangar-fleetchart',
    path: '/hangar/fleetchart/',
    redirect: {
      name: 'hangar',
      query: { fleetchart: true },
    },
  },
  {
    component: () => import('@/frontend/pages/Hangar/Stats/index.vue'),
    meta: {
      backgroundImage: 'bg-5',
      needsAuthentication: true,
      title: 'hangar.stats',
    },
    name: 'hangar-stats',
    path: '/hangar/stats/',
  },
  {
    component: () => import('@/frontend/pages/Hangar/Public/index.vue'),
    meta: {
      backgroundImage: 'bg-5',
    },
    name: 'hangar-public',
    path: '/hangar/:username/',
  },
  {
    name: 'hangar-public-fleetchart',
    path: '/hangar/:username/fleetchart',
    redirect: {
      name: 'hangar-public',
      query: { fleetchart: true },
    },
  },
  {
    component: () => import('@/frontend/pages/Models/index.vue'),
    meta: {
      quickSearch: 'searchCont',
      title: 'models.index',
    },
    name: 'models',
    path: '/ships/',
  },
  {
    name: 'models-fleetchart',
    path: '/ships/fleetchart',
    redirect: {
      name: 'models',
      query: { fleetchart: true },
    },
  },
  {
    component: () => import('@/frontend/pages/Models/Compare/index.vue'),
    meta: {
      title: 'compare.models',
    },
    name: 'models-compare',
    path: '/ships/compare/',
  },
  {
    component: () => import('@/frontend/pages/Models/Show/index.vue'),
    name: 'model',
    path: '/ships/:slug/',
  },
  {
    component: () => import('@/frontend/pages/Models/Show/Images/index.vue'),
    name: 'model-images',
    path: '/ships/:slug/images/',
  },
  {
    component: () => import('@/frontend/pages/Models/Show/Videos/index.vue'),
    name: 'model-videos',
    path: '/ships/:slug/videos/',
  },
  {
    component: () => import('@/frontend/pages/Stats/index.vue'),
    meta: {
      title: 'stats',
    },
    name: 'stats',
    path: '/stats/',
  },
  {
    children: FleetsRoutes,
    component: () => import('@/frontend/pages/Fleets/index.vue'),
    meta: {
      backgroundImage: 'bg-8',
      title: 'fleets',
    },
    name: 'fleets',
    path: '/fleets/',
    redirect: { name: FleetsRoutes[0].name },
  },
  {
    component: () => import('@/frontend/pages/Images/index.vue'),
    meta: {
      title: 'images',
    },
    name: 'images',
    path: '/images/',
  },
  {
    children: StationsRoutes,
    component: () => import('@/frontend/pages/Stations/index.vue'),
    meta: {
      backgroundImage: 'bg-0',
      quickSearch: 'searchCont',
      title: 'stations',
    },
    name: 'stations',
    path: '/stations/',
  },
  {
    children: ToolsRoutes,
    component: () => import('@/frontend/pages/Tools/index.vue'),
    meta: {
      backgroundImage: 'bg-7',
      title: 'tools',
    },
    name: 'tools',
    path: '/tools/',
    redirect: { name: ToolsRoutes[0].name },
  },
  {
    children: RoadmapRoutes,
    component: () => import('@/frontend/pages/Roadmap/index.vue'),
    meta: {
      title: 'roadmap.index',
    },
    name: 'roadmap',
    path: '/roadmap/',
  },
  {
    children: SettingsRoutes,
    component: () => import('@/frontend/pages/Settings/index.vue'),
    meta: {
      needsAuthentication: true,
    },
    name: 'settings',
    path: '/settings/',
    redirect: {
      name: 'settings-profile',
    },
  },
  {
    component: () => import('@/frontend/pages/Signup/index.vue'),
    meta: {
      title: 'signUp',
    },
    name: 'signup',
    path: '/sign-up/',
  },
  {
    component: () => import('@/frontend/pages/Login/index.vue'),
    meta: {
      title: 'login',
    },
    name: 'login',
    path: '/login/',
  },
  {
    component: () => import('@/frontend/pages/RequestPassword/index.vue'),
    meta: {
      title: 'requestPassword',
    },
    name: 'request-password',
    path: '/password/request/',
  },
  {
    component: () => import('@/frontend/pages/ChangePassword/index.vue'),
    meta: {
      title: 'changePassword',
    },
    name: 'change-password',
    path: '/password/update/:token/',
  },
  {
    component: () => import('@/frontend/pages/Confirm/index.vue'),
    name: 'confirm',
    path: '/confirm/:token/',
  },
  {
    component: () => import('@/frontend/pages/NotFound/index.vue'),
    meta: {
      backgroundImage: 'bg-404',
      title: 'notFound',
    },
    name: '404',
    path: '/404/',
  },
  {
    component: () => import('@/frontend/pages/NotFound/index.vue'),
    meta: {
      backgroundImage: 'bg-404',
      title: 'notFound',
    },
    path: '*',
  },
]

export default routes
