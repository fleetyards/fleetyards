import { describe, expect, it } from "vitest";
import { HardpointCategoryEnum, type Hardpoint } from "@/services/fyApi";
import {
  POWER_FAMILY_BY_CATEGORY,
  simulateLoadoutPower,
  useLoadoutSim,
  WEAPON_POOL_PORT,
  SHIELD_POOL_PORT,
  type LoadoutSimResult,
} from "./useLoadoutSim";
import type { PowerFamily } from "./powerSim";

// Sum a family's per-component column capacities.
const familyCapacity = (sim: LoadoutSimResult, family: PowerFamily) =>
  sim.columns
    .filter((column) => column.family === family)
    .reduce((sum, column) => sum + column.capacity, 0);

let seq = 0;

// The component payload union, taken from the generated Hardpoint type. Each
// member is all-optional, so a minimal `{ powerBase }` / `{ powerConsumption }`
// fixture satisfies it without hand-rolling a shape.
type ComponentTypeData = NonNullable<Hardpoint["component"]>["typeData"];

function hp(
  category: HardpointCategoryEnum,
  typeData: ComponentTypeData,
  opts: { size?: number; children?: Hardpoint[] } = {},
): Hardpoint {
  seq += 1;
  return {
    id: `hp-${seq}`,
    name: category,
    category,
    component: {
      name: category,
      size: String(opts.size ?? 1),
      typeData,
    } as Hardpoint["component"],
    hardpoints: opts.children ?? [],
    createdAt: "",
    updatedAt: "",
  } as Hardpoint;
}

const plant = (powerBase: number, size = 1) =>
  hp(HardpointCategoryEnum.POWERPLANT, { powerBase }, { size });

const weapons = (count: number, draw: number) =>
  Array.from({ length: count }, () =>
    hp(HardpointCategoryEnum.WEAPONS, { powerConsumption: draw }),
  );

