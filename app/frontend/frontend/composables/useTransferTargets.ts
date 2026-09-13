import type { MaybeRefOrGetter } from "vue";
import { useQueries } from "@tanstack/vue-query";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Fleet,
  type FleetMember,
  FeatureFlagName,
  fleetMembers,
  useFleetInventories,
  useHangarInventories,
  useMyFleets,
} from "@/services/fyApi";
import { useSessionStore } from "@/frontend/stores/session";
import type { TransferTargetOption } from "@/frontend/components/Logistics/TransferModal/types";

type Options = {
  // The inventory being emptied, so it is never offered as its own destination.
  source: MaybeRefOrGetter<{ id?: string | null } | undefined>;
  // Present when sending on a fleet's behalf. Its own inventories become the
  // immediate targets, and it drops out of the fleet list.
  fleetSlug?: MaybeRefOrGetter<string | undefined>;
};

const MEMBER_PARAMS = { perPage: "100" };

// Where stock can be sent, for either side. One composable rather than one per
// mount: the only thing that differs is whose inventories count as "mine", and
// the backend answers both through a single controller concern for exactly the
// same reason.
//
// Three kinds, kept apart because they are different kinds of address:
//
//   inventory  another of your own -- carried out on the spot
//   fleet      a fleet you belong to -- has to accept
//   user       somebody you share a fleet with -- has to accept
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
  const { t } = useI18n();
  const sessionStore = useSessionStore();

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

  // One request per fleet, because nothing answers "everyone I share a fleet
  // with" in one call. Plain options rather than the generated ones: those
  // unwrap refs for `useQuery`, and `useQueries` wants a settled key.
  const memberQueries = useQueries({
    queries: computed(() =>
      fleetList.value.map((fleet) => ({
        queryKey: ["fleets", fleet.slug, "members", MEMBER_PARAMS],
        queryFn: () => fleetMembers(fleet.slug, MEMBER_PARAMS),
      })),
    ),
  });

  const people = computed<TransferTargetOption[]>(() => {
    const seen = new Set<string>();
    const me = sessionStore.currentUser?.username;

    return memberQueries.value
      .flatMap((query) => (query.data?.items ?? []) as FleetMember[])
      .filter((member) => {
        if (!member.username || member.username === me) return false;
        if (seen.has(member.username)) return false;

        seen.add(member.username);

        return true;
      })
      .sort((a, b) => a.username.localeCompare(b.username))
      .map((member) => ({
        kind: "user" as const,
        value: `user:${member.username}`,
        label: member.username,
        needsAnswer: true,
        payload: { recipientUsername: member.username },
      }));
  });

  const targets = computed<TransferTargetOption[]>(() => [
    ...ownInventories.value,
    ...fleetTargets.value,
    ...people.value,
  ]);

  return { targets, ownInventories, fleetTargets, people, t };
};
