import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "fleet-members-index",
    component: () => import("@/frontend/pages/fleets/[slug]/members/index.vue"),
    meta: {
      title: "fleets.members.index",
      needsAuthentication: true,
      customTitle: true,
    },
  },
  {
    path: "worldmap/",
    name: "fleet-members-worldmap",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/members/worldmap.vue"),
    meta: {
      title: "fleets.members.worldmap",
      needsAuthentication: true,
      customTitle: true,
    },
  },
  {
    path: "starmap/",
    name: "fleet-members-starmap",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/members/starmap.vue"),
    meta: {
      title: "fleets.members.starmap",
      needsAuthentication: true,
      customTitle: true,
    },
  },
  {
    // Was a page of its own; the roster and the invites are one list asked two
    // questions, so the choice moved into the query. The path stays so shared
    // links resolve.
    path: "invites/",
    redirect: (to) => ({
      name: "fleet-members-index",
      params: to.params,
      query: { ...to.query, view: "invites" },
    }),
  },
];
