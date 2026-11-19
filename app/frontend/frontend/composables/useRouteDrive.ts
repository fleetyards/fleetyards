import { useQueries } from "@tanstack/vue-query";
import { storeToRefs } from "pinia";
import type { MaybeRefOrGetter } from "vue";
import { useSessionStore } from "@/frontend/stores/session";
import { useLoadoutFitting } from "@/frontend/composables/useLoadoutFitting";
import { findQuantumDrive } from "@/frontend/utils/quantumDrive";
import type { RouteDrive } from "@/frontend/utils/quantumRoute";
import {
  HardpointSourceEnum,
  VehicleLoadoutKindEnum,
  getVehicleLoadoutsQueryOptions,
  useHangar,
  useModel,
  useModelHardpoints,
  useVehicleLoadoutSlots,
  type Vehicle,
  type VehicleLoadout,
} from "@/services/fyApi";

export interface RouteLoadoutOption {
  id: string;
  name: string;
  vehicle: Vehicle;
  loadout: VehicleLoadout;
}

/**
 * The quantum drive a route is flown with: the ship's stock drive, or the one
 * fitted in a loadout of the signed-in user's own ship of that model. Only a
 * loadout kept here lists what it fits; one that links to a build elsewhere is
 * not offered.
 */
export const useRouteDrive = ({
  modelSlug,
  loadoutId,
}: {
  modelSlug: MaybeRefOrGetter<string | undefined>;
  loadoutId: MaybeRefOrGetter<string | undefined>;
}) => {
  const { isAuthenticated } = storeToRefs(useSessionStore());

  const slug = () => toValue(modelSlug) ?? "";

  const { data: model, isLoading: modelLoading } = useModel(slug, {
    query: { enabled: () => !!slug() },
  });

  const { data: stockHardpoints, isLoading: hardpointsLoading } =
    useModelHardpoints(
      slug,
      { source: HardpointSourceEnum.GAME_FILES },
      { query: { enabled: () => !!slug() } },
    );

  const { data: hangar } = useHangar(
    () => ({ q: { modelSlugIn: [slug()] }, perPage: "100" }),
    {
      query: {
        enabled: () => isAuthenticated.value && !!slug(),
        retry: false,
      },
    },
  );

  const vehicles = computed(() => (slug() ? (hangar.value?.items ?? []) : []));

  const loadoutResults = useQueries({
    queries: computed(() =>
      vehicles.value.map((vehicle) =>
        getVehicleLoadoutsQueryOptions(vehicle.id, {
          query: { retry: false },
        }),
      ),
    ),
  });

  const loadoutOptions = computed<RouteLoadoutOption[]>(() =>
    loadoutResults.value.flatMap((result, at) => {
      const vehicle = vehicles.value[at];

      if (!vehicle) return [];

      return (result.data ?? [])
        .filter((loadout) => loadout.kind === VehicleLoadoutKindEnum.FLEETYARDS)
        .map((loadout) => ({
          id: loadout.id,
          name: [vehicle.name || vehicle.model.name, loadout.name]
            .filter(Boolean)
            .join(" · "),
          vehicle,
          loadout,
        }));
    }),
  );

  const selected = computed(() =>
    loadoutOptions.value.find((option) => option.id === toValue(loadoutId)),
  );

  const { data: loadoutSlots, isLoading: slotsLoading } =
    useVehicleLoadoutSlots(
      () => selected.value?.vehicle.id ?? "",
      () => selected.value?.loadout.id ?? "",
      { query: { enabled: () => !!selected.value } },
    );

  const { hardpoints: fittedHardpoints, loading: fittingLoading } =
    useLoadoutFitting({
      model: () => model.value,
      loadoutSlots: () => loadoutSlots.value,
      items: () => selected.value?.loadout.items,
      enabled: () => !!selected.value,
    });

  const loading = computed(
    () =>
      modelLoading.value ||
      hardpointsLoading.value ||
      (!!selected.value && (slotsLoading.value || fittingLoading.value)),
  );

  const drive = computed<RouteDrive | null>(() => {
    if (!slug() || loading.value) return null;

    const typeData = findQuantumDrive(
      selected.value ? fittedHardpoints.value : stockHardpoints.value,
    );

    if (!typeData?.driveSpeed) return null;

    return {
      typeData,
      tankSize: model.value?.metrics?.quantumFuelTankSize ?? null,
    };
  });

  return { model, drive, loadoutOptions, loading };
};
