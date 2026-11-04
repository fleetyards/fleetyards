import { describe, expect, it } from "vitest";
import { placementsFromLayout, stackingOrders } from "./savedLayouts";
import type { FleetchartPlacement } from "@/services/fyApi";

describe("stackingOrders", () => {
  it("records the drawing order of ships without an order of their own", () => {
    expect(stackingOrders(["kraken", "constellation"], () => 0)).toEqual({
      kraken: 0,
      constellation: 1,
    });
  });

  it("puts an explicit order ahead of the drawing order", () => {
    const orders: Record<string, number> = { a: 2, c: -1 };

    expect(stackingOrders(["a", "b", "c"], (id) => orders[id] ?? 0)).toEqual({
      c: 0,
      b: 1,
      a: 2,
    });
  });
});

describe("placementsFromLayout", () => {
  it("keeps everything a placement has", () => {
    expect(
      placementsFromLayout([
        {
          vehicleId: "a",
          x: 1,
          y: 2,
          facing: "top",
          viewpoint: "rear",
          state: "landed",
          order: 0,
          groupId: "g",
          heading: "Anvil",
        },
      ] as FleetchartPlacement[]),
    ).toEqual({
      a: {
        x: 1,
        y: 2,
        facing: "top",
        viewpoint: "rear",
        state: "landed",
        order: 0,
        groupId: "g",
        heading: "Anvil",
      },
    });
  });

  it("leaves out what the API sent as null", () => {
    expect(
      placementsFromLayout([
        {
          vehicleId: "a",
          x: 1,
          y: 2,
          facing: null,
          viewpoint: null,
          state: null,
          order: null,
          groupId: null,
          heading: null,
        },
      ] as FleetchartPlacement[]),
    ).toEqual({ a: { x: 1, y: 2 } });
  });
});
