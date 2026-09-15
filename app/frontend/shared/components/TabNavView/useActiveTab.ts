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

// An old path kept alive so shared links still resolve is not a destination:
// it has no name to link to and no title to label it with.
export const isTabRoute = (route: RouteRecordRaw) => !!routeName(route);

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
