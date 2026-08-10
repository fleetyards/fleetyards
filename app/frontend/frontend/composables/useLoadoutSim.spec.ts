import { describe, expect, it } from "vitest";
import { HardpointCategoryEnum, type Hardpoint } from "@/services/fyApi";
import {
  POWER_FAMILY_BY_CATEGORY,
  simulateLoadoutPower,
  useLoadoutSim,
} from "./useLoadoutSim";

let seq = 0;

function hp(
  category: HardpointCategoryEnum,
  typeData: Record<string, unknown>,
  extra: Partial<Hardpoint> = {},
): Hardpoint {
  seq += 1;
  return {
    id: `hp-${seq}`,
    name: category,
    category,
    component: { size: 1, typeData } as Hardpoint["component"],
    ...extra,
  } as Hardpoint;
}

describe("useLoadoutSim", () => {
  it("reproduces the max-power weapon ratio when segments are ample (Asgard)", () => {
    // One plant of 20 segments, 4 weapons drawing 2 each (consumption 8), a
    // shield and life support. Weapon pool 4 → weapon fills to 4 → ratio 0.5.
    const hardpoints: Hardpoint[] = [
      hp(HardpointCategoryEnum.POWERPLANT, { powerBase: 20 }, {
        component: { size: 2, typeData: { powerBase: 20 } },
      } as Partial<Hardpoint>),
      ...Array.from({ length: 4 }, () =>
        hp(HardpointCategoryEnum.WEAPONS, { powerConsumption: 2 }),
      ),
      hp(HardpointCategoryEnum.SHIELDGENERATOR, { powerConsumption: 3 }),
      hp(HardpointCategoryEnum.LIFESUPPORT, { powerConsumption: 1 }),
    ];

    const sim = useLoadoutSim(hardpoints, 4).value;

    expect(sim.totalSegments).toBe(20);
    expect(sim.perFamily.weapon).toBe(4);
    expect(sim.weaponPoolRatio).toBeCloseTo(0.5);
    // Ample power leaves the non-weapon families fully fed.
    expect(sim.perFamily.shield).toBeGreaterThan(0);
    expect(sim.perFamily.lifeSupport).toBeGreaterThan(0);
  });

  it("throttles the weapon pool when the plant is segment-starved", () => {
    const hardpoints: Hardpoint[] = [
      hp(HardpointCategoryEnum.POWERPLANT, { powerBase: 3 }, {
        component: { size: 1, typeData: { powerBase: 3 } },
      } as Partial<Hardpoint>),
      hp(HardpointCategoryEnum.LIFESUPPORT, { powerConsumption: 2 }),
      ...Array.from({ length: 4 }, () =>
        hp(HardpointCategoryEnum.WEAPONS, { powerConsumption: 2 }),
      ),
    ];

    const sim = useLoadoutSim(hardpoints, 4).value;

    // 3 segments: life support keeps its critical block, weapons get the rest —
    // below the pool of 4, so the ratio drops under the max-power 0.5.
    expect(sim.totalSegments).toBe(3);
    expect(sim.weaponPoolRatio).toBeLessThan(0.5);
  });

  it("treats a ship without a weapon pool as power-unlimited (ratio 1)", () => {
    const hardpoints: Hardpoint[] = [
      hp(HardpointCategoryEnum.POWERPLANT, { powerBase: 10 }, {
        component: { size: 1, typeData: { powerBase: 10 } },
      } as Partial<Hardpoint>),
      hp(HardpointCategoryEnum.WEAPONS, { powerConsumption: 2 }),
    ];

    expect(useLoadoutSim(hardpoints, 0).value.weaponPoolRatio).toBe(1);
    expect(useLoadoutSim(hardpoints, undefined).value.weaponPoolRatio).toBe(1);
  });

  it("descends into nested hardpoints (weapons under a mount)", () => {
    const hardpoints: Hardpoint[] = [
      hp(HardpointCategoryEnum.POWERPLANT, { powerBase: 20 }, {
        component: { size: 1, typeData: { powerBase: 20 } },
      } as Partial<Hardpoint>),
      hp(
        HardpointCategoryEnum.WEAPON_MOUNTS,
        {},
        {
          hardpoints: [
            hp(HardpointCategoryEnum.WEAPONS, { powerConsumption: 2 }),
            hp(HardpointCategoryEnum.WEAPONS, { powerConsumption: 2 }),
          ],
        },
      ),
    ];

    const sim = useLoadoutSim(hardpoints, 2).value;
    // Two nested weapons drawing 2 each → consumption 4, pool 2 → ratio 0.5.
    expect(sim.perFamily.weapon).toBe(2);
    expect(sim.weaponPoolRatio).toBeCloseTo(0.5);
  });
});

