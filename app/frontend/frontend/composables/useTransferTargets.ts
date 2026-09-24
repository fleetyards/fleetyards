import type { MaybeRefOrGetter } from "vue";
import {
  type Fleet,
  FeatureFlagName,
  FleetContractDestinationHolderEnum,
  useFleetAllies,
  useFleetInventories,
  useFriends,
  useHangarContractDestinations,
  useHangarInventories,
  useMyFleets,
} from "@/services/fyApi";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { useI18n } from "@/shared/composables/useI18n";
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
//   contract   where a contract you work on delivers -- filed under that
//              contract, and waits for whoever answers for its destination
//
// Who this reaches is kept in step with what `known` means server-side, so the
// picker and the gate agree on who counts: a fleet in common, a friendship, or
// -- when sending on a fleet's behalf -- an alliance.
//
// Both sides are filtered on whether the feature is *available* to the party,
// never on whether the gate would admit this sender: a policy or a standing
// denial must not be readable from an option going missing.
//
// For people that filtering is the API's, through `transferTargets` on the two
// group endpoints, and it does make one person's feature flags legible from
// another's picker. The trade was made deliberately: `TransferGate` already
// answers the same fact one refused send at a time, and a name that can only be
// picked to be told "this person cannot receive" is worse than a name that was
// never offered.

// The value the group picker uses for "my friends" rather than a fleet slug.
// Not a slug any fleet can have: slugs are lowercased alphanumerics.
export const FRIENDS_GROUP = "@friends";

