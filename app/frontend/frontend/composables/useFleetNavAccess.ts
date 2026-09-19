import { type MaybeRefOrGetter } from "vue";
import {
  useFleetMembership as useFleetMembershipQuery,
  FeatureFlagName,
  FleetRoleResourceAccessEnum,
  type Fleet,
} from "@/services/fyApi";
import { useSessionStore } from "@/frontend/stores/session";
import { useFeatures } from "@/frontend/composables/useFeatures";

export const useFleetNavAccess = (
  fleet: MaybeRefOrGetter<Pick<Fleet, "features"> | undefined>,
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

  const hasLogisticsAccess = computed(
    () => membership.value?.capabilities?.readInventories ?? false,
  );

  const hasAlliesAccess = computed(
    () => membership.value?.capabilities?.readAllies ?? false,
  );

  const hasBlueprintsAccess = computed(
    () => membership.value?.capabilities?.readBlueprints ?? false,
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
      isFeatureEnabled(FeatureFlagName.FLEET_LOGISTICS),
  );

  // No feature flag and no subscription: the fleet's list of what its members
  // can craft ships with the catalogue, free for every fleet, like the ships
  // tab. The privilege is the only gate.
  const showBlueprintsNav = computed(
    () => !!membership.value && hasBlueprintsAccess.value,
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
      isFleetFeatureEnabled(toValue(fleet), FeatureFlagName.FLEET_CONTRACTS),
  );

  const showEventsNav = computed(
    () =>
      !!membership.value &&
      (hasEventsAccess.value || hasMissionsAccess.value) &&
      isFleetFeatureEnabled(
        toValue(fleet),
        FeatureFlagName.FLEET_MISSION_BUILDER,
      ),
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
      isFleetFeatureEnabled(toValue(fleet), FeatureFlagName.FLEET_TOURS),
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
    showBlueprintsNav,
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
