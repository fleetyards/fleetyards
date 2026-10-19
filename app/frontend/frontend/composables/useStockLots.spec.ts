import { describe, expect, it, vi } from "vitest";
import {
  lotEntry,
  usePositionLots,
  useStockLots,
  type StockLot,
} from "./useStockLots";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

const lot = (overrides: Partial<StockLot> = {}): StockLot => ({
  id: "pos-1",
  name: "Quantanium",
  category: "commodity",
  unit: "scu",
  netQuantity: 10,
  ...overrides,
});

describe("useStockLots", () => {
  it("keys a lot by what it is, not by where it sits in the list", () => {
    const lots = ref([lot({ quality: 800 }), lot({ quality: null })]);
    const { lotOptions, lotAt } = useStockLots(lots);

    const ungraded = lotOptions.value[1].value as string;

    lots.value = [lot({ quality: null }), lot({ quality: 800 })];

    expect(lotAt(ungraded)?.quality).toBeNull();
  });

  // A cleared select reports null as often as undefined.
  it("resolves no lot for a cleared select", () => {
    const { lotAt } = useStockLots(ref([lot()]));

    expect(lotAt(null)).toBeUndefined();
    expect(lotAt("")).toBeUndefined();
  });

  it("offers each position once for a deposit", () => {
    const { positionOptions } = useStockLots(
      ref([lot({ quality: 800 }), lot({ quality: 200 })]),
    );

    expect(positionOptions.value).toHaveLength(1);
  });
});

describe("lotEntry", () => {
  it("carries nothing for a lot that was not crafted", () => {
    expect(lotEntry(lot({ quality: 800 }))).toEqual({});
  });

  it("carries a crafted lot's part and grades", () => {
    expect(
      lotEntry(
        lot({
          category: "component",
          item: { id: "bulwark", type: "Component" },
          crafted: {
            blueprint: { id: "bp-1", name: "Bulwark", slug: "bulwark" },
            qualities: { 1: 750 },
          },
        }),
      ),
    ).toMatchObject({
      item: { type: "Component", id: "bulwark" },
      crafted: { blueprintId: "bp-1", qualities: { 1: 750 } },
    });
  });
});

describe("usePositionLots", () => {
  const crafted = {
    blueprint: { id: "bp-1", name: "Bulwark Blueprint", slug: "bulwark-bp" },
    qualities: { 1: 750 },
  };

  it("lists every lot of the position, and only those", () => {
    const { lots, showLots } = usePositionLots(
      ref([
        lot({ quality: 0 }),
        lot({ quality: 0, crafted }),
        lot({ id: "pos-2", name: "Titanium" }),
      ]),
      ref("pos-1"),
    );

    expect(lots.value).toHaveLength(2);
    expect(showLots.value).toBe(true);
  });

  it("lists a lone crafted lot", () => {
    const { showLots } = usePositionLots(ref([lot({ crafted })]), ref("pos-1"));

    expect(showLots.value).toBe(true);
  });

  // The position's own total already says everything a single plain lot would.
  it("lists nothing for a single plain lot", () => {
    const { showLots } = usePositionLots(ref([lot()]), ref("pos-1"));

    expect(showLots.value).toBe(false);
  });
});
