import { type Ref } from "vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useMoveVehicle, type Vehicle } from "@/services/fyApi";

/**
 * Drag to rearrange a hangar page.
 *
 * The list holds the new order locally while the write is in flight:
 * re-reading the server between the drop and the response would snap the card
 * back to where it was dragged from.
 */
export const useVehicleReorder = (items: Ref<Vehicle[] | undefined>) => {
  const { t } = useI18n();

  const { displayAlert } = useAppNotifications();

  const orderedVehicles = ref<Vehicle[]>([]);

  watch(
    items,
    (vehicles) => {
      orderedVehicles.value = [...(vehicles ?? [])];
    },
    { immediate: true },
  );

  const moveMutation = useMoveVehicle();

  /*
   * The page is a slice of the owner's order, and that order also holds the
   * wishlist and hidden ships this page never shows. So the move names the
   * neighbour it was dropped beside -- the ship now ahead of it, or the one
   * behind it at the top of a page -- and the server places it there.
   */
  const onSort = (keys: string[], id: string) => {
    const previous = orderedVehicles.value;
    const byId = new Map(previous.map((vehicle) => [vehicle.id, vehicle]));

    if (!byId.has(id)) return;

    const index = keys.indexOf(id);
    const ahead = keys[index - 1];
    const behind = keys[index + 1];

    orderedVehicles.value = keys
      .map((key) => byId.get(key))
      .filter((vehicle): vehicle is Vehicle => !!vehicle);

    return moveMutation
      .mutateAsync({
        id,
        data: ahead ? { afterId: ahead } : { beforeId: behind },
      })
      .catch(() => {
        orderedVehicles.value = previous;

        displayAlert({ text: t("messages.vehicle.move.failure") });
      });
  };

  return { orderedVehicles, onSort };
};
