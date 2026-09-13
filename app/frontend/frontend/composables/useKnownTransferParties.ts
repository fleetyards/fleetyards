import { useQueries } from "@tanstack/vue-query";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Fleet,
  type FleetMember,
  FeatureFlagName,
  getFleetMembersQueryOptions,
  useMyFleets,
} from "@/services/fyApi";
import { useSessionStore } from "@/frontend/stores/session";
import type { TransferTargetOption } from "@/frontend/components/Logistics/TransferModal/types";

// The parties a reader can pick rather than type: the fleets they belong to,
// and the people in them.
//
// There is no friends list and no user search, so "known" means "shares a fleet
// with you" -- which is also what a `known` transfer policy means server-side,
// so the picker and the gate agree on who counts.
//
// Fleets are filtered on whether the feature is *available* to them, never on
// whether the gate would admit this sender: a policy or a standing denial must
// not be readable from an option going missing. People are not filtered at all;
// a user's own flags are not ours to read.
export const useKnownTransferParties = (options?: {
  excludeFleetSlug?: string;
}) => {
  const { t } = useI18n();
  const sessionStore = useSessionStore();

  const { data: fleets } = useMyFleets();

  const fleetList = computed<Fleet[]>(() => fleets.value ?? []);

  // One request per fleet, because nothing answers "everyone I share a fleet
  // with" in one call. A reader belongs to a handful, and the results are
  // cached by the same keys the fleet pages already use.
  const memberQueries = useQueries({
    queries: computed(() =>
      fleetList.value.map((fleet) =>
        getFleetMembersQueryOptions(fleet.slug, { perPage: "100" }),
      ),
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
        kind: "user",
        value: `user:${member.username}`,
        label: member.username,
        needsAnswer: true,
        payload: { recipientUsername: member.username },
      }));
  });

  const canReceive = (fleet: Fleet) =>
    fleet.slug !== options?.excludeFleetSlug &&
    fleet.features?.includes(FeatureFlagName.INVENTORY_TRANSFERS) &&
    fleet.features?.includes(FeatureFlagName.FLEET_LOGISTICS);

  const fleetTargets = computed<TransferTargetOption[]>(() =>
    fleetList.value.filter(canReceive).map((fleet) => ({
      kind: "fleet",
      value: `fleet:${fleet.slug}`,
      label: t("labels.logistics.transferToFleet", { fleet: fleet.name }),
      needsAnswer: true,
      payload: { recipientFleetSlug: fleet.slug },
    })),
  );

  return { people, fleetTargets };
};
