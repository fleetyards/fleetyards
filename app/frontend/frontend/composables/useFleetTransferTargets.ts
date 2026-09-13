import type { MaybeRefOrGetter } from "vue";
import { useFleetInventories } from "@/services/fyApi";
import { useKnownTransferParties } from "@/frontend/composables/useKnownTransferParties";
import type { TransferTargetOption } from "@/frontend/components/Logistics/TransferModal/types";

// Where a fleet can send stock. The mirror of `useTransferTargets`, which does
// the same for a user: another of this fleet's own inventories is carried out
// on the spot -- a deposit anybody privileged here could make by hand -- while
// another fleet has to accept it and pick where it lands.
//
// Filtered on whether the feature is *available* to the other fleet, never on
// whether the gate would admit this sender: a policy or a standing denial must
// not be readable from an option going missing.
export const useFleetTransferTargets = (
  fleetSlug: MaybeRefOrGetter<string>,
  source: MaybeRefOrGetter<{ id?: string | null } | undefined>,
) => {
  const { data: inventories } = useFleetInventories(fleetSlug);
  const ownInventories = computed<TransferTargetOption[]>(() =>
    (inventories.value?.items ?? [])
      .filter((inventory) => inventory.id !== toValue(source)?.id)
      .map((inventory) => ({
        kind: "inventory",
        value: `fleet-inventory:${inventory.id}`,
        label: inventory.name,
        needsAnswer: false,
        payload: { fleetInventoryId: inventory.id },
      })),
  );

  const { people, fleetTargets } = useKnownTransferParties({
    excludeFleetSlug: toValue(fleetSlug),
  });

  const targets = computed<TransferTargetOption[]>(() => [
    ...ownInventories.value,
    ...fleetTargets.value,
    ...people.value,
  ]);

  return { targets, ownInventories, fleetTargets };
};