export const useTransferTargets = (options: Options) => {
  const actingFleet = computed(() => toValue(options.fleetSlug));
  const sourceId = computed(() => toValue(options.source)?.id);

  const { isFeatureEnabled } = useFeatures();
  const { t } = useI18n();

  // Always fetched, even when acting for a fleet: a fleet issuing kit to one of
  // its members is the sixth movement, and the reader's own inventories are
  // where that lands.
  const { data: hangarInventories } = useHangarInventories();

  const { data: fleetInventories } = useFleetInventories(
    computed(() => actingFleet.value ?? ""),
    undefined,
    { query: { enabled: computed(() => !!actingFleet.value) } },
  );

  const inventoryTargets = (
    items: { id: string; name: string }[],
    payloadKey: "inventoryId" | "fleetInventoryId",
    kind: "inventory" | "mine",
  ): TransferTargetOption[] =>
    items
      .filter((inventory) => inventory.id !== sourceId.value)
      .map((inventory) => ({
        kind,
        value: `${payloadKey}:${inventory.id}`,
        label: inventory.name,
        needsAnswer: false,
        payload: { [payloadKey]: inventory.id },
      }));

  // Acting for a fleet, both are offered -- the fleet's and the reader's -- as
  // two kinds rather than one list with "(mine)" stuck on half its rows. When
  // the fleet holds nothing but the source, that suffix was on every entry and
  // said nothing.
  const ownInventories = computed<TransferTargetOption[]>(() =>
    actingFleet.value
      ? [
          ...inventoryTargets(
            fleetInventories.value?.items ?? [],
            "fleetInventoryId",
            "inventory",
          ),
          ...inventoryTargets(
            hangarInventories.value?.items ?? [],
            "inventoryId",
            "mine",
          ),
        ]
      : inventoryTargets(
          hangarInventories.value?.items ?? [],
          "inventoryId",
          "inventory",
        ),
  );

  const { data: fleets } = useMyFleets();

  const fleetList = computed<Fleet[]>(() => fleets.value ?? []);

  // A fleet's allies, and only when acting for that fleet. An alliance is
  // between the two organisations, not between one of them and each member of
  // the other, so a person shipping from their own hangar is never offered it.
  const { data: allies } = useFleetAllies(
    computed(() => actingFleet.value ?? ""),
    computed(() => ({ state: "accepted" as const })),
    {
      query: {
        enabled: computed(
          () =>
            !!actingFleet.value &&
            isFeatureEnabled(FeatureFlagName.FLEET_ALLIES),
        ),
      },
    },
  );

  // Accepted friendships, for the party picker. Only for a reader sending as
  // themselves: a fleet has no friends.
  const { data: friends } = useFriends(
    computed(() => ({ state: "accepted" as const, transferTargets: true })),
    {
      query: {
        enabled: computed(
          () => !actingFleet.value && isFeatureEnabled(FeatureFlagName.FRIENDS),
        ),
      },
    },
  );

  const canReceive = (fleet: Fleet) =>
    fleet.slug !== actingFleet.value &&
    fleet.features?.includes(FeatureFlagName.INVENTORY_TRANSFERS) &&
    fleet.features?.includes(FeatureFlagName.FLEET_LOGISTICS);

  // An ally carries no feature list -- the alliance payload names the fleet and
  // nothing about what it holds -- so unlike `fleetList` these are not filtered
  // on availability. Offering one the API then refuses is the right way round:
  // the refusal is the API's to give, and inferring it here would be guessing.
  const allyTargets = computed<TransferTargetOption[]>(() =>
    (allies.value?.items ?? []).map((alliance) => ({
      kind: "fleet" as const,
      value: `fleet:${alliance.fleet.slug}`,
      label: alliance.fleet.name,
      needsAnswer: true,
      payload: { recipientFleetSlug: alliance.fleet.slug },
    })),
  );

  const fleetTargets = computed<TransferTargetOption[]>(() => [
    ...fleetList.value.filter(canReceive).map((fleet) => ({
      kind: "fleet" as const,
      value: `fleet:${fleet.slug}`,
      label: fleet.name,
      needsAnswer: true,
      payload: { recipientFleetSlug: fleet.slug },
    })),
    ...allyTargets.value,
  ]);

  // Where a person can be picked out of. The *groups* are not filtered on
  // transfer flags the way `fleetTargets` is -- those gate sending to the fleet
  // itself, and this is about finding a person who happens to be in it. The
  // people inside them are, by the endpoints the pickers read.
  //
  // This list is the grouping, and it is the extension point: a friends list,
  // or any other way of knowing somebody, becomes another entry here rather
  // than another branch in the modal.
  // Friends are the entry this list was always going to grow: another way of
  // knowing somebody, offered as a group to pick a person out of rather than as
  // a fourth kind of address.
  const friendOptions = computed(() =>
    (friends.value?.items ?? []).map((friendship) => ({
      value: `user:${friendship.user.username}`,
      label: friendship.user.username,
    })),
  );

  const memberFleets = computed(() => [
    ...(friendOptions.value.length
      ? [
          {
            value: FRIENDS_GROUP,
            label: t("labels.logistics.transferFromFriends"),
          },
        ]
      : []),
    ...fleetList.value.map((fleet) => ({
      value: fleet.slug,
      label: fleet.name,
    })),
  ]);

  // The contracts the reader holds a seat on, and where each delivers. Only
  // when sending as themselves: a contractor delivers their own goods. The
  // author's inventory is named here and nothing more -- the API resolves it
  // as a target only together with its contract.
  const offersContracts = computed(
    () =>
      !actingFleet.value && isFeatureEnabled(FeatureFlagName.FLEET_CONTRACTS),
  );

  const { data: contractDestinations } = useHangarContractDestinations({
    query: { enabled: offersContracts },
  });

  // Guarded as well as disabled: a disabled query still hands back what an
  // earlier one cached, and a fleet sending is not a contractor delivering.
  const contractTargets = computed<TransferTargetOption[]>(() =>
    (offersContracts.value ? (contractDestinations.value ?? []) : []).map(
      (target) => ({
        kind: "contract" as const,
        value: `contract:${target.contractId}`,
        label: t("labels.logistics.contractDeliveryTarget", {
          contract: target.contractTitle,
          fleet: target.fleetName,
          destination: target.destination.name,
        }),
        needsAnswer: true,
        payload:
          target.destination.holder === FleetContractDestinationHolderEnum.USER
            ? {
                inventoryId: target.destination.id,
                contractId: target.contractId,
              }
            : {
                recipientFleetSlug: target.fleetSlug,
                contractId: target.contractId,
              },
      }),
    ),
  );

  const targets = computed<TransferTargetOption[]>(() => [
    ...ownInventories.value,
    ...fleetTargets.value,
    ...contractTargets.value,
  ]);

  return {
    targets,
    ownInventories,
    fleetTargets,
    contractTargets,
    memberFleets,
    friendOptions,
  };
};
