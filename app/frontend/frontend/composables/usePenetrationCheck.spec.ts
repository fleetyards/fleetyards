import { describe, expect, it } from "vitest";
import {
  HardpointCategoryEnum,
  type Hardpoint,
  type ModelDefense,
  type WeaponIndexItem,
} from "@/services/fyApi";
import {
  collectLoadoutWeapons,
  computePenetrationCheck,
  penetrationTargets,
} from "./usePenetrationCheck";

function weapon(
  name: string,
  damagePerShot: Partial<Record<string, number>>,
  extra: Partial<WeaponIndexItem> = {},
): WeaponIndexItem {
  return {
    id: name,
    name,
    size: "3",
    beam: false,
    pelletsPerShot: 1,
    ...extra,
    damagePerShot: {
      physical: 0,
      energy: 0,
      distortion: 0,
      thermal: 0,
      ...damagePerShot,
    },
  } as WeaponIndexItem;
}

// Gladius-like: shields soak 45% of physical and all energy, deflection 11/9.
const GLADIUS: ModelDefense = {
  id: "gladius",
  name: "Gladius",
  slug: "gladius",
  size: "small",
  armor: {
    health: 3300,
    damagePhysical: 0.75,
    damageEnergy: 0.6,
    deflectionPhysical: 11,
    deflectionEnergy: 9,
  },
  shields: [
    {
      maxHealth: 6336,
      maxRegen: 0,
      absorption: {
        physical: { min: 0, max: 0.45 },
        energy: { min: 1, max: 1 },
      },
      resistance: { physical: { min: 0, max: 0.25 } },
    },
  ],
};

// Asgard-like: a much heavier deflection threshold.
const ASGARD: ModelDefense = {
  id: "asgard",
  name: "Asgard",
  slug: "asgard",
  size: "medium",
  armor: {
    health: 23760,
    deflectionPhysical: 139,
    deflectionEnergy: 88,
  },
  shields: [],
};

const NO_ARMOR: ModelDefense = {
  id: "bare",
  name: "Bare",
  slug: "bare",
  shields: [{ maxHealth: 1000, maxRegen: 0 }],
};

const targets = () => penetrationTargets([GLADIUS, ASGARD, NO_ARMOR]);

describe("penetrationTargets", () => {
  it("leaves out ships with no armor threshold", () => {
    expect(targets().map((target) => target.model.id)).toEqual([
      "gladius",
      "asgard",
    ]);
  });

  it("builds the same stats the loadout path does", () => {
    const [gladius] = targets();

    expect(gladius.shield.totalHp).toBe(6336);
    expect(gladius.shield.absorptionByType.physical).toBeCloseTo(0.45);
    expect(gladius.armor.deflections.map((entry) => entry.value)).toEqual([
      11, 9,
    ]);
  });
});

describe("computePenetrationCheck", () => {
  it("pierces a ship when any selected weapon does", () => {
    const summary = computePenetrationCheck(
      [weapon("Small", { physical: 20 }), weapon("Big", { physical: 200 })],
      targets(),
      1,
      1,
    );

    const gladius = summary.results.find((r) => r.model.id === "gladius")!;
    const asgard = summary.results.find((r) => r.model.id === "asgard")!;

    expect(gladius.outcome).toBe("pierces");
    expect(gladius.best?.weapon.name).toBe("Big");
    expect(asgard.outcome).toBe("pierces");
    expect(asgard.margin).toBeCloseTo(200 - 139);
  });

  it("counts deflected and pierced ships", () => {
    // 20 physical: 20 * 0.55 * 0.75 = 8.25 vs 11 on the Gladius (deflected),
    // 20 vs 139 on the unshielded Asgard (deflected).
    const summary = computePenetrationCheck(
      [weapon("Small", { physical: 20 })],
      targets(),
      1,
      1,
    );

    expect(summary.deflectedCount).toBe(2);
    expect(summary.pierceCount).toBe(0);

    // With the Gladius's shields down the full 20 meets an 11 threshold.
    const shieldsDown = computePenetrationCheck(
      [weapon("Small", { physical: 20 })],
      targets(),
      0,
      1,
    );

    expect(shieldsDown.pierceCount).toBe(1);
    expect(shieldsDown.deflectedCount).toBe(1);
  });

  it("scales the threshold with target armor health", () => {
    const summary = computePenetrationCheck(
      [weapon("Mid", { physical: 100 })],
      targets(),
      1,
      0.5,
    );

    const asgard = summary.results.find((r) => r.model.id === "asgard")!;
    expect(asgard.outcome).toBe("pierces");
    expect(asgard.margin).toBeCloseTo(100 - 69.5);
  });

  it("marks a ship absorbed when its shields soak every weapon", () => {
    const summary = computePenetrationCheck(
      [weapon("Laser", { energy: 500 })],
      targets(),
      1,
      1,
    );

    const gladius = summary.results.find((r) => r.model.id === "gladius")!;
    expect(gladius.outcome).toBe("absorbed");
    expect(gladius.margin).toBeNull();
    expect(summary.absorbedCount).toBe(1);
    // Absorbed ships lead, then ascending margin.
    expect(summary.results[0].model.id).toBe("gladius");
  });

  it("sorts the rest by margin, deflected before pierced", () => {
    const summary = computePenetrationCheck(
      [weapon("Mid", { physical: 100 })],
      targets(),
      1,
      1,
    );

    expect(summary.results.map((r) => r.outcome)).toEqual([
      "deflected",
      "pierces",
    ]);
  });

  it("skips beams and returns nothing without weapons", () => {
    expect(
      computePenetrationCheck(
        [weapon("Beam", { energy: 999 }, { beam: true })],
        targets(),
        1,
        1,
      ).results,
    ).toEqual([]);
    expect(computePenetrationCheck([], targets(), 1, 1).results).toEqual([]);
  });
});

