import { describe, expect, it } from "vitest";
import { type Hardpoint, HardpointCategoryEnum } from "@/services/fyApi";
import { partContents } from "./contents";

const port = (name: string, component?: Record<string, unknown>) =>
  ({
    id: name,
    name,
    category: component
      ? HardpointCategoryEnum.CARGOGRID
      : HardpointCategoryEnum.UNKNOWN,
    component,
    hardpoints: [],
  }) as unknown as Hardpoint;

const station = (ports: Hardpoint[]) =>
  ({
    id: "station",
    name: "hardpoint_salvage_filler_right",
    component: { id: "filler", hardpoints: ports },
    hardpoints: [],
  }) as unknown as Hardpoint;

describe("partContents", () => {
  it("lists a fitted port that comes after empty ones", () => {
    const grid = port("hardpoint_cargo_grid", { id: "grid", name: "Grid" });

    const contents = partContents(
      station([
        port("hardpoint_salvage_refill"),
        port("hardpoint_salvage_crate"),
        grid,
      ]),
    );

    expect(contents).toEqual([grid]);
  });

  it("lists nothing for a part whose ports are all empty", () => {
    const contents = partContents(
      station([
        port("hardpoint_salvage_refill"),
        port("hardpoint_salvage_crate"),
      ]),
    );

    expect(contents).toEqual([]);
  });
});
