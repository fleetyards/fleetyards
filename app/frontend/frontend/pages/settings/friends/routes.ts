import type { RouteRecordRaw } from "vue-router";

// Four routes for one page -- which list is open is a link somebody can be
// sent, and a reload that lands where it left off. `ignored` is reachable and
// never the default. The allies routes are the same shape.
export const routes: RouteRecordRaw[] = [
  "",
  "incoming/",
  "outgoing/",
  "ignored/",
].map((suffix) => ({
  path: suffix,
  name: suffix
    ? `settings-friends-${suffix.replace("/", "")}`
    : "settings-friends",
  component: () => import("@/frontend/pages/settings/friends/index.vue"),
  meta: {
    title: "settings.friends",
    needsAuthentication: true,
  },
}));
