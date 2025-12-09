import type { RouteRecordRaw } from "vue-router";
import { routes as fleetsRoutes } from "@/frontend/pages/fleets/routes";
import { routes as hangarRoutes } from "@/frontend/pages/hangar/routes";
import { routes as settingsRoutes } from "@/frontend/pages/settings/routes";
import { routes as shipsRoutes } from "@/frontend/pages/ships/routes";
import { routes as toolsRoutes } from "@/frontend/pages/tools/routes";
import { routes as visualTestsRoutes } from "@/frontend/pages/visual-tests/routes";

const VisualTestsRoutes =
  process.env.NODE_ENV !== "production"
    ? [
        {
          name: "visual-tests",
          path: "/visual-tests/",
          component: () => import("@/frontend/pages/visual-tests.vue"),
          children: visualTestsRoutes,
          redirect: { name: visualTestsRoutes[0].name },
        },
      ]
    : [];

export const routes: RouteRecordRaw[] = [
  {
    path: "/",
    name: "home",
    component: () => import("@/frontend/pages/index.vue"),
    meta: {
      title: "home",
      nav: "main",
    },
  },
  {
    path: "/impressum/",
    name: "impressum",
    component: () => import("@/frontend/pages/impressum.vue"),
    meta: {
      title: "impressum",
      nav: "footer",
    },
  },
  {
    path: "/privacy-policy/",
    name: "privacy-policy",
    component: () => import("@/frontend/pages/privacy-policy.vue"),
    meta: {
      title: "privacyPolicy",
      nav: "footer",
    },
  },
  {
    path: "/hangar/",
    component: () => import("@/frontend/pages/hangar.vue"),
    children: hangarRoutes,
    redirect: { name: hangarRoutes[0].name },
    meta: {
      nav: "main",
    },
  },
  {
    path: "/compare/",
    name: "compare",
    component: () => import("@/frontend/pages/compare.vue"),
    meta: {
      title: "compare.ships",
      nav: "main",
    },
  },
  {
    path: "/ships/",
    component: () => import("@/frontend/pages/ships.vue"),
    children: shipsRoutes,
    redirect: { name: shipsRoutes[0].name },
    meta: {
      nav: "main",
    },
  },
  {
    path: "/stats/",
    name: "stats",
    component: () => import("@/frontend/pages/stats.vue"),
    meta: {
      title: "stats",
      nav: "main",
    },
  },
  {
    path: "/fleets/",
    name: "fleets",
    component: () => import("@/frontend/pages/fleets.vue"),
    children: fleetsRoutes,
    redirect: { name: fleetsRoutes[0].name },
    meta: {
      nav: "main",
    },
  },
  {
    path: "/images/",
    name: "images",
    component: () => import("@/frontend/pages/images.vue"),
    meta: {
      title: "images",
      nav: "main",
    },
  },
  {
    path: "/tools/",
    component: () => import("@/frontend/pages/tools.vue"),
    children: toolsRoutes,
    redirect: { name: toolsRoutes[0].name },
    meta: {
      nav: "main",
    },
  },
  {
    path: "/settings/",
    name: "settings",
    component: () => import("@/frontend/pages/settings.vue"),
    meta: {
      needsAuthentication: true,
      nav: "sub",
    },
    redirect: {
      name: "settings-profile",
    },
    children: settingsRoutes,
  },
  {
    path: "/sign-up/",
    name: "signup",
    component: () => import("@/frontend/pages/signup.vue"),
    meta: {
      title: "signUp",
      nav: "sub",
    },
  },
  {
    path: "/sign-up/auth-callback",
    name: "signup-auth-callback",
    component: () => import("@/frontend/pages/auth-callback.vue"),
    meta: {
      needsAuthentication: true,
    },
  },
  {
    path: "/login/",
    name: "login",
    component: () => import("@/frontend/pages/login.vue"),
    meta: {
      title: "login",
      needsNoAuthentication: true,
      nav: "sub",
    },
  },
  {
    path: "/oauth/authorize/",
    name: "oauth-authorize",
    component: () => import("@/frontend/pages/oauth/authorize.vue"),
    meta: {
      needsAuthentication: true,
    },
  },
  {
    path: "/password/request/",
    name: "request-password",
    component: () => import("@/frontend/pages/request-password.vue"),
    meta: {
      title: "requestPassword",
    },
  },
  {
    path: "/password/update/:token/",
    name: "change-password",
    component: () => import("@/frontend/pages/change-password.vue"),
    meta: {
      title: "changePassword",
    },
  },
  {
    path: "/confirm/:token/",
    name: "confirm",
    component: () => import("@/frontend/pages/confirm.vue"),
  },
  ...VisualTestsRoutes,
  {
    path: "/404/",
    name: "404",
    component: () => import("@/frontend/pages/404.vue"),
    meta: {
      title: "notFound",
      backgroundImage: "bg-404",
    },
  },
  {
    path: "/:pathMatch(.*)*",
    component: () => import("@/frontend/pages/404.vue"),
    meta: {
      title: "notFound",
      backgroundImage: "bg-404",
    },
  },
];
