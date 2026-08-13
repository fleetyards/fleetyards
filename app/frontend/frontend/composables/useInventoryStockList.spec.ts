import { describe, expect, it, vi } from "vitest";
import { ref } from "vue";

const routeQuery = ref<Record<string, string>>({});

vi.mock("vue-router", () => ({
  useRoute: () => ({
    get query() {
      return routeQuery.value;
    },
  }),
}));

const { useInventoryStockList } = await import("./useInventoryStockList");

type StockItem = {
  name: string;
  category: string;
  unit: string;
  quality?: number;
  qualityMin?: number;
  qualityMax?: number;
  netQuantity: number;
};

const stock = (
  attributes: Partial<StockItem> & { name: string },
): StockItem => ({
  category: "commodity",
  unit: "scu",
  netQuantity: 10,
  ...attributes,
});

const namesFor = (items: StockItem[], query: Record<string, string> = {}) => {
  routeQuery.value = query;

  const { stockRecords } = useInventoryStockList(ref(items));

  return stockRecords.value.map((record) => record.name);
};

describe("useInventoryStockList", () => {
  it("keeps every position when nothing is filtered", () => {
    expect(
      namesFor([stock({ name: "Quantanium" }), stock({ name: "Titanium" })]),
    ).toEqual(["Quantanium", "Titanium"]);
  });

  it("filters by name and category", () => {
    const items = [
      stock({ name: "Quantanium" }),
      stock({ name: "Titanium", category: "component" }),
    ];

    expect(namesFor(items, { nameCont: "tita" })).toEqual(["Titanium"]);
    expect(namesFor(items, { categoryEq: "component" })).toEqual(["Titanium"]);
  });

  it("compares a single quality against both bounds", () => {
    const items = [
      stock({ name: "Worn", quality: 200 }),
      stock({ name: "Fresh", quality: 900 }),
    ];

    expect(namesFor(items, { qualityGteq: "500" })).toEqual(["Fresh"]);
    expect(namesFor(items, { qualityLteq: "500" })).toEqual(["Worn"]);
  });

  // Merged inventories report a range rather than one quality, so a position
  // counts as matching whenever its range reaches into the requested window.
  it("keeps a quality range that reaches into the filter", () => {
    const items = [
      stock({ name: "Mixed", qualityMin: 100, qualityMax: 900 }),
      stock({ name: "Poor", qualityMin: 50, qualityMax: 200 }),
    ];

    expect(namesFor(items, { qualityGteq: "500" })).toEqual(["Mixed"]);
    expect(namesFor(items, { qualityLteq: "150" })).toEqual(["Mixed", "Poor"]);
    expect(namesFor(items, { qualityGteq: "300", qualityLteq: "400" })).toEqual(
      ["Mixed"],
    );
  });

  it("does not drop ranged positions when only a minimum is asked for", () => {
    const items = [stock({ name: "Mixed", qualityMin: 0, qualityMax: 1000 })];

    expect(namesFor(items, { qualityGteq: "1" })).toEqual(["Mixed"]);
  });
});
