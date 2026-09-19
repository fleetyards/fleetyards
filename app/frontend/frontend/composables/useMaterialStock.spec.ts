import { describe, expect, it, vi } from "vitest";
import { ref } from "vue";

const hangarStock = ref<Record<string, unknown>[]>([]);

vi.mock("pinia", () => ({
  storeToRefs: () => ({ isAuthenticated: ref(true) }),
}));

vi.mock("@/frontend/stores/session", () => ({ useSessionStore: () => ({}) }));

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFeatureEnabled: () => true }),
}));

vi.mock("@tanstack/vue-query", () => ({
  useQueries: () => ref([]),
}));

vi.mock("@/services/fyApi", () => ({
  useHangarAllInventoryStock: () => ({ data: hangarStock }),
  useMyFleets: () => ({ data: ref([]) }),
  getFleetAllInventoryStockQueryOptions: () => ({}),
  FeatureFlagName: { HANGAR_INVENTORIES: "a", FLEET_LOGISTICS: "b" },
}));

const { useMaterialStock } = await import("./useMaterialStock");

const GEM = "commodity-1";

const position = (unit: string, netQuantity: number) => ({
  id: `position-${unit}-${netQuantity}`,
  name: "Hadanite",
  unit,
  netQuantity,
  item: { id: GEM },
  qualityMin: 500,
  qualityMax: 500,
});

/** How many of the reader's own holdings could fill a slot on these terms. */
const ownCount = (
  holdings: ReturnType<typeof position>[],
  needed: number | null,
  costType: string,
  pieceVolume?: number | null,
) => {
  hangarStock.value = holdings;

  return useMaterialStock().forCommodity(GEM, needed, costType, pieceVolume).own
    .length;
};

describe("useMaterialStock#forCommodity", () => {
  it("compares a bulk cost against a holding in the same unit", () => {
    expect(ownCount([position("scu", 210)], 100, "resource")).toBe(1);
    expect(ownCount([position("scu", 50)], 100, "resource")).toBe(0);
  });

  // The whole point of the counted work: a recipe asking for 170 pieces can
  // now be answered by a holding recorded in pieces.
  it("compares a counted cost against a holding in pieces", () => {
    expect(ownCount([position("units", 200)], 170, "item")).toBe(1);
    expect(ownCount([position("units", 12)], 170, "item")).toBe(0);
  });

  // 210 SCU of Hadanite at 0.001 SCU a piece is 210,000 of them, which is
  // comfortably more than the 170 the recipe asks for.
  it("converts an SCU holding into pieces to answer a counted cost", () => {
    expect(ownCount([position("scu", 210)], 170, "item", 0.001)).toBe(1);
    expect(ownCount([position("scu", 0.05)], 170, "item", 0.001)).toBe(0);
  });

  it("converts a holding in pieces into SCU to answer a bulk cost", () => {
    expect(ownCount([position("units", 5000)], 2, "resource", 0.001)).toBe(1);
    expect(ownCount([position("units", 100)], 2, "resource", 0.001)).toBe(0);
  });

  // No rate, so there is no comparison to make -- and inventing one is what
  // this deliberately does not do. The holding is shown as it stands.
  it("shows a holding it cannot convert rather than judging it", () => {
    expect(ownCount([position("units", 1)], 9999, "resource")).toBe(1);
    expect(ownCount([position("scu", 1)], 9999, "item", null)).toBe(1);
  });

  // `unit` is optional on a stock row, and a unit we cannot read is not a
  // licence to guess -- converting it as though it were pieces would multiply
  // an unknown into a sufficiency claim.
  it("refuses to convert a holding whose unit it does not recognise", () => {
    const unknown = { ...position("scu", 1), unit: "crates" };

    expect(
      useMaterialStock().forCommodity(GEM, 9999, "item", 0.001).own.length,
    ).toBe(0);

    hangarStock.value = [unknown];

    expect(
      useMaterialStock().forCommodity(GEM, 9999, "item", 0.001).own.length,
    ).toBe(1);
  });

  // A slot with no stated amount asks for nothing in particular.
  it("keeps every holding where the slot names no amount", () => {
    expect(ownCount([position("scu", 1)], null, "item", 0.001)).toBe(1);
  });
});
