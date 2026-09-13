import type { MaybeRefOrGetter } from "vue";
import {
  type Fleet,
  FeatureFlagName,
  useFleetInventories,
  useHangarInventories,
  useMyFleets,
} from "@/services/fyApi";
import type { TransferTargetOption } from "@/frontend/components/Logistics/TransferModal/types";

type Options = {
  // The inventory being emptied, so it is never offered as its own destination.
  source: MaybeRefOrGetter<{ id?: string | null } | undefined>;
  // Present when sending on a fleet's behalf. Its own inventories become the
  // immediate targets, and it drops out of the fleet list.
  fleetSlug?: MaybeRefOrGetter<string | undefined>;
};

// Where stock can be sent, for either side. One composable rather than one per
// mount: the only thing that differs is whose inventories count as "mine", and
// the backend answers both through a single controller concern for exactly the
// same reason.
//
// Three kinds, kept apart because they are different kinds of address:
//
//   inventory  another of your own -- carried out on the spot
//   fleet      a fleet you belong to -- has to accept
//   user       somebody you share a fleet with -- has to accept, and is
//              picked out of that fleet rather than from one flat list
//
// This iteration reaches only what the reader already shares a fleet with,
// which is what a `known` transfer policy means server-side, so the picker and
// the gate agree on who counts.
//
// Fleets are filtered on whether the feature is *available* to them, never on
// whether the gate would admit this sender: a policy or a standing denial must
// not be readable from an option going missing. People are not filtered --
// another user's flags are not ours to read.
export const useTransferTargets = (options: Options) => {
  const actingFleet = computed(() => toValue(options.fleetSlug));
  const sourceId = computed(() => toValue(options.source)?.id);

  const { data: hangarInventories } = useHangarInventories(undefined, {
    query: { enabled: computed(() => !actingFleet.value) },
  });

  const { data: fleetInventories } = useFleetInventories(
    computed(() => actingFleet.value ?? ""),
    undefined,
    { query: { enabled: computed(() => !!actingFleet.value) } },
  );

  const ownInventories = computed<TransferTargetOption[]>(() => {
    const items = actingFleet.value
      ? (fleetInventories.value?.items ?? [])
      : (hangarInventories.value?.items ?? []);

    return items
      .filter((inventory) => inventory.id !== sourceId.value)
      .map((inventory) => ({
        kind: "inventory" as const,
        value: `inventory:${inventory.id}`,
        label: inventory.name,
        needsAnswer: false,
        payload: actingFleet.value
          ? { fleetInventoryId: inventory.id }
          : { inventoryId: inventory.id },
      }));
  });

  const { data: fleets } = useMyFleets();

  const fleetList = computed<Fleet[]>(() => fleets.value ?? []);

  const canReceive = (fleet: Fleet) =>
    fleet.slug !== actingFleet.value &&
    fleet.features?.includes(FeatureFlagName.INVENTORY_TRANSFERS) &&
    fleet.features?.includes(FeatureFlagName.FLEET_LOGISTICS);

  const fleetTargets = computed<TransferTargetOption[]>(() =>
    fleetList.value.filter(canReceive).map((fleet) => ({
      kind: "fleet" as const,
      value: `fleet:${fleet.slug}`,
      label: fleet.name,
      needsAnswer: true,
      payload: { recipientFleetSlug: fleet.slug },
    })),
  );

  // Where a person can be picked out of. Not filtered on transfer flags the way
  // `fleetTargets` is: those gate sending to the *fleet*, and this is about
  // finding a person who happens to be in it.
  //
  // This list is the grouping, and it is the extension point: a friends list,
  // or any other way of knowing somebody, becomes another entry here rather
  // than another branch in the modal.
  const memberFleets = computed(() =>
    fleetList.value.map((fleet) => ({
      value: fleet.slug,
      label: fleet.name,
    })),
  );

  const targets = computed<TransferTargetOption[]>(() => [
    ...ownInventories.value,
    ...fleetTargets.value,
  ]);

  return { targets, ownInventories, fleetTargets, memberFleets };
};
