import type { RouteRecordRaw } from "vue-router";
import { routes as componentRoutes } from "@/frontend/pages/components/[slug]/routes";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "components",
    component: () => import("@/frontend/pages/components/index.vue"),
    meta: {
      title: "components.index",
      nav: "main",
    },
  },
  {
    // A shell that resolves the component and hands it to whichever tab is
    // showing, the way `ships/[slug]` does.
    path: ":slug/",
    component: () => import("@/frontend/pages/components/[slug].vue"),
    children: componentRoutes,
    redirect: { name: componentRoutes[0].name },
  },
];
