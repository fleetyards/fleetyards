import type { RouteMeta, RouteRecordRaw } from "vue-router";

/*
 * The parts of one form: what a squadron is, what it looks like, and where it
 * is announced on Discord. They are tabs rather than one long page so that no
 * part gets buried under the others -- not because they are saved separately. One submit writes both, from whichever tab it is pressed
 * on.
 *
 * Built per mode, since the route names and the document titles differ between
 * creating a squadron and editing one while the pages themselves do not.
 */
export const squadronFormRoutes = (
  mode: "create" | "edit",
  access: string[],
): RouteRecordRaw[] => {
  const meta: RouteMeta = {
    needsAuthentication: true,
    nav: "editTabs",
    activeRoute: "fleet-squadrons",
    access,
    customTitle: true,
  };

  const name = mode === "create" ? "fleet-squadron-new" : "fleet-squadron-edit";

  return [
    {
      path: "",
      name,
      component: () =>
        import("@/frontend/pages/fleets/[slug]/squadrons/form/details.vue"),
      meta: { ...meta, title: `fleets.squadrons.${mode}.details` },
    },
    {
      path: "appearance/",
      name: `${name}-appearance`,
      component: () =>
        import("@/frontend/pages/fleets/[slug]/squadrons/form/appearance.vue"),
      meta: { ...meta, title: `fleets.squadrons.${mode}.appearance` },
    },
    {
      path: "discord/",
      name: `${name}-discord`,
      component: () =>
        import("@/frontend/pages/fleets/[slug]/squadrons/form/discord.vue"),
      meta: { ...meta, title: `fleets.squadrons.${mode}.discord` },
    },
  ];
};
