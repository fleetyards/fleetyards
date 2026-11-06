import { type Vehicle, useVehiclePaints } from "@/services/fyApi";

export const useVehicleOwnedPaints = (vehicle: () => Vehicle) => {
  const { data, isLoading } = useVehiclePaints(() => vehicle().id);

  const all = computed(() => data.value ?? []);

  // A pledge names no ship, so it counts for any ship of the model the owner
  // really has, but not for one on loan or still on the wishlist.
  const pledgesCount = computed(() => !vehicle().loaner && !vehicle().wanted);

  const owned = computed(() =>
    all.value.filter(
      (entry) => entry.owned || (pledgesCount.value && entry.pledged),
    ),
  );

  return { all, owned, isLoading };
};
