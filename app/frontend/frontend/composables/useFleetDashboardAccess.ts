import { type MaybeRefOrGetter } from "vue";
import {
  FeatureFlagName,
  FleetMembershipStatusEnum,
  type Fleet,
  type FleetMember,
} from "@/services/fyApi";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { useFleetSubscription } from "@/frontend/composables/useFleetSubscription";

/**
 * Which of the dashboard's panels this reader gets. Each one asks what the API
 * behind it asks -- the role, the feature's rollout and, for the premium
 * modules, the fleet's subscription -- so a panel is either shown and answered,
 * or not shown at all, and never one that renders a 403.
 */
export const useFleetDashboardAccess = (
  fleet: MaybeRefOrGetter<Fleet>,
  membership: MaybeRefOrGetter<FleetMember | undefined>,
) => {
  const { isFleetFeatureEnabled } = useFeatures();

  const { subscriptionRequired } = useFleetSubscription(fleet);

  const isMember = computed(
    () => toValue(membership)?.status === FleetMembershipStatusEnum.ACCEPTED,
  );

  const capabilities = computed(() =>
    isMember.value ? toValue(membership)?.capabilities : undefined,
  );

  const premiumAvailable = (feature: FeatureFlagName) =>
    isFleetFeatureEnabled(toValue(fleet), feature) &&
    !subscriptionRequired.value;

  const showEvents = computed(
    () =>
      premiumAvailable(FeatureFlagName.FLEET_MISSION_BUILDER) &&
      !!capabilities.value?.readEvents,
  );

  const showContracts = computed(
    () =>
      premiumAvailable(FeatureFlagName.FLEET_CONTRACTS) &&
      !!capabilities.value?.readContracts,
  );

  const showInventory = computed(
    () =>
      premiumAvailable(FeatureFlagName.FLEET_LOGISTICS) &&
      !!capabilities.value?.readInventories,
  );

  const showNewMembers = computed(() => !!capabilities.value?.readMembers);

  // The two queues an officer answers for the fleet as a whole: who asked to
  // join, and what was sent to the fleet. Each needs the right to list it and
  // the right to answer it.
  const canAnswerJoinRequests = computed(
    () =>
      !!capabilities.value?.readMembers && !!capabilities.value?.updateMembers,
  );

  const canAnswerTransfers = computed(
    () => showInventory.value && !!capabilities.value?.updateInventories,
  );

  const canCreateEvents = computed(
    () => showEvents.value && !!capabilities.value?.createEvents,
  );

  const canCreateContracts = computed(
    () => showContracts.value && !!capabilities.value?.createContracts,
  );

  const canReadMissions = computed(() => !!capabilities.value?.readMissions);

  // Who is around is read off the roster, so it asks what the roster asks.
  const showOnline = showNewMembers;

  // The loose ends are for whoever can act on members, like the join queue.
  const showHealth = canAnswerJoinRequests;

  const canManageAnnouncements = computed(
    () => !!capabilities.value?.manageAnnouncements,
  );

  const showActionQueue = computed(
    () => canAnswerJoinRequests.value || canAnswerTransfers.value,
  );

  return {
    showEvents,
    showContracts,
    showInventory,
    showNewMembers,
    showActionQueue,
    canAnswerJoinRequests,
    canAnswerTransfers,
    canCreateEvents,
    canCreateContracts,
    canReadMissions,
    showOnline,
    showHealth,
    canManageAnnouncements,
  };
};
