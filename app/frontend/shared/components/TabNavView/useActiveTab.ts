import { type RouteRecordName, type RouteRecordRaw } from "vue-router";

export const routeName = (route: RouteRecordRaw) =>
  route.name || (route.redirect as RouteRecordRaw)?.name;

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
