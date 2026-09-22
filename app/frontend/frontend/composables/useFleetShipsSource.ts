import { type MaybeRefOrGetter, type Ref } from "vue";
import {
  useFleetVehicles as useFleetVehiclesQuery,
  useFleetVehiclesStats as useFleetVehiclesStatsQuery,
  useFleetModelCounts as useFleetModelCountsQuery,
  getFleetVehiclesQueryKey,
  fleetVehiclesExport as fetchFleetVehiclesExport,
  fleetVehiclesHangarLinkExport as fetchFleetVehiclesHangarLinkExport,
  useFleetSquadronVehicles as useFleetSquadronVehiclesQuery,
  useFleetSquadronVehiclesStats as useFleetSquadronVehiclesStatsQuery,
  useFleetSquadronModelCounts as useFleetSquadronModelCountsQuery,
  getFleetSquadronVehiclesQueryKey,
  fleetSquadronVehiclesExport as fetchFleetSquadronVehiclesExport,
  fleetSquadronVehiclesHangarLinkExport as fetchFleetSquadronVehiclesHangarLinkExport,
  type FleetVehiclesParams,
} from "@/services/fyApi";

/*
 * Where a fleet ship list gets its ships: the whole fleet, or one squadron.
 *
 * Both sets of queries are declared unconditionally and one of them is left
 * disabled -- hooks cannot be called in a branch, and this is how the fleet
 * page already reconciles its own two fleet queries. The caller sees one
 * uniform shape and never learns which side answered.
 *
 * The endpoints are the same six on either side, because the squadron
 * controllers subclass the fleet's and override only the scope. That is what
 * lets `FleetShipsList` serve both rather than growing a second copy.
 */
export const useFleetShipsSource = (
  fleetSlug: Ref<string>,
  squadronSlug: Ref<string | undefined>,
  params: MaybeRefOrGetter<FleetVehiclesParams>,
) => {
  const scoped = computed(() => !!squadronSlug.value);

  // Never the empty string: a disabled query still builds its key, and an
  // empty slug in one reads as a second, meaningless cache entry.
  const squadron = computed(() => squadronSlug.value ?? "");

  const fleetEnabled = computed(() => !scoped.value);

  const {
    data: fleetVehicles,
    refetch: refetchFleetVehicles,
    ...fleetStatus
  } = useFleetVehiclesQuery(fleetSlug, params, {
    query: { enabled: fleetEnabled },
  });

  const {
    data: squadronVehicles,
    refetch: refetchSquadronVehicles,
    ...squadronStatus
  } = useFleetSquadronVehiclesQuery(fleetSlug, squadron, params, {
    query: { enabled: scoped },
  });

  const { data: fleetStats, refetch: refetchFleetStats } =
    useFleetVehiclesStatsQuery(fleetSlug, { query: { enabled: fleetEnabled } });

  const { data: squadronStats, refetch: refetchSquadronStats } =
    useFleetSquadronVehiclesStatsQuery(fleetSlug, squadron, {
      query: { enabled: scoped },
    });

  const { data: fleetModelCounts, refetch: refetchFleetModelCounts } =
    useFleetModelCountsQuery(fleetSlug, params, {
      query: { enabled: fleetEnabled },
    });

  const { data: squadronModelCounts, refetch: refetchSquadronModelCounts } =
    useFleetSquadronModelCountsQuery(fleetSlug, squadron, params, {
      query: { enabled: scoped },
    });

  const vehicles = computed(() =>
    scoped.value ? squadronVehicles.value : fleetVehicles.value,
  );

  const stats = computed(() =>
    scoped.value ? squadronStats.value : fleetStats.value,
  );

  const modelCounts = computed(() =>
    scoped.value ? squadronModelCounts.value : fleetModelCounts.value,
  );

  const asyncStatus = computed(() =>
    scoped.value ? squadronStatus : fleetStatus,
  );

  const queryKey = computed(() =>
    scoped.value
      ? getFleetSquadronVehiclesQueryKey(fleetSlug.value, squadron.value)
      : getFleetVehiclesQueryKey(fleetSlug.value),
  );

  const refetch = async () => {
    if (scoped.value) {
      await refetchSquadronVehicles();
      await refetchSquadronModelCounts();
      await refetchSquadronStats();
      return;
    }

    await refetchFleetVehicles();
    await refetchFleetModelCounts();
    await refetchFleetStats();
  };

  const fetchExport = (exportParams: FleetVehiclesParams) =>
    scoped.value
      ? fetchFleetSquadronVehiclesExport(
          fleetSlug.value,
          squadron.value,
          exportParams,
        )
      : fetchFleetVehiclesExport(fleetSlug.value, exportParams);

  const fetchHangarLinkExport = (exportParams: FleetVehiclesParams) =>
    scoped.value
      ? fetchFleetSquadronVehiclesHangarLinkExport(
          fleetSlug.value,
          squadron.value,
          exportParams,
        )
      : fetchFleetVehiclesHangarLinkExport(fleetSlug.value, exportParams);

  return {
    scoped,
    vehicles,
    stats,
    modelCounts,
    asyncStatus,
    queryKey,
    refetch,
    fetchExport,
    fetchHangarLinkExport,
  };
};
