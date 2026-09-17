import type { RouteRecordRaw } from "vue-router";

// The list is not here yet: it is the tenant that sits inside the shared
// catalogue section's nav, which #4988 builds. The detail page needs none of
// that -- `/components/:slug` is a top-level path either way, because
// `/catalogue` redirects to `/components` rather than nesting it.
export const routes: RouteRecordRaw[] = [
  {
    path: ":slug/",
    name: "component",
    component: () => import("@/frontend/pages/components/[slug].vue"),
    meta: {
      customTitle: true,
    },
  },
];
