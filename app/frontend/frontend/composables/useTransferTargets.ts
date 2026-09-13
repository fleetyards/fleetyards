import { useI18n } from "@/shared/composables/useI18n";
import {
  type Fleet,
  FeatureFlagName,
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
// A getter rather than a `Ref`: a `Ref` is invariant, so a caller holding a
// `Ref<Inventory> | Ref<undefined>` -- which is what the query hooks hand back --
// cannot pass it. Only the id is read, and it is nullable because a ship's
// inventory has none until something is put in it.
export const useTransferTargets = (
  source: MaybeRefOrGetter<{ id?: string | null } | undefined>,
) => {
  const { t } = useI18n();

  const { data: inventories } = useHangarInventories();
  const { data: fleets } = useMyFleets();

  const ownInventories = computed<TransferTargetOption[]>(() =>
    (inventories.value?.items ?? [])
      .filter((inventory) => inventory.id !== toValue(source)?.id)
      .map((inventory) => ({
        value: `inventory:${inventory.id}`,
        label: inventory.name,
        needsAnswer: false,
        payload: { inventoryId: inventory.id },
      })),
  );

  // Both flags, because a transfer into a fleet inventory rides on the gate
  // that already governs them: the new flag does not open a fleet whose
  // logistics are switched off. The fleet payload carries its own enabled
  // features, so this needs nothing from the server that is not already here.
  const canReceive = (fleet: Fleet) =>
    fleet.features?.includes(FeatureFlagName.INVENTORY_TRANSFERS) &&
    fleet.features?.includes(FeatureFlagName.FLEET_LOGISTICS);

  // Filtered on whether the feature is *available* to that fleet -- never on
  // whether the gate would admit this particular sender. A policy or a standing
  // denial must not be readable from an option going missing: that is the same
  // fact `TransferGate` refuses to distinguish in its wording, and hiding the
  // option would say it louder. Those are refused at send time instead.
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
