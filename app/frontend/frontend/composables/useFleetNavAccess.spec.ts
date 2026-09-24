import { beforeEach, describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import { FeatureFlagName } from "@/services/fyApi/models/FeatureFlagName";
import { FleetRoleResourceAccessEnum } from "@/services/fyApi/models/FleetRoleResourceAccessEnum";

const route = ref<{ name: string; params: object; path: string }>({
  name: "fleet",
  params: { slug: "merc" },
  path: "/fleets/merc",
});

const membership = ref<object | undefined>(undefined);

const viewerFeatures = ref<string[]>([]);

vi.mock("vue-router", () => ({
  useRoute: () => route.value,
}));

vi.mock("@/frontend/stores/session", () => ({
  useSessionStore: () => ({ isAuthenticated: true }),
}));

vi.mock("@/services/fyApi", async () => {
  const flags = await vi.importActual(
    "@/services/fyApi/models/FeatureFlagName.ts",
  );
  const access = await vi.importActual(
    "@/services/fyApi/models/FleetRoleResourceAccessEnum.ts",
  );

  return {
    ...flags,
    ...access,
    useFleetMembership: () => ({ data: membership }),
    useFeatures: () => ({ data: viewerFeatures }),
    getFeaturesQueryOptions: () => ({}),
  };
});

vi.mock("@/shared/composables/usePrefetch", () => ({
  usePrefetch: () => ({ fetchData: () => undefined }),
}));

const { useFleetNavAccess } = await import("./useFleetNavAccess");

const fleetWith = (...features: string[]) => ({
  features,
  publicFleet: false,
});

const publicFleetWith = (...features: string[]) => ({
  features,
  publicFleet: true,
});

const memberWith = (...resourceAccess: string[]) => ({
  fleetRole: { resourceAccess },
  capabilities: {},
});

const memberAbleTo = (...capabilities: string[]) => ({
  fleetRole: { resourceAccess: [] },
  capabilities: Object.fromEntries(capabilities.map((key) => [key, true])),
});

describe("useFleetNavAccess", () => {
  beforeEach(() => {
    route.value = { name: "fleet", params: { slug: "merc" }, path: "/merc" };
    membership.value = undefined;
    viewerFeatures.value = [];
  });

  it("hides contracts from someone who is not a member", () => {
    const fleet = fleetWith(FeatureFlagName.FLEET_CONTRACTS);

    expect(useFleetNavAccess(fleet).showContractsNav.value).toBe(false);
  });

  it("hides contracts from a member whose role cannot read them", () => {
    membership.value = memberWith(
      FleetRoleResourceAccessEnum.FLEET_MEMBERSHIPS_READ,
    );

    const fleet = fleetWith(FeatureFlagName.FLEET_CONTRACTS);

    expect(useFleetNavAccess(fleet).showContractsNav.value).toBe(false);
  });

  it("hides contracts while the fleet has no contracts flag", () => {
    membership.value = memberWith(
      FleetRoleResourceAccessEnum.FLEET_CONTRACTS_READ,
    );

    expect(useFleetNavAccess(fleetWith()).showContractsNav.value).toBe(false);
  });

  it("shows contracts to a member who can read them", () => {
    membership.value = memberWith(
      FleetRoleResourceAccessEnum.FLEET_CONTRACTS_READ,
    );

    const fleet = fleetWith(FeatureFlagName.FLEET_CONTRACTS);

    expect(useFleetNavAccess(fleet).showContractsNav.value).toBe(true);
  });

  // Missions and events share the one tab, so either access opens it.
  it("shows events to a member who can only read missions", () => {
    membership.value = memberWith(
      FleetRoleResourceAccessEnum.FLEET_MISSIONS_READ,
    );

    const fleet = fleetWith(FeatureFlagName.FLEET_MISSION_BUILDER);

    expect(useFleetNavAccess(fleet).showEventsNav.value).toBe(true);
  });

  // The events route admits event access only, so the tab that mission-only
  // access opens has to lead somewhere that access can be used.
  it("sends a mission-only member to the missions list", () => {
    membership.value = memberWith(
      FleetRoleResourceAccessEnum.FLEET_MISSIONS_READ,
    );

    const fleet = fleetWith(FeatureFlagName.FLEET_MISSION_BUILDER);

    expect(useFleetNavAccess(fleet).eventsNavRoute.value).toBe(
      "fleet-missions",
    );
  });

  it("sends a member with event access to the events list", () => {
    membership.value = memberWith(
      FleetRoleResourceAccessEnum.FLEET_EVENTS_READ,
      FleetRoleResourceAccessEnum.FLEET_MISSIONS_READ,
    );

    const fleet = fleetWith(FeatureFlagName.FLEET_MISSION_BUILDER);

    expect(useFleetNavAccess(fleet).eventsNavRoute.value).toBe("fleet-events");
  });

  it("reads the flag from the viewer as well as the fleet", () => {
    membership.value = memberWith(FleetRoleResourceAccessEnum.FLEET_MANAGE);
    viewerFeatures.value = [FeatureFlagName.FLEET_MISSION_BUILDER];

    expect(useFleetNavAccess(fleetWith()).showEventsNav.value).toBe(true);
  });

  it("marks the events tab active on a mission route", () => {
    route.value = {
      name: "fleet-mission",
      params: { slug: "merc" },
      path: "/fleets/merc/missions/rescue",
    };

    expect(useFleetNavAccess(undefined).eventsNavActive.value).toBe(true);
  });

  it("marks the events tab active on the calendar", () => {
    route.value = {
      name: "fleet-calendar",
      params: { slug: "merc" },
      path: "/fleets/merc/calendar",
    };

    expect(useFleetNavAccess(undefined).eventsNavActive.value).toBe(true);
  });

  // No feature flag and no subscription behind this one: the privilege is the
  // only gate, so a capability is the whole test.
  it("hides blueprints from someone who is not a member", () => {
    expect(useFleetNavAccess(fleetWith()).showBlueprintsNav.value).toBe(false);
  });

  it("hides blueprints from a member whose role cannot read them", () => {
    membership.value = memberAbleTo("readVehicles");

    expect(useFleetNavAccess(fleetWith()).showBlueprintsNav.value).toBe(false);
  });

  it("shows blueprints to a member whose role can read them", () => {
    membership.value = memberAbleTo("readBlueprints");

    expect(useFleetNavAccess(fleetWith()).showBlueprintsNav.value).toBe(true);
  });

  // The group is a row that opens on a list; with nothing under it, it opens
  // on nothing.
  it("hides the assets group from a stranger", () => {
    expect(useFleetNavAccess(fleetWith()).showAssetsNav.value).toBe(false);
  });

  // Ships is the one tab somebody outside the fleet can reach, and it stays
  // top-level rather than joining the group for exactly that reason.
  it("shows a stranger at a public fleet the ships tab and no group", () => {
    const tab = useFleetNavAccess(publicFleetWith());

    expect([tab.showShipsNav.value, tab.showAssetsNav.value]).toEqual([
      true,
      false,
    ]);
  });

  it("hides the assets group from a member who can read neither child", () => {
    membership.value = memberWith(
      FleetRoleResourceAccessEnum.FLEET_MEMBERSHIPS_READ,
    );

    expect(useFleetNavAccess(fleetWith()).showAssetsNav.value).toBe(false);
  });

  it("shows the assets group once one of its two is on", () => {
    membership.value = memberAbleTo("readBlueprints");

    expect(useFleetNavAccess(fleetWith()).showAssetsNav.value).toBe(true);
  });

  // Ships is not one of its children, so the fleetchart is not its route.
  it("leaves the assets group inactive on the ships routes", () => {
    route.value = {
      name: "fleet-fleetchart",
      params: { slug: "merc" },
      path: "/fleets/merc/fleetchart",
    };

    const tab = useFleetNavAccess(fleetWith());

    expect([tab.shipsNavActive.value, tab.assetsNavActive.value]).toEqual([
      true,
      false,
    ]);
  });

  // Closed, the parent is the only thing that can say where the reader is.
  it("marks the assets group active on a child's route", () => {
    route.value = {
      name: "fleet-blueprints",
      params: { slug: "merc" },
      path: "/fleets/merc/blueprints",
    };

    const tab = useFleetNavAccess(fleetWith());

    expect([tab.assetsNavActive.value, tab.contractsNavActive.value]).toEqual([
      true,
      false,
    ]);
  });

  // Tours lost its own row -- it is reached from the events page now -- so the
  // events tab is what has to stay lit in there.
  it("marks the events tab active on a tour route", () => {
    route.value = {
      name: "fleet-tours",
      params: { slug: "merc" },
      path: "/fleets/merc/tours",
    };

    const tab = useFleetNavAccess(fleetWith());

    expect([tab.eventsNavActive.value, tab.assetsNavActive.value]).toEqual([
      true,
      false,
    ]);
  });

  it("marks the events tab active on a single tour", () => {
    route.value = {
      name: "fleet-tour",
      params: { slug: "merc" },
      path: "/fleets/merc/tours/spring-run",
    };

    expect(useFleetNavAccess(fleetWith()).eventsNavActive.value).toBe(true);
  });

  it("hides squadrons from someone who is not a member", () => {
    const fleet = fleetWith(FeatureFlagName.FLEET_SQUADRONS);

    expect(useFleetNavAccess(fleet).showSquadronsNav.value).toBe(false);
  });

  it("hides squadrons from a member whose role cannot read them", () => {
    membership.value = memberAbleTo("readMembers");

    const fleet = fleetWith(FeatureFlagName.FLEET_SQUADRONS);

    expect(useFleetNavAccess(fleet).showSquadronsNav.value).toBe(false);
  });

  it("hides squadrons while the fleet has no squadrons flag", () => {
    membership.value = memberAbleTo("readSquadrons");

    expect(useFleetNavAccess(fleetWith()).showSquadronsNav.value).toBe(false);
  });

  it("shows squadrons to a member who may read them in a flagged fleet", () => {
    membership.value = memberAbleTo("readSquadrons");

    const fleet = fleetWith(FeatureFlagName.FLEET_SQUADRONS);

    expect(useFleetNavAccess(fleet).showSquadronsNav.value).toBe(true);
  });

  // The detail route is `fleet-squadron`, the list `fleet-squadrons`; one
  // prefix has to light the tab on both.
  it("marks the squadrons tab active on a squadron detail route", () => {
    route.value = {
      name: "fleet-squadron",
      params: { slug: "merc", squadron: "combat-wing" },
      path: "/fleets/merc/squadrons/combat-wing",
    };

    expect(useFleetNavAccess(undefined).squadronsNavActive.value).toBe(true);
  });

  it("marks the contracts tab active on a contract detail route", () => {
    route.value = {
      name: "fleet-contract-edit",
      params: { slug: "merc" },
      path: "/fleets/merc/contracts/1/edit",
    };

    const tab = useFleetNavAccess(undefined);

    expect([tab.contractsNavActive.value, tab.eventsNavActive.value]).toEqual([
      true,
      false,
    ]);
  });
});
