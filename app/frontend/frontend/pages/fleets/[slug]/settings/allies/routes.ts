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
  name: suffix
    ? `fleet-settings-allies-${suffix.replace("/", "")}`
    : "fleet-settings-allies",
  component: () =>
    import("@/frontend/pages/fleets/[slug]/settings/allies/index.vue"),
  meta: {
    title: "fleets.settings.allies",
    needsAuthentication: true,
    customTitle: true,
  },
}));
