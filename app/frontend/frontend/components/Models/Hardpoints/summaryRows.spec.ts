import { describe, expect, it } from "vitest";
import { HardpointCategoryEnum, type Hardpoint } from "@/services/fyApi";
import { minimalCategories } from "./summaryRows";

let nextId = 0;

const hardpoint = (
  category: HardpointCategoryEnum,
  name?: string,
  hardpoints: Hardpoint[] = [],
  typeData?: Record<string, unknown>,
) =>
  ({
    id: `hp-${(nextId += 1)}`,
    name: `hardpoint_${nextId}`,
    groupKey: `key-${nextId}`,
    maxSize: 3,
    category,
    hardpoints,
    component: name || typeData ? { name, typeData } : undefined,
  }) as unknown as Hardpoint;

const gun = (name: string) => hardpoint(HardpointCategoryEnum.WEAPONS, name);

const shape = (list: Hardpoint[]) =>
  minimalCategories(list).map(({ category, rows }) => [
    category,
    rows.map((row) => row.hardpoints.length),
  ]);

describe("minimalCategories", () => {
  it("lists what a mount holds instead of the mount", () => {
    const mounts = [
      hardpoint(HardpointCategoryEnum.WEAPON_MOUNTS, "Gimbal", [
        gun("Repeater"),
      ]),
      hardpoint(HardpointCategoryEnum.WEAPON_MOUNTS, "Gimbal", [
        gun("Repeater"),
      ]),
      hardpoint(HardpointCategoryEnum.WEAPON_MOUNTS, "Gimbal", [
        gun("Gatling"),
      ]),
    ];

    const [{ category, rows }] = minimalCategories(mounts);

    expect(category).toBe(HardpointCategoryEnum.WEAPONS);
    expect(rows.map((row) => row.hardpoints[0].component?.name)).toEqual([
      "Repeater",
      "Gatling",
    ]);
    expect(rows[0].hardpoints).toHaveLength(2);
  });

  it("keeps a turret's guns under the turret, through its mounts", () => {
    const turret = hardpoint(HardpointCategoryEnum.TURRET, "Remote Turret", [
      hardpoint(HardpointCategoryEnum.WEAPON_MOUNTS, "Gimbal", [gun("Cannon")]),
      hardpoint(HardpointCategoryEnum.WEAPON_MOUNTS, "Gimbal", [gun("Cannon")]),
    ]);

    expect(shape([turret])).toEqual([[HardpointCategoryEnum.TURRET, [2]]]);
  });

  it("files a rack's missiles under missiles, after the guns", () => {
    const rack = hardpoint(HardpointCategoryEnum.MISSILE_RACKS, "Rack", [
      hardpoint(HardpointCategoryEnum.MISSILES, "Ignite"),
      hardpoint(HardpointCategoryEnum.MISSILES, "Ignite"),
    ]);
    const mount = hardpoint(HardpointCategoryEnum.WEAPON_MOUNTS, "Gimbal", [
      gun("Cannon"),
    ]);

    expect(shape([rack, mount])).toEqual([
      [HardpointCategoryEnum.WEAPONS, [1]],
      [HardpointCategoryEnum.MISSILES, [2]],
    ]);
  });

  it("keeps an empty mount, so the slot still shows", () => {
    expect(
      shape([hardpoint(HardpointCategoryEnum.WEAPON_MOUNTS, "Gimbal")]),
    ).toEqual([[HardpointCategoryEnum.WEAPON_MOUNTS, [1]]]);
  });

  it("lists a jump module with the quantum drive that holds it", () => {
    const drive = hardpoint(HardpointCategoryEnum.QUANTUMDRIVE, "Beacon", [
      hardpoint(HardpointCategoryEnum.JUMPDRIVE, "Explorer"),
    ]);

    const [{ category, rows }] = minimalCategories([drive]);

    expect(category).toBe(HardpointCategoryEnum.QUANTUMDRIVE);
    expect(rows.map((row) => row.hardpoints[0].component?.name)).toEqual([
      "Beacon",
      "Explorer",
    ]);
  });

  it("leaves out fuel intakes, life support and controllers", () => {
    expect(
      shape([
        hardpoint(HardpointCategoryEnum.FUEL_INTAKES, "Intake"),
        hardpoint(HardpointCategoryEnum.LIFESUPPORT, "ComfortAir"),
        hardpoint(HardpointCategoryEnum.CONTROLLER, "Controller"),
        hardpoint(HardpointCategoryEnum.COOLER, "Bracer"),
      ]),
    ).toEqual([[HardpointCategoryEnum.COOLER, [1]]]);
  });

  it("keeps parts apart that share a name but not a sub-type", () => {
    const tank = (subType: string) => {
      const part = hardpoint(HardpointCategoryEnum.FUELTANKS, "Internal Tank");

      return {
        ...part,
        component: { ...part.component, subType },
      } as Hardpoint;
    };

    expect(shape([tank("Fuel"), tank("Fuel"), tank("QuantumFuel")])).toEqual([
      [HardpointCategoryEnum.FUELTANKS, [2, 1]],
    ]);
  });

  it("folds a thruster type into one total row, whatever their thrust", () => {
    const thruster = (thrustCapacity: number) =>
      hardpoint(HardpointCategoryEnum.MAIN_THRUSTERS, undefined, [], {
        thrustCapacity,
      });

    const [{ rows }] = minimalCategories([
      thruster(1000),
      thruster(1000),
      thruster(2000),
    ]);

    expect(rows).toHaveLength(1);
    expect(rows[0].total).toBe(true);
    expect(rows[0].hardpoints).toHaveLength(3);
  });

  it("totals the thrusters it can and lists an empty slot after them", () => {
    const [{ rows }] = minimalCategories([
      hardpoint(HardpointCategoryEnum.MAIN_THRUSTERS, undefined, [], {
        thrustCapacity: 1000,
      }),
      hardpoint(HardpointCategoryEnum.MAIN_THRUSTERS, undefined, [], {
        thrustCapacity: 1000,
      }),
      hardpoint(HardpointCategoryEnum.MAIN_THRUSTERS),
    ]);

    expect(rows.map((row) => [row.total, row.hardpoints.length])).toEqual([
      [true, 2],
      [false, 1],
    ]);
  });

  it("never stacks module slots, whose picks can differ", () => {
    expect(
      shape([
        hardpoint(HardpointCategoryEnum.MODULE, "Cargo Module"),
        hardpoint(HardpointCategoryEnum.MODULE, "Cargo Module"),
      ]),
    ).toEqual([[HardpointCategoryEnum.MODULE, [1, 1]]]);
  });

  it("does not total thrusters when one has no figure", () => {
    const [{ rows }] = minimalCategories([
      hardpoint(HardpointCategoryEnum.MAIN_THRUSTERS, "Named"),
    ]);

    expect(rows[0].total).toBe(false);
  });
});
