import type { Ref } from "vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Fleet,
  type HangarInventory,
  useHangarInventories,
  useMyFleets,
} from "@/services/fyApi";
import type { TransferTargetOption } from "@/frontend/components/Logistics/TransferModal/types";

// Where a user can send stock from one of their own inventories.
//
// Two kinds, and the difference is whether anybody has to answer. Another
// inventory of their own is carried out on the spot -- it is a deposit they
// could make by hand. A fleet they belong to, or another person, has to accept
// it first, and picks where it lands themselves.
//
// The client does not decide which is which by re-deriving the rule: it only
// knows that naming an inventory means "now" and naming a party means "ask",
// and the API refuses anything the sender is not actually allowed to do.
export const useTransferTargets = (
  source: Ref<HangarInventory | undefined>,
) => {
  const { t } = useI18n();

  const { data: inventories } = useHangarInventories();
  const { data: fleets } = useMyFleets();

  const ownInventories = computed<TransferTargetOption[]>(() =>
    (inventories.value?.items ?? [])
      .filter((inventory) => inventory.id !== source.value?.id)
      .map((inventory) => ({
        value: `inventory:${inventory.id}`,
        label: inventory.name,
        needsAnswer: false,
        payload: { inventoryId: inventory.id },
      })),
  );

  const fleetTargets = computed<TransferTargetOption[]>(() =>
    (fleets.value ?? []).map((fleet: Fleet) => ({
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
