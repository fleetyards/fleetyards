import type { RouteRecordRaw } from "vue-router";

export const routes: RouteRecordRaw[] = [
  {
    path: "",
    name: "fleet-members-index",
    component: () => import("@/frontend/pages/fleets/[slug]/members/index.vue"),
    meta: {
      title: "fleets.members.index",
      needsAuthentication: true,
      quickSearch: "searchCont",
    },
  },
  {
    path: "invites/",
    name: "fleet-members-invites",
    component: () =>
      import("@/frontend/pages/fleets/[slug]/members/invites.vue"),
    meta: {
      title: "fleets.members.invites",
      needsAuthentication: true,
      access: [
        "fleet:memberships:read",
        "fleet:memberships:manage",
        "fleet:manage",
      ],
    },
  },
];
