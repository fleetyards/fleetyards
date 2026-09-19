import { useQueries } from "@tanstack/vue-query";
import { storeToRefs } from "pinia";
import { useSessionStore } from "@/frontend/stores/session";
import {
  useMyFleets,
  getFleetBlueprintsQueryOptions,
  type FleetBlueprintOwner,
} from "@/services/fyApi";

export type BlueprintFleetOwners = {
  slug: string;
  name: string;
  ownerCount: number;
  owners: FleetBlueprintOwner[];
};

/**
 * Which of the reader's fleets have somebody who holds this recipe.
 *
 * One request per fleet, the way `useMaterialStock` already asks for fleet
 * stock: they resolve independently, so a fleet whose role does not grant
 * `fleet:blueprints:read` answers 403 without taking the others with it.
 *
 * The endpoint is the fleet's whole list, narrowed to one blueprint rather than
 * given a shape of its own -- two payloads for one question drift.
 */
export const useBlueprintFleetOwners = (
  blueprintId: MaybeRefOrGetter<string | undefined>,
) => {
  const { isAuthenticated } = storeToRefs(useSessionStore());

  // The catalogue is public and mostly read by people who are not signed in,
  // and a recipe page renders before its blueprint has arrived. Asking in
  // either state would be a 401 or a request for nothing.
  const enabled = computed(
    () => isAuthenticated.value && !!toValue(blueprintId),
  );

  const { data: fleets } = useMyFleets({
    query: { enabled: isAuthenticated, retry: false },
  });

  const fleetList = computed(() => fleets.value ?? []);

  const results = useQueries({
    queries: computed(() =>
      fleetList.value.map((fleet) =>
        getFleetBlueprintsQueryOptions(
          fleet.slug,
          computed(() => ({ q: { idIn: [toValue(blueprintId) as string] } })),
          { query: { enabled, retry: false } },
        ),
      ),
    ),
  });

  // Only the fleets that answered with somebody. A fleet where nobody holds
  // the recipe has nothing to say about it, and listing it as empty reads as
  // an answer about the fleet rather than about the recipe.
  const fleetsWithOwners = computed<BlueprintFleetOwners[]>(() =>
    results.value.flatMap((result, at) => {
      const fleet = fleetList.value[at];
      const row = result.data?.items?.[0];

      if (!fleet || !row || !row.owners.length) return [];

      return [
        {
          slug: fleet.slug,
          name: fleet.name,
          ownerCount: row.ownerCount,
          owners: row.owners,
        },
      ];
    }),
  );

  return { fleetsWithOwners };
};
