import { useSearchStore } from "@/frontend/stores/search";
import { useSessionStore } from "@/frontend/stores/session";
import {
  fleetSearch,
  hangarSearch,
  search,
  type SearchResults,
} from "@/services/fyApi";

export type SearchScope = {
  key: string;
  labelKey: string;
  // Absent where the field's own wording fits.
  placeholderKey?: string;
  fleetSlug?: string;
  search: (q: string) => Promise<SearchResults>;
};

export const CATALOGUE_SCOPE = "catalogue";

const CATALOGUE: SearchScope = {
  key: CATALOGUE_SCOPE,
  labelKey: "nav.catalogue.index",
  search: (q) => search({ q }),
};

const MINE: SearchScope = {
  key: "mine",
  labelKey: "home.landing.searchScopes.mine",
  placeholderKey: "home.landing.searchScopes.minePlaceholder",
  search: (q) => hangarSearch({ q }),
};

const NOT_A_MEMBER = [403, 404];

export const useSearchScopes = () => {
  const store = useSearchStore();
  const sessionStore = useSessionStore();
  const route = useRoute();

  const routeFleet = computed(() => {
    const slug = route?.params?.slug;

    return route?.path?.startsWith("/fleets/") && typeof slug === "string"
      ? slug
      : undefined;
  });

  // Learned from the answer: a fleet someone only visits, or has since left.
  const refused = ref<string[]>([]);

  watch(
    routeFleet,
    (slug) => {
      if (slug && !refused.value.includes(slug)) store.fleetSlug = slug;
    },
    { immediate: true },
  );

  const fleetSlug = computed(() => {
    const slug = routeFleet.value ?? store.fleetSlug;

    return slug && !refused.value.includes(slug) ? slug : undefined;
  });

  const fleetScope = (slug: string): SearchScope => ({
    key: "fleet",
    labelKey: "home.landing.searchScopes.fleet",
    placeholderKey: "home.landing.searchScopes.fleetPlaceholder",
    fleetSlug: slug,
    search: async (q) => {
      try {
        return await fleetSearch(slug, { q });
      } catch (error) {
        const status = (error as { response?: { status?: number } }).response
          ?.status;

        if (status && NOT_A_MEMBER.includes(status)) {
          refused.value = [...refused.value, slug];
          if (store.fleetSlug === slug) store.fleetSlug = undefined;
        }

        throw error;
      }
    },
  });

  const scopes = computed<SearchScope[]>(() => {
    if (!sessionStore.isAuthenticated) return [CATALOGUE];

    return [
      CATALOGUE,
      MINE,
      ...(fleetSlug.value ? [fleetScope(fleetSlug.value)] : []),
    ];
  });

  // The saved scope may no longer be on offer: a guest, or a fleet since left.
  const current = computed(
    () =>
      scopes.value.find((scope) => scope.key === store.scope) ??
      scopes.value[0],
  );

  const select = (key: string) => {
    store.scope = key;
  };

  const step = (by: 1 | -1) => {
    const count = scopes.value.length;
    const index = scopes.value.findIndex(
      (scope) => scope.key === current.value.key,
    );

    select(scopes.value[(index + by + count) % count].key);
  };

  return { scopes, current, select, step };
};
