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

const fleetWith = (...features: string[]) => ({ features });

const memberWith = (...resourceAccess: string[]) => ({
  fleetRole: { resourceAccess },
  capabilities: {},
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
  // The twelve cases above pass a fleet with no `subscribed` at all and none of
  // them changed when the gate landed: while `fleet_subscriptions` is off for a
  // fleet, entitlement is never asked about and the tabs are what they always
  // were. That is the whole of D16 as the nav sees it.
  describe("the subscription gate", () => {
    const premiumFleet = (...extra: string[]) =>
      fleetWith(
        FeatureFlagName.FLEET_CONTRACTS,
        FeatureFlagName.FLEET_MISSION_BUILDER,
        FeatureFlagName.FLEET_TOURS,
        FeatureFlagName.TOUR_PAYOUTS,
        ...extra,
      );

    const premiumTabs = (fleet: {
      features: string[];
      subscribed?: boolean;
    }) => {
      const tabs = useFleetNavAccess(fleet);

      return [
        tabs.showContractsNav.value,
        tabs.showEventsNav.value,
        tabs.showToursNav.value,
        tabs.showLogisticsNav.value,
      ];
    };

    beforeEach(() => {
      membership.value = {
        fleetRole: {
          resourceAccess: [FleetRoleResourceAccessEnum.FLEET_MANAGE],
        },
        capabilities: { readInventories: true, readAllies: true },
      };
      viewerFeatures.value = [FeatureFlagName.FLEET_LOGISTICS];
    });

    it("leaves every tab alone while enforcement is not rolled out", () => {
      expect(premiumTabs(premiumFleet())).toEqual([true, true, true, true]);
    });

    it("hides all four from an unsubscribed fleet once it is rolled out", () => {
      const fleet = {
        ...premiumFleet(FeatureFlagName.FLEET_SUBSCRIPTIONS),
        subscribed: false,
      };

      expect(premiumTabs(fleet)).toEqual([false, false, false, false]);
    });

    it("shows all four to a subscribed fleet", () => {
      const fleet = {
        ...premiumFleet(FeatureFlagName.FLEET_SUBSCRIPTIONS),
        subscribed: true,
      };

      expect(premiumTabs(fleet)).toEqual([true, true, true, true]);
    });

    // A fleet that is rolled out but whose payload predates the field must not
    // be read as subscribed -- the safe reading of a missing answer is "no".
    it("treats a missing subscribed field as unsubscribed", () => {
      const fleet = premiumFleet(FeatureFlagName.FLEET_SUBSCRIPTIONS);

      expect(premiumTabs(fleet)).toEqual([false, false, false, false]);
    });

    // Allies is not one of the four premium capabilities and is not sold.
    it("does not gate allies behind a subscription", () => {
      const fleet = {
        ...premiumFleet(
          FeatureFlagName.FLEET_SUBSCRIPTIONS,
          FeatureFlagName.FLEET_ALLIES,
        ),
        subscribed: false,
      };

      expect(useFleetNavAccess(fleet).showAlliesNav.value).toBe(true);
    });

    // Matches the backend's `Flipper.enabled?(flag, current_resource_owner,
    // fleet)`: enforcement rolled out to the viewer counts too, which is how it
    // gets tried on one account before any fleet is switched on.
    it("reads the enforcement flag from the viewer as well", () => {
      viewerFeatures.value = [
        FeatureFlagName.FLEET_LOGISTICS,
        FeatureFlagName.FLEET_SUBSCRIPTIONS,
      ];

      expect(premiumTabs({ ...premiumFleet(), subscribed: false })).toEqual([
        false,
        false,
        false,
        false,
      ]);
    });
  });
});
