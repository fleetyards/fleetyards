import type { RouteRecordRaw, RouteLocation } from "vue-router";

export const addTrailingSlashToAllRoutes = (
  routes: RouteRecordRaw[],
): RouteRecordRaw[] =>
  ([] as RouteRecordRaw[]).concat(
    ...routes.map((route: RouteRecordRaw): RouteRecordRaw[] => {
      if (["*", "/", ""].includes(route.path)) {
        return [route];
      }

      const path = route.path.replace(/\/$/, "");

      const modifiedRoute = {
        ...route,
        strict: true,
        path: `${path}/`,
      };

      if (route.children && route.children.length > 0) {
        modifiedRoute.children = addTrailingSlashToAllRoutes(route.children);
      }

      return [
        {
          path,
          redirect: (to: RouteLocation) => ({
            name: route.name,
            params: to.params || undefined,
            query: to.query || undefined,
          }),
        },
        modifiedRoute,
      ];
    }),
  );
