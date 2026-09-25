import { type MaybeRefOrGetter, type Ref } from "vue";
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
export const useVehicleReorder = (
  items: Ref<Vehicle[] | undefined>,
  // What the list is a page of -- page, sort and filters. A new one is always
  // shown, move or no move: it is a different list, not a stale read of this one.
  listKey?: MaybeRefOrGetter<unknown>,
) => {
  const { t } = useI18n();

  const { displayAlert } = useAppNotifications();

  const orderedVehicles = ref<Vehicle[]>([]);

  // Moves sent and not yet answered. A read of the same list in the meantime
  // may have been answered before they landed, and taking it would put the
  // dragged ships back; the read that follows a landed move is broadcast and
  // taken instead.
  let pendingMoves = 0;

  let shownKey = JSON.stringify(toValue(listKey));

  watch(
    items,
    (vehicles) => {
      const key = JSON.stringify(toValue(listKey));

      if (pendingMoves && key === shownKey) return;

      shownKey = key;
      orderedVehicles.value = [...(vehicles ?? [])];
    },
    { immediate: true },
  );

  const moveMutation = useMoveVehicle();

  // One move at a time, in the order the drags happened: each names its
  // neighbour as it stood after the drag before it, so a later move reaching
  // the server first would place its ship against an order that is not there
  // yet.
  let moving: Promise<void> = Promise.resolve();

  // Counts failed moves. A drag queued behind one that failed named its
  // neighbour in an order that was never saved, so it is dropped rather than
  // sent.
  let failures = 0;

  /*
   * The page is a slice of the owner's order, and that order also holds the
   * wishlist and hidden ships this page never shows. So the move names the
   * neighbour it was dropped beside -- the ship now ahead of it, or the one
   * behind it at the top of a page -- and the server places it there.
   */
  const onSort = (keys: string[], id: string) => {
    const byId = new Map(
      orderedVehicles.value.map((vehicle) => [vehicle.id, vehicle]),
    );

    if (!byId.has(id)) return;

    const index = keys.indexOf(id);
    const ahead = keys[index - 1];
    const behind = keys[index + 1];

    orderedVehicles.value = keys
      .map((key) => byId.get(key))
      .filter((vehicle): vehicle is Vehicle => !!vehicle);

    const data = ahead ? { afterId: ahead } : { beforeId: behind };
    const failuresBefore = failures;

    pendingMoves += 1;

    moving = moving.then(async () => {
      if (failures !== failuresBefore) {
        pendingMoves -= 1;
        return;
      }

      await moveMutation
        .mutateAsync({ id, data })
        .finally(() => {
          pendingMoves -= 1;
        })
        // Back to the order the server last sent rather than to the one
        // before this drag: a drag before it may have landed, and putting back
        // a snapshot from before that would undo it too. A move that did land
        // is broadcast, and the list is read again with it in place.
        .catch(() => {
          failures += 1;
          orderedVehicles.value = [...(toValue(items) ?? [])];

          displayAlert({ text: t("messages.vehicle.move.failure") });
        });
    });

    return moving;
  };

  // The keyboard's move: one place towards the front or the back, sent the same
  // way a drag to there would be.
  const moveBy = (id: string, offset: number) => {
    const keys = orderedVehicles.value.map((vehicle) => vehicle.id);
    const from = keys.indexOf(id);
    const to = from + offset;

    if (from === -1 || to < 0 || to >= keys.length) return;

    keys.splice(from, 1);
    keys.splice(to, 0, id);

    return onSort(keys, id);
  };

  return { orderedVehicles, onSort, moveBy };
};
