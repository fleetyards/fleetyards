import { useFleetRouteCheck } from "@/frontend/composables/useFleetRouteCheck";
import { useNavContextStore } from "@/frontend/stores/navContext";

// The pages reached from the account menu: about the reader, not about any one
// hangar or fleet.
const ACCOUNT_ROUTES = new Set(["notifications", "cart"]);

export const isAccountRoute = (name: string) =>
  name.startsWith("settings") || ACCOUNT_ROUTES.has(name);

/**
 * Which fleet the navigation is in, if any. A fleet's pages put it there and
 * every other page takes it back out, except the account's own pages, which
 * leave it where it was.
 */
export const useNavContext = () => {
  const route = useRoute();

  const { isFleetRoute } = useFleetRouteCheck();

  const store = useNavContextStore();

  const fleetSlug = computed<string | null>(() => {
    if (isFleetRoute.value) {
      return String(route.params.slug);
    }

    if (isAccountRoute(String(route.name ?? ""))) {
      return store.fleetSlug;
    }

    return null;
  });

  watch(
    fleetSlug,
    (slug) => {
      store.fleetSlug = slug;
    },
    { immediate: true },
  );

  return { fleetSlug };
};
