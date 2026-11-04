import { describe, expect, it } from "vitest";
import { placementsFromLayout } from "./savedLayouts";
import type { FleetchartPlacement } from "@/services/fyApi";

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
        },
      ] as FleetchartPlacement[]),
    ).toEqual({ a: { x: 1, y: 2 } });
  });
});
