import { type LoadoutComponentRef, type LoadoutSlot } from "@/services/fyApi";
import { nonStockCartItems } from "./loadoutCartItems";

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
