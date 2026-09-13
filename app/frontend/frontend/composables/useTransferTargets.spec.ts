import { describe, expect, it, vi } from "vitest";
import { computed, ref } from "vue";
import type { Fleet, HangarInventory } from "@/services/fyApi";

const inventories = ref<{ items: Partial<HangarInventory>[] } | undefined>();
const fleets = ref<Partial<Fleet>[] | undefined>();

// The two query hooks are mocked at their own modules rather than at the
// barrel: mocking `@/services/fyApi` replaces the re-export that carries
// `FeatureFlagName`, and the composable reads the enum from it.
vi.mock(
  "@/services/fyApi/services/hangar-inventories/hangar-inventories",
  () => ({
    useHangarInventories: () => ({ data: inventories }),
  }),
);

vi.mock("./useKnownTransferParties", () => ({
  useKnownTransferParties: () => ({
    people: computed(() => []),
    fleetTargets: computed(() =>
      (fleets.value ?? [])
        .filter(
          (fleet) =>
            fleet.features?.includes("inventory_transfers") &&
            fleet.features?.includes("fleet_logistics"),
        )
        .map((fleet) => ({
          value: `fleet:${fleet.slug}`,
          label: fleet.name,
          needsAnswer: true,
          payload: { recipientFleetSlug: fleet.slug },
        })),
    ),
  }),
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
    inventories.value = {
      items: [
        { id: "src", name: "Caterpillar" },
        { id: "other", name: "Locker" },
      ],
    };
    fleets.value = [];

    const { targets } = useTransferTargets(() => ({ id: "src" }));

    expect(targets.value.map((target) => target.payload)).toEqual([
      { inventoryId: "other" },
    ]);
    expect(targets.value[0].needsAnswer).toBe(false);
  });

  // A fleet whose logistics are switched off cannot receive, and offering it
  // would mean finding out by being refused. The filtering itself lives in
  // `useKnownTransferParties`; this checks the list it feeds reaches the caller.
  it("drops a fleet that is missing either flag", () => {
    inventories.value = { items: [] };
    fleets.value = [
      fleet(),
      fleet({ slug: "no-transfers", features: ["fleet_logistics"] }),
      fleet({ slug: "no-logistics", features: ["inventory_transfers"] }),
      fleet({ slug: "nothing", features: [] }),
    ];

    const { targets } = useTransferTargets(() => undefined);

    expect(targets.value.map((target) => target.payload)).toEqual([
      { recipientFleetSlug: "crew" },
    ]);
    expect(targets.value[0].needsAnswer).toBe(true);
  });
});
