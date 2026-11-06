import { type Vehicle, useVehiclePaints } from "@/services/fyApi";

export const useVehicleOwnedPaints = (vehicle: () => Vehicle) => {
  const { data, isLoading, isPlaceholderData } = useVehiclePaints(
    () => vehicle().id,
  );

  // A placeholder is the previous ship's list.
  const loaded = computed(() => !!data.value && !isPlaceholderData.value);

  const pending = computed(() => isLoading.value || isPlaceholderData.value);

  const all = computed(() => (loaded.value ? (data.value ?? []) : []));

  // A pledge names no ship, so it counts for any ship of the model the owner
  // really has, but not for one on loan or still on the wishlist.
  const pledgesCount = computed(() => !vehicle().loaner && !vehicle().wanted);

  const owned = computed(() =>
    all.value.filter(
      (entry) => entry.owned || (pledgesCount.value && entry.pledged),
    ),
  );

  return { all, owned, loaded, pending };
};
