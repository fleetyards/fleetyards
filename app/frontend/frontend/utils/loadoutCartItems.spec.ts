import { type LoadoutComponentRef, type LoadoutSlot } from "@/services/fyApi";
import { type FittedSlot } from "@/frontend/composables/useComponentFitting";
import { nonStockCartItems, nonStockFittedItems } from "./loadoutCartItems";

const part = (id: string) => ({ id, name: id }) as LoadoutComponentRef;

const slot = (overrides: Partial<LoadoutSlot> = {}): LoadoutSlot => ({
  name: "hardpoint",
  hardpointId: "hp",
  types: [],
  editable: true,
  slots: [],
  ...overrides,
});

describe("nonStockCartItems", () => {
  it("leaves out slots that keep or refit their stock part", () => {
    expect(
      nonStockCartItems([
        slot({ stock: part("stock-cooler") }),
        slot({ stock: part("stock-shield"), fitted: part("stock-shield") }),
        slot({ stock: part("stock-qd"), emptied: true }),
      ]),
    ).toEqual([]);
  });

  it("counts the same part in several hardpoints as one line", () => {
    expect(
      nonStockCartItems([
        slot({ stock: part("stock-gun"), fitted: part("panther") }),
        slot({ stock: part("stock-gun"), fitted: part("panther") }),
        slot({ stock: part("stock-cooler"), fitted: part("bracer") }),
      ]),
    ).toEqual([
      { itemType: "Component", itemId: "panther", quantity: 2 },
      { itemType: "Component", itemId: "bracer", quantity: 1 },
    ]);
  });

  it("includes parts fitted in nested ports", () => {
    expect(
      nonStockCartItems([
        slot({
          stock: part("stock-mount"),
          fitted: part("gimbal"),
          slots: [
            slot({ fitted: part("panther") }),
            slot({ fitted: part("panther") }),
          ],
        }),
      ]),
    ).toEqual([
      { itemType: "Component", itemId: "gimbal", quantity: 1 },
      { itemType: "Component", itemId: "panther", quantity: 2 },
    ]);
  });
});

const fitted = (
  stock?: string,
  content?: string,
  children: FittedSlot[] = [],
): FittedSlot => ({
  path: "hardpoint",
  slot: slot({ stock: stock ? part(stock) : undefined }),
  content: content ? part(content) : undefined,
  children,
});

describe("nonStockFittedItems", () => {
  it("counts what the editor has fitted in place of stock, nested ports included", () => {
    expect(
      nonStockFittedItems([
        fitted("stock-gun", "stock-gun"),
        fitted("stock-mount", "gimbal", [
          fitted(undefined, "panther"),
          fitted(undefined, "panther"),
        ]),
      ]),
    ).toEqual([
      { itemType: "Component", itemId: "gimbal", quantity: 1 },
      { itemType: "Component", itemId: "panther", quantity: 2 },
    ]);
  });

  it("leaves modules out", () => {
    expect(
      nonStockFittedItems([
        {
          ...fitted(undefined, undefined),
          content: { id: "cargo-module", name: "Cargo", category: "module" },
        } as FittedSlot,
      ]),
    ).toEqual([]);
  });
});
