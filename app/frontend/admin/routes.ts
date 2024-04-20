import { routes as modelsRoutes } from "@/admin/pages/models/routes";

export const routes = [
  {
    path: "/models/",
    component: () => import("@/admin/pages/models.vue"),
    children: modelsRoutes,
    redirect: { name: modelsRoutes[0].name },
  },
  {
    path: "/images",
    name: "images",
    component: () => import("@/admin/pages/images.vue"),
    meta: {
      title: "admin.images.index",
    },
  },
];

export default routes;
