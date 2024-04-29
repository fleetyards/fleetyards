import { routes as modelsRoutes } from "@/admin/pages/models/routes";
import { routes as maintenanceRoutes } from "@/admin/pages/maintenance/routes";

export const routes = [
  {
    path: "/",
    name: "home",
    component: () => import("@/admin/pages/index.vue"),
    meta: {
      title: "home",
      icon: "fad fa-home-alt",
      exact: true,
    },
  },
  {
    path: "/models/",
    component: () => import("@/admin/pages/models.vue"),
    children: modelsRoutes,
    redirect: { name: modelsRoutes[0].name },
    meta: {
      title: "admin.models.index",
      icon: "fad fa-starship",
    },
  },
  {
    path: "/components/",
    name: "components",
    component: () => import("@/admin/pages/components.vue"),
    meta: {
      title: "admin.components.index",
      icon: "fad fa-flux-capacitor",
    },
  },
  {
    path: "/manufacturers/",
    name: "manufacturers",
    component: () => import("@/admin/pages/manufacturers.vue"),
    meta: {
      title: "admin.manufacturers.index",
      icon: "fad fa-industry",
    },
  },
  {
    path: "/images",
    name: "images",
    component: () => import("@/admin/pages/images.vue"),
    meta: {
      title: "admin.images.index",
      icon: "fad fa-images",
    },
  },
  {
    path: "/vehicles",
    name: "vehicles",
    component: () => import("@/admin/pages/vehicles.vue"),
    meta: {
      title: "admin.vehicles.index",
      icon: "fad fa-rocket",
    },
  },
  {
    path: "/fleets",
    name: "fleets",
    component: () => import("@/admin/pages/fleets.vue"),
    meta: {
      title: "admin.fleets.index",
      icon: "fad fa-users",
    },
  },
  {
    path: "/users",
    name: "users",
    component: () => import("@/admin/pages/users.vue"),
    meta: {
      title: "admin.users.index",
      icon: "fad fa-user-group",
    },
  },
  {
    path: "/admins",
    name: "admins",
    component: () => import("@/admin/pages/admins.vue"),
    meta: {
      title: "admin.admins.index",
      icon: "fad fa-user-group-crown",
    },
  },
  {
    path: "/maintenance",
    name: "maintenance",
    children: maintenanceRoutes,
    redirect: { name: maintenanceRoutes[0].name },
    meta: {
      title: "admin.maintenance.index",
      icon: "fad fa-screwdriver-wrench",
    },
  },
  {
    path: "/404/",
    name: "404",
    component: () => import("@/admin/pages/404.vue"),
    meta: {
      title: "notFound",
      backgroundImage: "bg-404",
      hide: true,
    },
  },
  {
    path: "/:pathMatch(.*)*",
    component: () => import("@/admin/pages/404.vue"),
    meta: {
      title: "notFound",
      backgroundImage: "bg-404",
      hide: true,
    },
  },
];

export default routes;
