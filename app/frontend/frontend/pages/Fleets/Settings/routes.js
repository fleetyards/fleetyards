export const routes = [
  {
    path: "fleet/",
    name: "fleet-settings-fleet",
    component: () => import("@/frontend/pages/Fleets/Settings/Fleet/index.vue"),
    meta: {
      needsAuthentication: true,
    },
  },
  {
    path: "membership/",
    name: "fleet-settings-membership",
    component: () =>
      import("@/frontend/pages/Fleets/Settings/Membership/index.vue"),
    meta: {
      needsAuthentication: true,
    },
  },
];

export default routes;
