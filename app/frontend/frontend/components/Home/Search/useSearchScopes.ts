import { type Icon } from "@/shared/components/DuotoneGlyph/glyph";
import { FLEET_GLYPH } from "@/shared/glyphs/fleets";
import { useSearchStore } from "@/frontend/stores/search";
import { useSessionStore } from "@/frontend/stores/session";
import {
  fleetSearch,
  hangarSearch,
  search,
  type SearchResults,
} from "@/services/fyApi";

export interface SearchScope {
  key: string;
  labelKey: string;
  icon: Icon;
  // Absent where the field's own wording fits.
  placeholderKey?: string;
  fleetSlug?: string;
  search: (q: string) => Promise<SearchResults>;
}

export const CATALOGUE_SCOPE = "catalogue";

const CATALOGUE: SearchScope = {
  key: CATALOGUE_SCOPE,
  labelKey: "nav.catalogue.index",
  icon: "fa-duotone fa-books",
  search: (q) => search({ q }),
};

const MINE: SearchScope = {
  key: "mine",
  labelKey: "home.landing.searchScopes.mine",
  icon: "fa-duotone fa-warehouse",
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

  // Asked again on the next visit: someone refused today may since have joined.
  watch(routeFleet, () => {
    refused.value = [];
  });

  const fleetSlug = computed(() => {
    const slug = routeFleet.value ?? store.fleetSlug;

    return slug && !refused.value.includes(slug) ? slug : undefined;
  });

  const fleetScope = (slug: string): SearchScope => ({
    key: "fleet",
    labelKey: "home.landing.searchScopes.fleet",
    icon: FLEET_GLYPH,
    placeholderKey: "home.landing.searchScopes.fleetPlaceholder",
    fleetSlug: slug,
    search: async (q) => {
      try {
        const results = await fleetSearch(slug, { q });

        // Only once it has answered: viewing a fleet's public page must not
        // replace the one the reader is actually in.
        store.fleetSlug = slug;

        return results;
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
