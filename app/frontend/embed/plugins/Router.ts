import { createRouter, createMemoryHistory } from "vue-router";

const router = createRouter({
  history: createMemoryHistory(),
  linkActiveClass: "active",
  linkExactActiveClass: "active-exact",
  routes: [
    {
      path: "/",
      name: "home",
      component: () => import("@/embed/pages/index.vue"),
    },
  ],
});

export default router;
