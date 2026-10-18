import { describe, expect, it } from "vitest";
import { HardpointCategoryEnum, type Hardpoint } from "@/services/fyApi";
import { rowPresentation } from "./rowPresentation";

const t = (key: string) => key;

const toNumber = (value: number, units: string) => `${value} ${units}`;

const hardpoint = (attributes: Record<string, unknown>) =>
  attributes as unknown as Hardpoint;

describe("rowPresentation", () => {
  it("reads a cargo grid as its hold, with its capacity and largest container", () => {
    const grid = rowPresentation(HardpointCategoryEnum.CARGOGRID);
    const hold = hardpoint({
      category: HardpointCategoryEnum.CARGOGRID,
      component: {
        name: "hardpoint_cargogrid_main",
        typeData: { capacity: 96, maxContainerSize: { size: 32 } },
      },
    });

    expect(grid.label?.(hold, t)).toBe("Main");
    expect(grid.headline?.(hold, t, toNumber)).toEqual({
      value: "96 cargo",
      unit: "labels.cargoGridViewer.capacity",
    });
    expect(grid.stats?.(hold, t, toNumber)).toEqual([
      { label: "labels.hardpoint.maxContainerSize", value: "32 cargo" },
    ]);
    expect(grid.sizeless).toBe(true);
  });

  it("names a tank by what it holds, and an ore pod by its volume", () => {
    const tank = rowPresentation(HardpointCategoryEnum.FUELTANKS);

    expect(
      tank.label?.(hardpoint({ component: { subType: "QuantumFuel" } }), t),
    ).toBe("labels.hardpoint.fuelTanks.quantum");
    expect(
      rowPresentation(HardpointCategoryEnum.ORE_PODS).headline?.(
        hardpoint({ component: { typeData: { storage: 12 } } }),
        t,
        toNumber,
      ),
    ).toEqual({ value: "12 cargo", unit: "labels.cargoGridViewer.capacity" });
  });

  it("names a seat after its hardpoint and gives it nothing to lead with", () => {
    const seat = rowPresentation(HardpointCategoryEnum.SEAT);
    const pilot = hardpoint({ name: "hardpoint_seat_pilot" });

    expect(seat.label?.(pilot, t)?.trim()).toBe("Seat Pilot");
    expect(seat.headline?.(pilot, t, toNumber)).toBeUndefined();
    expect(seat.sizeless).toBe(true);
  });

  it("names a loadout's module slot after its module, or as empty", () => {
    const slot = rowPresentation(HardpointCategoryEnum.MODULE);

    expect(
      slot.label?.(hardpoint({ component: { name: "Cargo Module" } }), t),
    ).toBe("Cargo Module");
    expect(slot.label?.(hardpoint({}), t)).toBe(
      "labels.hardpoint.moduleSlotEmpty",
    );
  });

  it("leaves a part's own kinds as they are", () => {
    expect(rowPresentation(HardpointCategoryEnum.WEAPONS)).toEqual({});
  });
});
