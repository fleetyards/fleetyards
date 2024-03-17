import type { RouteRecordRaw } from "vue-router";
import { routes as stationsRoutes } from "@/frontend/pages/Stations/routes";
import { routes as roadmapRoutes } from "@/frontend/pages/Roadmap/routes";
import { routes as settingsRoutes } from "@/frontend/pages/Settings/routes";
import { routes as fleetsRoutes } from "@/frontend/pages/Fleets/routes";
import { routes as modelRoutes } from "@/frontend/pages/Models/Show/routes";
import { routes as toolsRoutes } from "@/frontend/pages/Tools/routes";
import { routes as visualTestsSubRoutes } from "@/frontend/pages/VisualTests/routes";

const VisualTestsRoutes =
  process.env.NODE_ENV !== "production"
    ? [
        {
          path: "/visual-tests/",
          name: "visual-tests",
          component: () => import("@/frontend/pages/VisualTests/index.vue"),
          children: visualTestsSubRoutes,
        },
      ]
    : [];

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
    component: () => import("@/frontend/pages/Models/Show/routerView.vue"),
    children: modelRoutes,
    redirect: { name: modelRoutes[0].name },
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
    component: () => import("@/frontend/pages/Fleets/routerView.vue"),
    children: fleetsRoutes,
    redirect: { name: fleetsRoutes[0].name },
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
    children: stationsRoutes,
    redirect: { name: stationsRoutes[0].name },
  },
  {
    path: "/tools/",
    component: () => import("@/frontend/pages/Tools/routerView.vue"),
    children: toolsRoutes,
    redirect: { name: toolsRoutes[0].name },
  },
  {
    path: "/roadmap/",
    component: () => import("@/frontend/pages/Roadmap/routerView.vue"),
    children: roadmapRoutes,
    redirect: { name: roadmapRoutes[0].name },
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
    children: settingsRoutes,
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
  ...VisualTestsRoutes,
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
