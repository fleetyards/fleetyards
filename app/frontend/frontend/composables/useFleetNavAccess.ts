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
  fleet: MaybeRefOrGetter<Pick<Fleet, "features" | "publicFleet"> | undefined>,
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

  const hasBlueprintsAccess = computed(
    () => membership.value?.capabilities?.readBlueprints ?? false,
  );

  const hasSquadronsAccess = computed(
    () => membership.value?.capabilities?.readSquadrons ?? false,
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

  // The one tab somebody outside the fleet can reach, and the reason it stays
  // top-level rather than joining the Assets group.
  const showShipsNav = computed(
    () => !!membership.value || !!toValue(fleet)?.publicFleet,
  );

  const showSquadronsNav = computed(
    () =>
      !!membership.value &&
      hasSquadronsAccess.value &&
      isFleetFeatureEnabled(toValue(fleet), FeatureFlagName.FLEET_SQUADRONS),
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

  const toursNavActive = computed(() =>
    String(route.name ?? "").startsWith("fleet-tour"),
  );

  const logisticsNavActive = computed(() =>
    String(route.name ?? "").startsWith("fleet-logistics"),
  );

  const blueprintsNavActive = computed(
    () => String(route.name ?? "") === "fleet-blueprints",
  );

  const shipsNavActive = computed(() =>
    ["fleet-ships", "fleet-fleetchart"].includes(String(route.name ?? "")),
  );

  const squadronsNavActive = computed(() =>
    String(route.name ?? "").startsWith("fleet-squadron"),
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

    // Tours has no tab of its own -- it is reached from the events page, the
    // way missions already are -- so this is the tab that has to stay lit
    // while a reader is in there.
    if (name.startsWith("fleet-tour")) return true;

    const path = route.path || "";
    return /\/fleets\/[^/]+\/(events|missions|calendar|tours)/.test(path);
  });

  // A parent with nothing under it is a row that opens on an empty list, so
  // each group is present only when at least one of its children is. The
  // children keep the guards they already had -- grouping them changes where
  // they are, not who may see them.
  //
  // Ships is deliberately not in here. It is the one tab somebody outside the
  // fleet can reach, and a public surface behind a parent is a click added for
  // the reader least able to guess what the parent holds.
  const showAssetsNav = computed(
    () => showBlueprintsNav.value || showLogisticsNav.value,
  );

  // The parent lights up on either of its children's routes, which is what
  // keeps the group findable once it is closed.
  const assetsNavActive = computed(
    () => blueprintsNavActive.value || logisticsNavActive.value,
  );

  return {
    membership,
    showAssetsNav,
    assetsNavActive,
    showShipsNav,
    shipsNavActive,
    showBlueprintsNav,
    blueprintsNavActive,
    showLogisticsNav,
    logisticsNavActive,
    showSquadronsNav,
    squadronsNavActive,
    showContractsNav,
    showEventsNav,
    eventsNavRoute,
    showToursNav,
    toursNavActive,
    contractsNavActive,
    eventsNavActive,
  };
};