describe("collectLoadoutWeapons", () => {
  function gun(id: string, typeData: Record<string, unknown>): Hardpoint {
    return {
      id: `slot-${Math.random()}`,
      name: "hardpoint_weapon",
      category: HardpointCategoryEnum.WEAPONS,
      component: { id, name: id, slug: id, size: "3", typeData },
      hardpoints: [],
    } as unknown as Hardpoint;
  }

  it("collects nested guns once per component with a count", () => {
    const mount = {
      id: "mount",
      name: "hardpoint_turret",
      category: HardpointCategoryEnum.TURRET,
      hardpoints: [
        gun("repeater", { damagePerShot: { energy: 30 } }),
        gun("repeater", { damagePerShot: { energy: 30 } }),
      ],
    } as unknown as Hardpoint;

    const weapons = collectLoadoutWeapons([
      mount,
      gun("cannon", { damagePerShot: { physical: 200 } }),
    ]);

    expect(weapons.map((entry) => [entry.id, entry.count])).toEqual([
      ["repeater", 2],
      ["cannon", 1],
    ]);
    expect(weapons[0].damagePerShot.energy).toBe(30);
    expect(weapons[0].damagePerShot.physical).toBe(0);
  });

  it("carries each gun's sustained damage and duty cycle", () => {
    // 600 rpm, overheating after 5 s of fire and recovering in 5 s.
    const [cannon] = collectLoadoutWeapons([
      gun("cannon", {
        damagePerShot: { physical: 100 },
        fireRate: 600,
        heatPerShot: 2,
        heat: { overheatTemperature: 100, overheatFixTime: 5 },
      }),
    ]);

    expect(cannon.sustainedDps.physical).toBeCloseTo(500);
    expect(cannon.duty).toEqual({ ratio: 0.5, offTime: 5, cycle: 10 });
  });

  it("fires nothing with the weapon system unpowered", () => {
    const [cannon] = collectLoadoutWeapons(
      [gun("cannon", { damagePerShot: { physical: 100 }, fireRate: 600 })],
      0,
    );

    expect(cannon.sustainedDps.physical).toBe(0);
  });

  it("ignores guns whose only damage the check does not weigh", () => {
    expect(
      collectLoadoutWeapons([gun("stunner", { damagePerShot: { stun: 40 } })]),
    ).toEqual([]);
  });

  it("ignores missiles and mining lasers", () => {
    const weapons = collectLoadoutWeapons([
      gun("missile", {
        damagePerShot: { physical: 5000 },
        trackingSignal: "IR",
      }),
      gun("mining", {
        damagePerSecond: { energy: 500 },
        beam: true,
        mining: true,
      }),
    ]);

    expect(weapons).toEqual([]);
  });

  it("carries a beam's damage per second, with no alpha to test", () => {
    const [beam] = collectLoadoutWeapons([
      gun("beam", { damagePerSecond: { energy: 250 }, beam: true }),
    ]);

    expect(beam.beam).toBe(true);
    expect(beam.sustainedDps.energy).toBeCloseTo(250);
    expect(beam.damagePerShot.energy).toBe(0);
  });

  it("leaves a beam out of the deflection margin", () => {
    const [beam] = collectLoadoutWeapons([
      gun("beam", { damagePerSecond: { energy: 250 }, beam: true }),
    ]);

    const { results } = computePenetrationCheck(
      [beam],
      penetrationTargets([GLADIUS]),
      1,
      1,
    );

    expect(results).toEqual([]);
  });
});
