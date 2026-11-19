import { useQueries } from "@tanstack/vue-query";
import type { MaybeRefOrGetter } from "vue";
import { useRouteDrive } from "@/frontend/composables/useRouteDrive";
import {
  planRoute,
  type QuantumRoute,
  type RouteSystem,
  type RouteTunnel,
} from "@/frontend/utils/quantumRoute";
import {
  LocationKindEnum,
  getLocationStarmapQueryOptions,
  type Location,
  type LocationJumpPoint,
  type LocationStarmapPlace,
} from "@/services/fyApi";
import { UNIT, toScene, type StarmapVector } from "./layout";

export interface RoutePlaceOption {
  place: LocationStarmapPlace;
  systemId: string;
  systemName: string;
}

/**
 * Pairs each jump point with the one at the other end of its tunnel: the
 * jump point in the destination system that leads back.
 */
export const tunnelsOf = (jumpPoints: LocationJumpPoint[]): RouteTunnel[] =>
  jumpPoints.flatMap((point) =>
    jumpPoints
      .filter(
        (other) =>
          other.systemId === point.destinationSystemId &&
          other.destinationSystemId === point.systemId,
      )
      .map((other) => ({ from: point.location.id, to: other.location.id })),
  );

/**
 * The jumps of a route that fall in one system, as the scene draws them:
 * scene units from that system's star.
 */
export const legsInSystem = (
  route: QuantumRoute | null,
  system: RouteSystem | undefined,
): [StarmapVector, StarmapVector][] => {
  if (!route || !system) return [];

  const star = system.places.find(
    (place) => place.kind === LocationKindEnum.STAR,
  );
  const origin = star?.position ?? [0, 0, 0];

  return route.legs.flatMap((leg) =>
    leg.kind === "quantum" && leg.systemId === system.id
      ? [
          [
            toScene(leg.from.position, origin, UNIT),
            toScene(leg.to.position, origin, UNIT),
          ] as [StarmapVector, StarmapVector],
        ]
      : [],
  );
};

/**
 * A route across every system the starmap knows, flown with a ship's drive.
 * Every system's places are only asked for once a route is being planned.
 */
export const useStarmapRoute = ({
  enabled,
  systems,
  jumpPoints,
  from,
  to,
  ship,
  loadout,
}: {
  enabled: MaybeRefOrGetter<boolean>;
  systems: MaybeRefOrGetter<Location[]>;
  jumpPoints: MaybeRefOrGetter<LocationJumpPoint[]>;
  from: MaybeRefOrGetter<string | null>;
  to: MaybeRefOrGetter<string | null>;
  ship: MaybeRefOrGetter<string | null>;
  loadout: MaybeRefOrGetter<string | null>;
}) => {
  const starmaps = useQueries({
    queries: computed(() =>
      toValue(systems).map((system) =>
        getLocationStarmapQueryOptions(system.slug, {
          query: { enabled: () => toValue(enabled), retry: false },
        }),
      ),
    ),
  });

  // Rebuilt only when a system's places change: a refetch that brings the
  // same data keeps the list, and the plan is not run again for it.
  const routeSystems = computed<RouteSystem[]>((previous) => {
    const next = starmaps.value.flatMap((result) =>
      result.data
        ? [{ id: result.data.system.id, places: result.data.places }]
        : [],
    );

    const unchanged =
      previous?.length === next.length &&
      previous.every(
        (system, index) =>
          system.id === next[index].id && system.places === next[index].places,
      );

    return unchanged && previous ? previous : next;
  });

  const placesLoading = computed(
    () => toValue(enabled) && starmaps.value.some((result) => result.isLoading),
  );

  const tunnels = computed(() => tunnelsOf(toValue(jumpPoints)));

  // What a route can start or end at: where a quantum drive takes you, and
  // the jump points it leaves a system through.
  const options = computed<RoutePlaceOption[]>(() => {
    const tunnelEnds = new Set(
      tunnels.value.flatMap((tunnel) => [tunnel.from, tunnel.to]),
    );

    return starmaps.value.flatMap((result) => {
      const data = result.data;
      if (!data) return [];

      return data.places
        .filter(
          (place) => place.quantumTravelDestination || tunnelEnds.has(place.id),
        )
        .map((place) => ({
          place,
          systemId: data.system.id,
          systemName: data.system.name ?? data.system.slug,
        }));
    });
  });

  const bySlug = (slug: string | null) =>
    slug
      ? options.value.find((option) => option.place.slug === slug)
      : undefined;

  const origin = computed(() => bySlug(toValue(from)));
  const destination = computed(() => bySlug(toValue(to)));

  const {
    model,
    drive,
    loadoutOptions,
    missingLoadout,
    loading: driveLoading,
  } = useRouteDrive({
    modelSlug: () => toValue(ship) ?? undefined,
    loadoutId: () => toValue(loadout) ?? undefined,
  });

  const route = computed<QuantumRoute | null>(() => {
    if (!drive.value || !origin.value || !destination.value) return null;

    return planRoute({
      systems: routeSystems.value,
      tunnels: tunnels.value,
      drive: drive.value,
      from: origin.value.place.id,
      to: destination.value.place.id,
    });
  });

  return {
    options,
    origin,
    destination,
    routeSystems,
    placesLoading,
    model,
    drive,
    driveLoading,
    loadoutOptions,
    missingLoadout,
    route,
  };
};
