import { type RouterLinkProps } from "vue-router";
import { useBreadCrumbsStore } from "@/shared/stores/breadCrumbs";
import { useLastRoute } from "@/shared/composables/useLastRoute";

export const useBreadCrumbs = () => {
  const router = useRouter();

  const breadCrumbsStore = useBreadCrumbsStore();

  const { extend: extendLastRoute } = useLastRoute();

  const extend = (to: RouterLinkProps["to"]) => {
    const resolvedRoute = router.resolve(to);

    if (!resolvedRoute.name) {
      return extendLastRoute(to);
    }

    const savedPath = breadCrumbsStore.crumbs[resolvedRoute.name as string];

    if (!savedPath) {
      return extendLastRoute(to);
    }

    const savedRoute = router.resolve(savedPath);

    return {
      name: resolvedRoute.name,
      hash: resolvedRoute.hash,
      params: {
        ...resolvedRoute.params,
        ...savedRoute.params,
      },
      query: {
        ...resolvedRoute.query,
        ...savedRoute.query,
      },
    } as RouterLinkProps["to"];
  };

  return {
    extend,
  };
};
