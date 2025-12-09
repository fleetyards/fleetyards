import { type RouterLinkProps } from "vue-router";

export const useLastRoute = () => {
  const router = useRouter();

  const lastRoute = computed(() => {
    if (!router.options.history.state.back) {
      return undefined;
    }

    return router.resolve(router.options.history.state.back as string);
  });

  const extend = (route: RouterLinkProps["to"]): RouterLinkProps["to"] => {
    const resolvedRoute = router.resolve(route);
    if (lastRoute.value && lastRoute.value.name === resolvedRoute.name) {
      return {
        name: resolvedRoute.name as string,
        hash: resolvedRoute.hash,
        params: {
          ...lastRoute.value.params,
          ...resolvedRoute.params,
        },
        query: {
          ...lastRoute.value.query,
          ...resolvedRoute.query,
        },
      };
    }

    return route;
  };

  return {
    lastRoute,
    extend,
  };
};