describe("useLoadoutSim", () => {
  it("reproduces the max-power weapon ratio when segments are ample (Asgard)", () => {
    // One plant of 20 segments, 4 weapons drawing 2 each (consumption 8), a
    // shield and life support. Weapon pool 4 → weapon fills to 4 → ratio 0.5.
    const hardpoints = [
      plant(20, 2),
      ...weapons(4, 2),
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
    const hardpoints = [
      plant(3),
      hp(HardpointCategoryEnum.LIFESUPPORT, { powerConsumption: 2 }),
      ...weapons(4, 2),
    ];

    const sim = useLoadoutSim(hardpoints, 4).value;

    // 3 segments: life support keeps its critical block, weapons get the rest —
    // below the pool of 4, so the ratio drops under the max-power 0.5.
    expect(sim.totalSegments).toBe(3);
    expect(sim.weaponPoolRatio).toBeLessThan(0.5);
  });

  it("treats a ship without a weapon pool as power-unlimited (ratio 1)", () => {
    const hardpoints = [plant(10), ...weapons(1, 2)];

    expect(useLoadoutSim(hardpoints, 0).value.weaponPoolRatio).toBe(1);
    expect(useLoadoutSim(hardpoints, undefined).value.weaponPoolRatio).toBe(1);
  });

  it("descends into nested hardpoints (weapons under a mount)", () => {
    const hardpoints = [
      plant(20),
      hp(HardpointCategoryEnum.WEAPON_MOUNTS, {}, { children: weapons(2, 2) }),
    ];

    const sim = useLoadoutSim(hardpoints, 2).value;
    // Two nested weapons drawing 2 each → consumption 4, pool 2 → ratio 0.5.
    expect(sim.perFamily.weapon).toBe(2);
    expect(sim.weaponPoolRatio).toBeCloseTo(0.5);
  });
});

describe("weaponMaxRatio (sustained-DPS input)", () => {
  it("equals min(1, pool/consumption) when the plant has ample power", () => {
    const hardpoints = [
      plant(40, 2),
      ...weapons(4, 2), // consumption 8, pool 4 → 0.5
      hp(HardpointCategoryEnum.SHIELDGENERATOR, { powerConsumption: 4 }),
    ];
    expect(simulateLoadoutPower(hardpoints, 4).weaponMaxRatio).toBeCloseTo(0.5);
  });

  it("caps below the uncapped ratio when the plant is segment-starved", () => {
    const hardpoints = [
      plant(3),
      hp(HardpointCategoryEnum.LIFESUPPORT, { powerConsumption: 2 }),
      ...weapons(4, 2), // consumption 8, pool 4 → uncapped 0.5
    ];
    // 3 segments, 1 reserved as life-support critical → weapons max 2 of pool 4.
    const ratio = simulateLoadoutPower(hardpoints, 4).weaponMaxRatio;
    expect(ratio).toBeLessThan(0.5);
    expect(ratio).toBeCloseTo(2 / 8);
  });

  it("falls back to the uncapped ratio when there is no plant data (no regression)", () => {
    expect(simulateLoadoutPower(weapons(4, 2), 4).weaponMaxRatio).toBeCloseTo(
      0.5,
    );
  });

  it("is 1 for a ship without a weapon pool", () => {
    expect(
      simulateLoadoutPower([plant(5), ...weapons(2, 2)], 0).weaponMaxRatio,
    ).toBe(1);
  });
});

describe("overrides (pip UI)", () => {
  const asgardLike = (): Hardpoint[] => [
    plant(20, 2),
    ...weapons(4, 2),
    hp(HardpointCategoryEnum.SHIELDGENERATOR, { powerConsumption: 4 }),
  ];

  it("throttles weapons down to the override target", () => {
    const sim = simulateLoadoutPower(asgardLike(), 4, "SCM", {
      [WEAPON_POOL_PORT]: 2,
    });
    expect(sim.perFamily.weapon).toBe(2);
    // consumption 8, weapon segments 2 → ratio 0.25 (below the 0.5 max).
    expect(sim.weaponPoolRatio).toBeCloseTo(0.25);
    // The max-power baseline is unaffected by the override.
    expect(sim.weaponMaxRatio).toBeCloseTo(0.5);
  });

  it("exposes one column per component with its capacity", () => {
    const sim = simulateLoadoutPower(asgardLike(), 4);
    const weaponCol = sim.columns.find((c) => c.portPath === WEAPON_POOL_PORT);
    expect(weaponCol?.capacity).toBe(4);
    expect(familyCapacity(sim, "shield")).toBe(4);
  });

  it("lets the user take weapons all the way to 0 (no forced base)", () => {
    const sim = simulateLoadoutPower(asgardLike(), 4, "SCM", {
      [WEAPON_POOL_PORT]: 0,
    });
    expect(sim.perFamily.weapon).toBe(0);
    expect(sim.weaponPoolRatio).toBe(0);
  });

  it("allocates to a specific non-weapon component the user boosts", () => {
    const cooler = hp(HardpointCategoryEnum.COOLER, { powerConsumption: 3 });
    const sim = simulateLoadoutPower(
      [plant(40, 2), ...weapons(4, 2), cooler],
      4,
      "SCM",
      { [cooler.id]: 2 },
    );
    const coolerCol = sim.columns.find((c) => c.portPath === cooler.id);
    expect(coolerCol?.allocated).toBe(2);
  });

  it("leaves the quantum drive unpowered in SCM but powered in NAV", () => {
    const qd = hp(HardpointCategoryEnum.QUANTUMDRIVE, {
      powerConsumption: 3,
      powerMinimumFraction: 1,
    });
    const ports = [plant(40, 2), qd];
    const scm = simulateLoadoutPower(ports, 0, "SCM");
    expect(scm.columns.find((c) => c.portPath === qd.id)?.allocated).toBe(0);
    const nav = simulateLoadoutPower(ports, 0, "NAV");
    expect(nav.columns.find((c) => c.portPath === qd.id)?.allocated).toBe(3);
  });

  it("defaults a non-primary system to its critical floor (life support 1)", () => {
    // LS: units 2 @ 0.5 min fraction → critical 1; not greedily filled.
    const ls = hp(HardpointCategoryEnum.LIFESUPPORT, {
      powerConsumption: 2,
      powerMinimumFraction: 0.5,
    });
    const col = simulateLoadoutPower([plant(40, 2), ls], 0).columns.find(
      (c) => c.portPath === ls.id,
    );
    expect(col?.allocated).toBe(1);
    expect(col?.capacity).toBe(2);
  });

  it("returns freed pips to the pool instead of redistributing", () => {
    const ports = asgardLike();
    const base = simulateLoadoutPower(ports, 4);
    const reduced = simulateLoadoutPower(ports, 4, "SCM", {
      [SHIELD_POOL_PORT]: 1,
    });
    // Dropping shields frees segments into `remaining`, not into other families.
    expect(reduced.remaining).toBeGreaterThan(base.remaining);
    expect(reduced.perFamily.weapon).toBe(base.perFamily.weapon);
  });
});

describe("shield active cap", () => {
  const shields = (count: number) =>
    Array.from({ length: count }, () =>
      hp(HardpointCategoryEnum.SHIELDGENERATOR, { powerConsumption: 4 }),
    );

  it("powers only the first 2 shields by default (rest are backups)", () => {
    const sim = simulateLoadoutPower([plant(40, 2), ...shields(3)], 0);
    // Shields aggregate into ONE column; 2 active × 4 cells = 8, 3rd is backup.
    expect(sim.columns.filter((c) => c.family === "shield")).toHaveLength(1);
    expect(familyCapacity(sim, "shield")).toBe(8);
  });

  it("respects a ship's own shield cap", () => {
    const sim = simulateLoadoutPower(
      [plant(40, 2), ...shields(3)],
      0,
      "SCM",
      undefined,
      3,
    );
    expect(sim.columns.filter((c) => c.family === "shield")).toHaveLength(1);
    expect(familyCapacity(sim, "shield")).toBe(12);
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
