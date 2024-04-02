export const routes = [
  {
    path: "/models/:uuid/images",
    name: "model-images",
    component: () => import("@/admin/pages/Models/Images/index.vue"),
  },
  {
    path: "/images",
    name: "images",
    component: () => import("@/admin/pages/Images/index.vue"),
  },
];

export default routes;
