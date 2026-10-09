import { beforeEach, describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import { FeatureFlagName } from "@/services/fyApi/models/FeatureFlagName";
import { FleetMembershipStatusEnum } from "@/services/fyApi/models/FleetMembershipStatusEnum";
import type { Fleet, FleetMember } from "@/services/fyApi";

const viewerFeatures = ref<string[]>([]);

vi.mock("@/services/fyApi", async () => {
  const flags = await vi.importActual(
    "@/services/fyApi/models/FeatureFlagName.ts",
  );
  const status = await vi.importActual(
    "@/services/fyApi/models/FleetMembershipStatusEnum.ts",
  );

  return {
    ...flags,
    ...status,
    useFeatures: () => ({ data: viewerFeatures }),
    getFeaturesQueryOptions: () => ({}),
  };
});

vi.mock("@/shared/composables/usePrefetch", () => ({
  usePrefetch: () => ({ fetchData: () => undefined }),
}));

const { useFleetDashboardAccess } = await import("./useFleetDashboardAccess");

const ALL_FEATURES = [
  FeatureFlagName.FLEET_MISSION_BUILDER,
  FeatureFlagName.FLEET_CONTRACTS,
  FeatureFlagName.FLEET_LOGISTICS,
];

const fleetWith = (features: string[] = ALL_FEATURES, subscribed = true) =>
  ({ features, subscribed }) as unknown as Fleet;

const member = (
  capabilities: string[] = [],
  status: string = FleetMembershipStatusEnum.ACCEPTED,
) =>
  ({
    status,
    capabilities: Object.fromEntries(capabilities.map((key) => [key, true])),
  }) as unknown as FleetMember;

const READS = ["readEvents", "readContracts", "readMembers", "readInventories"];

// What the member preset carries: reading the fleet's modules, answering none.
const plainMember = () => member(READS);

const officer = () => member([...READS, "updateMembers", "updateInventories"]);

describe("useFleetDashboardAccess", () => {
  beforeEach(() => {
    viewerFeatures.value = [];
  });

  it("shows a plain member the fleet's modules but no queue to answer", () => {
    const access = useFleetDashboardAccess(fleetWith(), plainMember());

    expect(access.showEvents.value).toBe(true);
    expect(access.showContracts.value).toBe(true);
    expect(access.showInventory.value).toBe(true);
    expect(access.showNewMembers.value).toBe(true);
    expect(access.showActionQueue.value).toBe(false);
  });

  it("gives an officer the queue for join requests and transfers", () => {
    const access = useFleetDashboardAccess(fleetWith(), officer());

    expect(access.showActionQueue.value).toBe(true);
    expect(access.canAnswerJoinRequests.value).toBe(true);
    expect(access.canAnswerTransfers.value).toBe(true);
  });

  it("lists no join requests to a role that may answer but not read them", () => {
    const access = useFleetDashboardAccess(
      fleetWith(),
      member(["updateMembers"]),
    );

    expect(access.canAnswerJoinRequests.value).toBe(false);
    expect(access.showActionQueue.value).toBe(false);
  });

  it("keeps a module the role cannot read off the dashboard", () => {
    const access = useFleetDashboardAccess(fleetWith(), member(["readEvents"]));

    expect(access.showEvents.value).toBe(true);
    expect(access.showContracts.value).toBe(false);
    expect(access.showInventory.value).toBe(false);
    expect(access.showNewMembers.value).toBe(false);
  });

  it("keeps a module that is not rolled out off the dashboard", () => {
    const access = useFleetDashboardAccess(
      fleetWith([FeatureFlagName.FLEET_MISSION_BUILDER]),
      officer(),
    );

    expect(access.showEvents.value).toBe(true);
    expect(access.showContracts.value).toBe(false);
    expect(access.showInventory.value).toBe(false);
    expect(access.canAnswerTransfers.value).toBe(false);
    expect(access.canAnswerJoinRequests.value).toBe(true);
  });

  // The premium modules answer 403 to an unsubscribed fleet once enforcement
  // is rolled out, so their panels go; the members panel is free.
  it("drops the premium modules for an unsubscribed fleet", () => {
    const access = useFleetDashboardAccess(
      fleetWith([...ALL_FEATURES, FeatureFlagName.FLEET_SUBSCRIPTIONS], false),
      officer(),
    );

    expect(access.showEvents.value).toBe(false);
    expect(access.showContracts.value).toBe(false);
    expect(access.showInventory.value).toBe(false);
    expect(access.showNewMembers.value).toBe(true);
  });

  it("shows nothing to somebody whose membership is not accepted", () => {
    const access = useFleetDashboardAccess(
      fleetWith(),
      member(
        [...READS, "updateMembers", "updateInventories"],
        FleetMembershipStatusEnum.REQUESTED,
      ),
    );

    expect(access.isMember.value).toBe(false);
    expect(access.showEvents.value).toBe(false);
    expect(access.showNewMembers.value).toBe(false);
    expect(access.showActionQueue.value).toBe(false);
  });
});
