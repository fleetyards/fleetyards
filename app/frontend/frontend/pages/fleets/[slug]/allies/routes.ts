import type { RouteRecordRaw } from "vue-router";

// One page, four routes -- see the friends routes for why the open list is a
// link rather than local state.
export const routes: RouteRecordRaw[] = [
  "",
  "incoming/",
  "outgoing/",
  "ignored/",
].map((suffix) => ({
  path: suffix,
  name: suffix ? `fleet-allies-${suffix.replace("/", "")}` : "fleet-allies",
  component: () => import("@/frontend/pages/fleets/[slug]/allies/index.vue"),
  meta: {
    needsAuthentication: true,
    backgroundImage: "bg-8",
    customTitle: true,
  },
}));
