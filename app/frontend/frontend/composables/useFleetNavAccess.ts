import { type MaybeRefOrGetter } from "vue";
import {
  useFleetMembership as useFleetMembershipQuery,
  FeatureFlagName,
  FleetRoleResourceAccessEnum,
  type Fleet,
} from "@/services/fyApi";
import { useSessionStore } from "@/frontend/stores/session";
import { useFeatures } from "@/frontend/composables/useFeatures";

// `subscribed` is optional although the schema types it required: the public
// fleet endpoint is documented as returning a whole Fleet but its view renders
// the base partial only, so a fleet read while signed out carries neither it
// nor `features`. The optional chaining on `features` below is the same
// admission. Absent has to read as unsubscribed either way.
export const useFleetNavAccess = (
  fleet: MaybeRefOrGetter<
    (Pick<Fleet, "features"> & Partial<Pick<Fleet, "subscribed">>) | undefined
  >,
) => {
  const route = useRoute();

  const sessionStore = useSessionStore();

  const { isFeatureEnabled, isFleetFeatureEnabled } = useFeatures();

  const fleetSlug = computed(() => route.params.slug as string);

  const hasSlug = computed(() => route.params.slug !== undefined);

  const { data: membership } = useFleetMembershipQuery(fleetSlug, {
    query: {
      retry: false,
      enabled: computed(() => hasSlug.value && sessionStore.isAuthenticated),
    },
  });

  const hasResourceAccess = (...allowed: FleetRoleResourceAccessEnum[]) => {
    const access = membership.value?.fleetRole?.resourceAccess;

    if (!access) {
      return false;
    }

    return access.some((resource) => allowed.includes(resource));
  };

  // Mirrors `FleetSubscriptionConcern`: two questions, capability first. This
  // one is the second, and it is asked only once enforcement is rolled out for
  // this fleet -- while `fleet_subscriptions` is off it answers true and the
  // tabs are exactly what they were before any of this shipped.
  //
  // An unsubscribed fleet loses the tab rather than getting one that leads to
  // a refusal. The upsell still exists for anyone who arrives by URL or from a
  // stale link; it is just not something the nav walks people into.
  const subscriptionSatisfied = computed(() => {
    const currentFleet = toValue(fleet);

    if (
      !isFleetFeatureEnabled(currentFleet, FeatureFlagName.FLEET_SUBSCRIPTIONS)
    ) {
      return true;
    }

    return currentFleet?.subscribed ?? false;
  });

  const hasLogisticsAccess = computed(
    () => membership.value?.capabilities?.readInventories ?? false,
  );

  const hasAlliesAccess = computed(
    () => membership.value?.capabilities?.readAllies ?? false,
  );

  const hasContractsAccess = computed(() =>
    hasResourceAccess(
      FleetRoleResourceAccessEnum.FLEET_MANAGE,
      FleetRoleResourceAccessEnum.FLEET_CONTRACTS_MANAGE,
      FleetRoleResourceAccessEnum.FLEET_CONTRACTS_READ,
    ),
  );

  const hasMissionsAccess = computed(() =>
    hasResourceAccess(
      FleetRoleResourceAccessEnum.FLEET_MANAGE,
      FleetRoleResourceAccessEnum.FLEET_MISSIONS_MANAGE,
      FleetRoleResourceAccessEnum.FLEET_MISSIONS_READ,
    ),
  );

  const hasEventsAccess = computed(() =>
    hasResourceAccess(
      FleetRoleResourceAccessEnum.FLEET_MANAGE,
      FleetRoleResourceAccessEnum.FLEET_EVENTS_MANAGE,
      FleetRoleResourceAccessEnum.FLEET_EVENTS_READ,
    ),
  );

  const showLogisticsNav = computed(
    () =>
      !!membership.value &&
      hasLogisticsAccess.value &&
      isFeatureEnabled(FeatureFlagName.FLEET_LOGISTICS) &&
      subscriptionSatisfied.value,
  );

  const showAlliesNav = computed(
    () =>
      !!membership.value &&
      hasAlliesAccess.value &&
      isFleetFeatureEnabled(toValue(fleet), FeatureFlagName.FLEET_ALLIES),
  );

  const showContractsNav = computed(
    () =>
      !!membership.value &&
      hasContractsAccess.value &&
      isFleetFeatureEnabled(toValue(fleet), FeatureFlagName.FLEET_CONTRACTS) &&
      subscriptionSatisfied.value,
  );

  const showEventsNav = computed(
    () =>
      !!membership.value &&
      (hasEventsAccess.value || hasMissionsAccess.value) &&
      isFleetFeatureEnabled(
        toValue(fleet),
        FeatureFlagName.FLEET_MISSION_BUILDER,
      ) &&
      subscriptionSatisfied.value,
  );

  // Missions are reached from the events page, but the events route only
  // admits event access, so a role that reads missions and nothing else lands
  // on NotAuthorized. It gets the same tab, pointed one page further in.
  const eventsNavRoute = computed(() =>
    hasEventsAccess.value ? "fleet-events" : "fleet-missions",
  );

  const showToursNav = computed(
    () =>
      !!membership.value &&
      isFleetFeatureEnabled(toValue(fleet), FeatureFlagName.TOUR_PAYOUTS) &&
      isFleetFeatureEnabled(toValue(fleet), FeatureFlagName.FLEET_TOURS) &&
      subscriptionSatisfied.value,
  );

  const contractsNavActive = computed(() =>
    String(route.name ?? "").startsWith("fleet-contract"),
  );

  // Missions and the calendar live under the events tab, and the mission
  // builder's own routes are nested deep enough that the name check alone
  // misses the ones reached by path.
  const eventsNavActive = computed(() => {
    const name = String(route.name ?? "");
    if (name.startsWith("fleet-event") || name.startsWith("fleet-mission")) {
      return true;
    }
    if (name === "fleet-calendar") return true;

    const path = route.path || "";
    return /\/fleets\/[^/]+\/(events|missions|calendar)/.test(path);
  });

  return {
    membership,
    showLogisticsNav,
    showAlliesNav,
    showContractsNav,
    showEventsNav,
    eventsNavRoute,
    showToursNav,
    contractsNavActive,
    eventsNavActive,
  };
};
