import type { MaybeRefOrGetter } from "vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Fleet,
  FeatureFlagName,
  useFleetInventories,
  useMyFleets,
} from "@/services/fyApi";
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
  const { t } = useI18n();

  const { data: inventories } = useFleetInventories(fleetSlug);
  const { data: fleets } = useMyFleets();

  const ownInventories = computed<TransferTargetOption[]>(() =>
    (inventories.value?.items ?? [])
      .filter((inventory) => inventory.id !== toValue(source)?.id)
      .map((inventory) => ({
        value: `fleet-inventory:${inventory.id}`,
        label: inventory.name,
        needsAnswer: false,
        payload: { fleetInventoryId: inventory.id },
      })),
  );

  const canReceive = (fleet: Fleet) =>
    fleet.slug !== toValue(fleetSlug) &&
    fleet.features?.includes(FeatureFlagName.INVENTORY_TRANSFERS) &&
    fleet.features?.includes(FeatureFlagName.FLEET_LOGISTICS);

  const fleetTargets = computed<TransferTargetOption[]>(() =>
    (fleets.value ?? []).filter(canReceive).map((fleet: Fleet) => ({
      value: `fleet:${fleet.slug}`,
      label: t("labels.logistics.transferToFleet", { fleet: fleet.name }),
      needsAnswer: true,
      payload: { recipientFleetSlug: fleet.slug },
    })),
  );

  const targets = computed<TransferTargetOption[]>(() => [
    ...ownInventories.value,
    ...fleetTargets.value,
  ]);

  return { targets, ownInventories, fleetTargets };
};