describe("weaponMaxRatio (sustained-DPS input)", () => {
  const weapons = (n: number, draw: number) =>
    Array.from({ length: n }, () =>
      hp(HardpointCategoryEnum.WEAPONS, { powerConsumption: draw }),
    );

  it("equals min(1, pool/consumption) when the plant has ample power", () => {
    const hardpoints = [
      hp(HardpointCategoryEnum.POWERPLANT, { powerBase: 40 }, {
        component: { size: 2, typeData: { powerBase: 40 } },
      } as Partial<Hardpoint>),
      ...weapons(4, 2), // consumption 8, pool 4 → 0.5
      hp(HardpointCategoryEnum.SHIELDGENERATOR, { powerConsumption: 4 }),
    ];
    expect(simulateLoadoutPower(hardpoints, 4).weaponMaxRatio).toBeCloseTo(0.5);
  });

  it("caps below the uncapped ratio when the plant is segment-starved", () => {
    const hardpoints = [
      hp(HardpointCategoryEnum.POWERPLANT, { powerBase: 3 }, {
        component: { size: 1, typeData: { powerBase: 3 } },
      } as Partial<Hardpoint>),
      hp(HardpointCategoryEnum.LIFESUPPORT, { powerConsumption: 2 }),
      ...weapons(4, 2), // consumption 8, pool 4 → uncapped 0.5
    ];
    // 3 segments, 1 reserved as life-support critical → weapons max 2 of pool 4.
    const ratio = simulateLoadoutPower(hardpoints, 4).weaponMaxRatio;
    expect(ratio).toBeLessThan(0.5);
    expect(ratio).toBeCloseTo(2 / 8);
  });

  it("falls back to the uncapped ratio when there is no plant data (no regression)", () => {
    const hardpoints = [...weapons(4, 2)]; // no power plant at all
    expect(simulateLoadoutPower(hardpoints, 4).weaponMaxRatio).toBeCloseTo(0.5);
  });

  it("is 1 for a ship without a weapon pool", () => {
    const hardpoints = [
      hp(HardpointCategoryEnum.POWERPLANT, { powerBase: 5 }, {
        component: { size: 1, typeData: { powerBase: 5 } },
      } as Partial<Hardpoint>),
      ...weapons(2, 2),
    ];
    expect(simulateLoadoutPower(hardpoints, 0).weaponMaxRatio).toBe(1);
  });
});

describe("POWER_FAMILY_BY_CATEGORY", () => {
  it("maps the power-drawing families and leaves the rest unmapped", () => {
    expect(POWER_FAMILY_BY_CATEGORY[HardpointCategoryEnum.WEAPONS]).toBe(
      "weapon",
    );
    expect(
      POWER_FAMILY_BY_CATEGORY[HardpointCategoryEnum.SHIELDGENERATOR],
    ).toBe("shield");
    expect(POWER_FAMILY_BY_CATEGORY[HardpointCategoryEnum.CONTROLLER]).toBe(
      "engine",
    );
    // Thrusters / fuel draw no power segments in erkul's model.
    expect(
      POWER_FAMILY_BY_CATEGORY[HardpointCategoryEnum.MAIN_THRUSTERS],
    ).toBeUndefined();
    expect(
      POWER_FAMILY_BY_CATEGORY[HardpointCategoryEnum.FUELTANKS],
    ).toBeUndefined();
  });
});
