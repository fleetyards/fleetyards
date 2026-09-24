import { beforeEach, describe, expect, it, vi } from "vitest";
import { computed, ref } from "vue";
import type { Fleet, HangarInventory } from "@/services/fyApi";

const hangarInventories = ref<
  { items: Partial<HangarInventory>[] } | undefined
>();
const fleetInventories = ref<
  { items: Partial<HangarInventory>[] } | undefined
>();
const fleets = ref<Partial<Fleet>[] | undefined>();
const members = ref<{ items: { username: string }[] }[]>([]);
const allies = ref<{ items: { fleet: { slug: string; name: string } }[] }>();
const friends = ref<{ items: { user: { username: string } }[] }>();
const enabledFeatures = ref<string[]>(["friends", "fleet_allies"]);
const contractDestinations = ref<Record<string, unknown>[] | undefined>();

vi.mock(
  "@/services/fyApi/services/hangar-inventories/hangar-inventories",
  () => ({
    useHangarInventories: () => ({ data: hangarInventories }),
  }),
);

vi.mock(
  "@/services/fyApi/services/fleet-inventories/fleet-inventories",
  () => ({
    useFleetInventories: () => ({ data: fleetInventories }),
  }),
);

vi.mock(
  "@/services/fyApi/services/hangar-inventory-transfers/hangar-inventory-transfers",
  () => ({
    useHangarContractDestinations: () => ({ data: contractDestinations }),
  }),
);

vi.mock("@/services/fyApi/services/fleets/fleets", () => ({
  useMyFleets: () => ({ data: fleets }),
}));

vi.mock("@/services/fyApi/services/fleet-members/fleet-members", () => ({
  fleetMembers: vi.fn(),
}));

vi.mock("@/services/fyApi/services/fleet-allies/fleet-allies", () => ({
  useFleetAllies: () => ({ data: allies }),
}));

vi.mock("@/services/fyApi/services/friends/friends", () => ({
  useFriends: () => ({ data: friends }),
}));

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({
    isFeatureEnabled: (feature: string) =>
      enabledFeatures.value.includes(feature),
  }),
}));

vi.mock("@tanstack/vue-query", () => ({
  useQueries: () => computed(() => members.value.map((data) => ({ data }))),
}));

