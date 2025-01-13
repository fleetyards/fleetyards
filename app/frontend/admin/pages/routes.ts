import { routes as modelsRoutes } from "@/admin/pages/models/routes";
import { routes as manufacturersRoutes } from "@/admin/pages/manufacturers/routes";
import { routes as componentsRoutes } from "@/admin/pages/components/routes";
import { routes as maintenanceRoutes } from "@/admin/pages/maintenance/routes";
import { routes as usersRoutes } from "@/admin/pages/users/routes";
import { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "/",
    name: "home",
    component: () => import("@/admin/pages/index.vue"),
    meta: {
      title: "home",
      icon: "fad fa-home-alt",
      needsAuthentication: true,
      exact: true,
      mobileNav: 0,
      access: "all",
    },
  },
  {
    path: "/models/",
    component: () => import("@/admin/pages/models.vue"),
    children: modelsRoutes,
    redirect: { name: modelsRoutes[0].name },
    meta: {
      title: "admin.models.index",
      needsAuthentication: true,
      icon: "fad fa-starship",
      mobileNav: 1,
      access: "models",
    },
  },
  {
    path: "/components/",
    component: () => import("@/admin/pages/components.vue"),
    children: componentsRoutes,
    redirect: { name: componentsRoutes[0].name },
    meta: {
      title: "admin.components.index",
      needsAuthentication: true,
      icon: "fad fa-flux-capacitor",
      access: "components",
    },
  },
  {
    path: "/manufacturers/",
    component: () => import("@/admin/pages/manufacturers.vue"),
    children: manufacturersRoutes,
    redirect: { name: manufacturersRoutes[0].name },
    meta: {
      title: "admin.manufacturers.index",
      needsAuthentication: true,
      icon: "fad fa-industry",
      access: "manufacturers",
    },
  },
  {
    path: "/images",
    name: "admin-images",
    component: () => import("@/admin/pages/images.vue"),
    meta: {
      title: "admin.images.index",
      needsAuthentication: true,
      icon: "fad fa-images",
      access: "images",
    },
  },
  {
    path: "/vehicles",
    name: "admin-vehicles",
    component: () => import("@/admin/pages/vehicles.vue"),
    meta: {
      title: "admin.vehicles.index",
      needsAuthentication: true,
      icon: "fad fa-rocket",
      access: "vehicles",
    },
  },
  {
    path: "/fleets",
    name: "admin-fleets",
    component: () => import("@/admin/pages/fleets.vue"),
    meta: {
      title: "admin.fleets.index",
      needsAuthentication: true,
      icon: "fad fa-users-class",
      mobileNav: 2,
      access: "fleets",
    },
  },
  {
    path: "/users",
    component: () => import("@/admin/pages/users.vue"),
    children: usersRoutes,
    redirect: { name: usersRoutes[0].name },
    meta: {
      title: "admin.users.index",
      needsAuthentication: true,
      icon: "fad fa-users",
      mobileNav: 3,
      access: "users",
    },
  },
  {
    path: "/admins",
    name: "admin-admins",
    component: () => import("@/admin/pages/admins.vue"),
    meta: {
      title: "admin.admins.index",
      needsAuthentication: true,
      icon: "fad fa-user-group-crown",
    },
  },
  {
    path: "/maintenance",
    name: "admin-maintenance",
    children: maintenanceRoutes,
    redirect: { name: maintenanceRoutes[0].name },
    meta: {
      title: "admin.maintenance.index",
      needsAuthentication: true,
      icon: "fad fa-screwdriver-wrench",
    },
  },
  {
    path: "/login/",
    name: "admin-login",
    component: () => import("@/admin/pages/login.vue"),
    meta: {
      title: "login",
      icon: "fal fa-sign-in",
      hideWhenAuthenticated: true,
      nav: "footer",
      access: "all",
    },
  },
  {
    path: "/404/",
    name: "404",
    component: () => import("@/admin/pages/404.vue"),
    meta: {
      title: "notFound",
      backgroundImage: "bg-404",
      nav: "hidden",
      access: "all",
    },
  },
  {
    path: "/403/",
    name: "403",
    component: () => import("@/admin/pages/403.vue"),
    meta: {
      title: "notAuthorized",
      backgroundImage: "bg-404",
      nav: "hidden",
      access: "all",
    },
  },
  {
    path: "/:pathMatch(.*)*",
    component: () => import("@/admin/pages/404.vue"),
    meta: {
      title: "notFound",
      backgroundImage: "bg-404",
      nav: "hidden",
      access: "all",
    },
  },
];

export default routes;
