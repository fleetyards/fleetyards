import { describe, expect, it, vi } from "vitest";
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

vi.mock("@/services/fyApi/services/fleets/fleets", () => ({
  useMyFleets: () => ({ data: fleets }),
}));

vi.mock("@/services/fyApi/services/fleet-members/fleet-members", () => ({
  fleetMembers: vi.fn(),
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

    expect(targets.value.map((target) => [target.kind, target.payload])).toEqual([
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
});
