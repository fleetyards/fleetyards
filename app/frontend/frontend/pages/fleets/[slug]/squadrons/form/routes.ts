import type { RouteMeta, RouteRecordRaw } from "vue-router";

/*
 * The two halves of one form: what a squadron is, and what it looks like. They
 * are tabs rather than one long page because three file fields under four text
 * fields made a form where neither half was findable -- not because they are
 * saved separately. One submit writes both, from whichever tab it is pressed
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
      path: "images/",
      name: `${name}-images`,
      component: () =>
        import("@/frontend/pages/fleets/[slug]/squadrons/form/images.vue"),
      meta: { ...meta, title: `fleets.squadrons.${mode}.images` },
    },
  ];
};