vi.mock("@/frontend/stores/session", () => ({
  useSessionStore: () => ({ currentUser: { username: "me" } }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

const { useTransferTargets } = await import("./useTransferTargets");

const fleet = (overrides: Partial<Fleet> = {}): Partial<Fleet> => ({
  slug: "crew",
  name: "Crew",
  features: ["inventory_transfers", "fleet_logistics"],
  ...overrides,
});

describe("useTransferTargets", () => {
  beforeEach(() => {
    allies.value = undefined;
    friends.value = undefined;
    contractDestinations.value = undefined;
    enabledFeatures.value = ["friends", "fleet_allies"];
  });

  it("offers the holder's other inventories, never the one being emptied", () => {
    hangarInventories.value = {
      items: [
        { id: "src", name: "Caterpillar" },
        { id: "other", name: "Locker" },
      ],
    };
    fleets.value = [];
    members.value = [];

    const { targets } = useTransferTargets({ source: () => ({ id: "src" }) });

    expect(targets.value).toEqual([
      expect.objectContaining({
        kind: "inventory",
        payload: { inventoryId: "other" },
        needsAnswer: false,
      }),
    ]);
  });

  // Acting for a fleet offers both: the fleet's own inventories and the
  // reader's. A fleet issuing kit to one of its members is the sixth movement,
  // and the reader's own inventory is where that lands.
  it("offers the fleet's inventories and the reader's when acting for one", () => {
    hangarInventories.value = { items: [{ id: "mine", name: "Locker" }] };
    fleetInventories.value = {
      items: [
        { id: "src", name: "Depot" },
        { id: "forward", name: "Forward" },
      ],
    };
    fleets.value = [];
    members.value = [];

    const { targets } = useTransferTargets({
      source: () => ({ id: "src" }),
      fleetSlug: () => "crew",
    });

    expect(
      targets.value.map((target) => [target.kind, target.payload]),
    ).toEqual([
      ["inventory", { fleetInventoryId: "forward" }],
      ["mine", { inventoryId: "mine" }],
    ]);
    // Both are deposits the reader could make by hand, so neither waits.
    expect(targets.value.every((target) => !target.needsAnswer)).toBe(true);
    // No per-row suffix: the kind says whose it is.
    expect(targets.value.map((target) => target.label)).toEqual([
      "Forward",
      "Locker",
    ]);
  });

  // A fleet whose logistics are switched off cannot receive, and offering it
  // would mean finding out by being refused.
  it("drops a fleet that is missing either flag, and the one it acts for", () => {
    hangarInventories.value = { items: [] };
    fleetInventories.value = { items: [] };
    fleets.value = [
      fleet(),
      fleet({ slug: "self", name: "Self" }),
      fleet({ slug: "no-transfers", features: ["fleet_logistics"] }),
      fleet({ slug: "no-logistics", features: ["inventory_transfers"] }),
    ];
    members.value = [];

    const { targets } = useTransferTargets({
      source: () => undefined,
      fleetSlug: () => "self",
    });

    expect(targets.value.map((target) => target.payload)).toEqual([
      { recipientFleetSlug: "crew" },
    ]);
  });

  // A person is picked out of a fleet rather than from one flat list, so the
  // composable offers the fleets and the modal fetches that fleet's members.
  it("offers every fleet a person can be picked out of, flags or not", () => {
    hangarInventories.value = { items: [] };
    fleets.value = [
      fleet(),
      fleet({ slug: "quiet", name: "Quiet", features: [] }),
    ];
    members.value = [];

    const { memberFleets } = useTransferTargets({ source: () => undefined });

    expect(memberFleets.value).toEqual([
      { value: "crew", label: "Crew" },
      { value: "quiet", label: "Quiet" },
    ]);
  });

  // The extension point the composable's own comment describes: another way of
  // knowing somebody becomes another group to pick a person out of.
  it("offers friends as a group beside the fleets", () => {
    hangarInventories.value = { items: [] };
    fleets.value = [fleet()];
    friends.value = { items: [{ user: { username: "wingman" } }] };

    const { memberFleets, friendOptions } = useTransferTargets({
      source: () => undefined,
    });

    expect(memberFleets.value[0]).toEqual({
      value: "@friends",
      label: "labels.logistics.transferFromFriends",
    });
    expect(friendOptions.value).toEqual([
      { value: "user:wingman", label: "wingman" },
    ]);
  });

  it("offers no friends group when there are none", () => {
    hangarInventories.value = { items: [] };
    fleets.value = [fleet()];
    friends.value = { items: [] };

    const { memberFleets } = useTransferTargets({ source: () => undefined });

    expect(memberFleets.value).toEqual([{ value: "crew", label: "Crew" }]);
  });

  // An alliance is between the two organisations, not between one of them and
  // each member of the other.
  it("offers allied fleets only when acting for a fleet", () => {
    hangarInventories.value = { items: [] };
    fleetInventories.value = { items: [] };
    fleets.value = [];
    allies.value = { items: [{ fleet: { slug: "ally", name: "Ally" } }] };

    const asFleet = useTransferTargets({
      source: () => undefined,
      fleetSlug: () => "crew",
    });

    expect(asFleet.targets.value.map((target) => target.payload)).toEqual([
      { recipientFleetSlug: "ally" },
    ]);
    expect(asFleet.targets.value.every((target) => target.needsAnswer)).toBe(
      true,
    );

    // The same alliance data, read as a person rather than as the fleet: the
    // query is disabled there, so this asserts the shape rather than the fetch.
    allies.value = undefined;
    const asPerson = useTransferTargets({ source: () => undefined });

    expect(asPerson.targets.value).toEqual([]);
  });

  describe("contracts the reader works on", () => {
    const hangarTarget = {
      contractId: "c-1",
      contractTitle: "Buy titanium",
      contractSlug: "buy-titanium",
      fleetSlug: "crew",
      fleetName: "Crew",
      destination: {
        id: "locker",
        name: "Locker",
        slug: "locker",
        holder: "user",
      },
    };
    const fleetTarget = {
      contractId: "c-2",
      contractTitle: "Haul ore",
      contractSlug: "haul-ore",
      fleetSlug: "crew",
      fleetName: "Crew",
      destination: {
        id: "depot",
        name: "Depot",
        slug: "depot",
        holder: "fleet",
      },
    };

    beforeEach(() => {
      hangarInventories.value = { items: [] };
      fleets.value = [];
      members.value = [];
      enabledFeatures.value = ["fleet_contracts"];
      contractDestinations.value = [hangarTarget, fleetTarget];
    });

    // The author's inventory is named only together with its contract, which
    // is the one way the API resolves it as a target.
    it("offers each destination filed under its contract", () => {
      const { contractTargets } = useTransferTargets({
        source: () => undefined,
      });

      expect(
        contractTargets.value.map((target) => [target.kind, target.payload]),
      ).toEqual([
        ["contract", { inventoryId: "locker", contractId: "c-1" }],
        ["contract", { recipientFleetSlug: "crew", contractId: "c-2" }],
      ]);
      expect(contractTargets.value.every((target) => target.needsAnswer)).toBe(
        true,
      );
    });

    it("offers none when sending for a fleet", () => {
      const { contractTargets } = useTransferTargets({
        source: () => undefined,
        fleetSlug: () => "crew",
      });

      expect(contractTargets.value).toEqual([]);
    });

    // Contracts are switched on per fleet, and the endpoint filters by that.
    it("offers them without the reader's own contracts flag", () => {
      enabledFeatures.value = [];

      const { contractTargets } = useTransferTargets({
        source: () => undefined,
      });

      expect(contractTargets.value).toHaveLength(2);
    });
  });
});
