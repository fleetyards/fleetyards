import { type RouteRecordName, type RouteRecordRaw } from "vue-router";

export const routeName = (
  route: RouteRecordRaw,
): RouteRecordName | undefined => {
  if (route.name) {
    return route.name;
  }

  // `redirect` is also allowed to be a function, and one written inline is
  // named after the property it was assigned to -- so reading `.name` off it
  // unguarded hands back the string "redirect", which no route is called.
  const { redirect } = route;

  return typeof redirect === "object" && redirect !== null
    ? (redirect as RouteRecordRaw).name
    : undefined;
};

/*
 * An old path kept alive so shared links still resolve is not a destination.
 *
 * A route named in its own right is always a tab. It is the nameless ones that
 * have to be told apart, and `routeName` cannot do it alone: it falls back to
 * the redirect's target, so a grouped tab and a retired alias both report a
 * name -- the group its first child, the alias the sibling that absorbed it.
 * The alias then drew a second copy of that sibling's tab, labelled
 * `nav.undefined` and lit whenever the real one was.
 *
 * What tells them apart is the title. A grouped tab carries one because the
 * strip has to label it; an alias carries no meta at all.
 */
export const isTabRoute = (route: RouteRecordRaw) =>
  !!route.name || (!!routeName(route) && !!route.meta?.title);

/*
 * Which tab the strip should light up. Shared by the desktop strip and the
 * mobile dropdown, which have to agree -- and did so by holding two copies of
 * this.
 */
export const useActiveTab = (routes: Ref<RouteRecordRaw[]>) => {
  const route = useRoute();

  const isActive = (tabRouteName?: RouteRecordName) => {
    if (tabRouteName === route.name) return true;

    // A detail page is not a tab, so it names the one it sits under.
    if (route.meta?.activeTab === tabRouteName) return true;

    const tabRoute = routes.value.find((r) => routeName(r) === tabRouteName);
    if (!tabRoute?.children?.length) return false;

    return route.matched.some(
      (matched) => (matched.redirect as RouteRecordRaw)?.name === tabRouteName,
    );
  };

  const activeRoute = computed(() =>
    routes.value.find((r) => isActive(routeName(r))),
  );

  return { isActive, activeRoute };
};
