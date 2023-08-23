import type { RouteRecordRaw } from "vue-router";
import { routes as StationsRoutes } from "@/frontend/pages/Stations/routes";
import { routes as RoadmapRoutes } from "@/frontend/pages/Roadmap/routes";
import { routes as SettingsRoutes } from "@/frontend/pages/Settings/routes";
import { routes as FleetsRoutes } from "@/frontend/pages/Fleets/routes";
import { routes as ToolsRoutes } from "@/frontend/pages/Tools/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "/",
    name: "home",
    component: () => import("@/frontend/pages/Home/index.vue"),
    meta: {
      title: "home",
    },
  },
  {
    path: "/search/",
    name: "search",
    component: () => import("@/frontend/pages/Search/index.vue"),
    meta: {
      title: "search",
    },
  },
  {
    path: "/impressum/",
    name: "impressum",
    component: () => import("@/frontend/pages/Impressum/index.vue"),
    meta: {
      title: "impressum",
    },
  },
  {
    path: "/privacy-policy/",
    name: "privacy-policy",
    component: () => import("@/frontend/pages/PrivacyPolicy/index.vue"),
    meta: {
      title: "privacyPolicy",
    },
  },
  {
    path: "/hangar/",
    name: "hangar",
    component: () => import("@/frontend/pages/Hangar/index.vue"),
    meta: {
      needsAuthentication: true,
      quickSearch: "searchCont",
      title: "hangar.index",
      primaryAction: true,
      backgroundImage: "bg-5",
    },
  },
  {
    path: "/hangar/wishlist/",
    name: "hangar-wishlist",
    component: () => import("@/frontend/pages/Hangar/Wishlist/index.vue"),
    meta: {
      needsAuthentication: true,
      quickSearch: "searchCont",
      title: "hangar.wishlist",
      primaryAction: true,
      backgroundImage: "bg-5",
    },
  },
  {
    path: "/hangar/preview/",
    name: "hangar-preview",
    component: () => import("@/frontend/pages/Hangar/Preview/index.vue"),
    meta: {
      title: "hangar.preview",
      backgroundImage: "bg-5",
    },
  },
  {
    path: "/hangar/fleetchart/",
    name: "hangar-fleetchart",
    redirect: {
      name: "hangar",
      query: { fleetchart: "true" },
    },
  },
  {
    path: "/hangar/stats/",
    name: "hangar-stats",
    component: () => import("@/frontend/pages/Hangar/Stats/index.vue"),
    meta: {
      needsAuthentication: true,
      title: "hangar.stats",
      backgroundImage: "bg-5",
    },
  },
  {
    path: "/hangar/:username/",
    name: "hangar-public",
    component: () => import("@/frontend/pages/Hangar/Public/index.vue"),
    meta: {
      backgroundImage: "bg-5",
    },
  },
  {
    path: "/hangar/:username/fleetchart/",
    name: "hangar-public-fleetchart",
    redirect: {
      name: "hangar-public",
      query: { fleetchart: "true" },
    },
  },
  {
    path: "/hangar/:username/wishlist/",
    name: "wishlist-public",
    component: () => import("@/frontend/pages/Hangar/PublicWishlist/index.vue"),
    meta: {
      backgroundImage: "bg-5",
    },
  },
  {
    path: "/ships/",
    name: "models",
    component: () => import("@/frontend/pages/Models/index.vue"),
    meta: {
      title: "models.index",
      quickSearch: "searchCont",
    },
  },
  {
    path: "/ships/fleetchart/",
    name: "models-fleetchart",
    redirect: {
      name: "models",
      query: { fleetchart: "true" },
    },
  },
  {
    path: "/compare/ships/",
    name: "models-compare",
    component: () => import("@/frontend/pages/Models/Compare/index.vue"),
    meta: {
      title: "compare.models",
    },
  },
  {
    path: "/ships/:slug/",
    name: "model",
    component: () => import("@/frontend/pages/Models/Show/index.vue"),
  },
  {
    path: "/ships/:slug/images/",
    name: "model-images",
    component: () => import("@/frontend/pages/Models/Show/Images/index.vue"),
  },
  {
    path: "/ships/:slug/videos/",
    name: "model-videos",
    component: () => import("@/frontend/pages/Models/Show/Videos/index.vue"),
  },
  {
    path: "/stats/",
    name: "stats",
    component: () => import("@/frontend/pages/Stats/index.vue"),
    meta: {
      title: "stats",
    },
  },
  {
    path: "/fleets/",
    name: "fleets",
    component: () => import("@/frontend/pages/Fleets/index.vue"),
    children: FleetsRoutes,
    redirect: { name: FleetsRoutes[0].name },
    meta: {
      title: "fleets",
      backgroundImage: "bg-8",
    },
  },
  {
    path: "/images/",
    name: "images",
    component: () => import("@/frontend/pages/Images/index.vue"),
    meta: {
      title: "images",
    },
  },
  {
    path: "/stations/",
    component: () => import("@/frontend/pages/Stations/routerView.vue"),
    children: StationsRoutes,
  },
  {
    path: "/tools/",
    component: () => import("@/frontend/pages/Tools/routerView.vue"),
    children: ToolsRoutes,
    redirect: { name: ToolsRoutes[0].name },
  },
  {
    path: "/roadmap/",
    name: "roadmap",
    children: RoadmapRoutes,
    component: () => import("@/frontend/pages/Roadmap/index.vue"),
    meta: {
      title: "roadmap.index",
    },
  },
  {
    path: "/settings/",
    name: "settings",
    component: () => import("@/frontend/pages/Settings/index.vue"),
    meta: {
      needsAuthentication: true,
    },
    redirect: {
      name: "settings-profile",
    },
    children: SettingsRoutes,
  },
  {
    path: "/sign-up/",
    name: "signup",
    component: () => import("@/frontend/pages/Signup/index.vue"),
    meta: {
      title: "signUp",
    },
  },
  {
    path: "/login/",
    name: "login",
    component: () => import("@/frontend/pages/Login/index.vue"),
    meta: {
      title: "login",
    },
  },
  {
    path: "/password/request/",
    name: "request-password",
    component: () => import("@/frontend/pages/RequestPassword/index.vue"),
    meta: {
      title: "requestPassword",
    },
  },
  {
    path: "/password/update/:token/",
    name: "change-password",
    component: () => import("@/frontend/pages/ChangePassword/index.vue"),
    meta: {
      title: "changePassword",
    },
  },
  {
    path: "/confirm/:token/",
    name: "confirm",
    component: () => import("@/frontend/pages/Confirm/index.vue"),
  },
  {
    path: "/404/",
    name: "404",
    component: () => import("@/frontend/pages/NotFound/index.vue"),
    meta: {
      title: "notFound",
      backgroundImage: "bg-404",
    },
  },
  {
    path: "/:pathMatch(.*)*",
    component: () => import("@/frontend/pages/NotFound/index.vue"),
    meta: {
      title: "notFound",
      backgroundImage: "bg-404",
    },
  },
];

export default routes;
