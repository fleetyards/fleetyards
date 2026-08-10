import { describe, expect, it } from "vitest";
import type { WeaponIndexItem } from "@/services/fyApi";
import { computeArmorStats } from "./useArmorStats";
import { computeShieldStats } from "./useShieldStats";
import { computeDeflectionCheck } from "./useDeflectionCheck";
import {
  HardpointCategoryEnum,
  type Hardpoint,
  type ComponentShield,
  type ComponentArmor,
} from "@/services/fyApi";

function hardpoint(
  category: Hardpoint["category"],
  typeData: ComponentShield | ComponentArmor,
): Hardpoint {
  return {
    id: Math.random().toString(),
    name: "hardpoint",
    category,
    component: { name: "component", typeData } as Hardpoint["component"],
    hardpoints: [],
    createdAt: "",
    updatedAt: "",
  } as Hardpoint;
}

function weapon(
  name: string,
  damagePerShot: Partial<Record<string, number>>,
  size = "3",
  extra: Partial<WeaponIndexItem> = {},
): WeaponIndexItem {
  return {
    id: name,
    name,
    size,
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

// Mirrors the Gladius: 45% physical absorption, 25% physical shield
// resistance, deflection thresholds of 11 physical / 9 energy. Note the armor
// damage reduction below is deliberately NOT what drives the deflection test —
// on this ship it happens to equal `1 - shieldResistance`, which is exactly why
// the Asgard was needed to tell them apart.
const GLADIUS = [
  hardpoint(HardpointCategoryEnum.SHIELDGENERATOR, {
    maxHealth: 6336,
    maxRegen: 1204,
    absorption: {
      physical: { min: 0, max: 0.45 },
      energy: { min: 1, max: 1 },
    },
    resistance: {
      physical: { min: 0, max: 0.25 },
      energy: { min: 0, max: 0 },
    },
  }),
  hardpoint(HardpointCategoryEnum.ARMOR, {
    health: 3300,
    damagePhysical: 0.75,
    damageEnergy: 0.6,
    deflectionPhysical: 11,
    deflectionEnergy: 9,
  }),
];

const armor = () => computeArmorStats(GLADIUS);
const shield = () => computeShieldStats(GLADIUS);

// Every physical row erkul lists for the Gladius, read off their Deflection
// check on v4.9.0-LIVE: raw alpha and the margin they display.
const ERKUL_GLADIUS_ROWS = [
  { name: 'SW16BR1 "Buzzsaw" Repeater', alpha: 18, margin: -4 },
  { name: "Mantis GT-220 Gatling", alpha: 19, margin: -3 },
  { name: "Tigerstrike T-19P", alpha: 23, margin: -2 },
  { name: 'SW16BR2 "Sawbuck" Repeater', alpha: 24, margin: -1 },
  { name: 'SW16BR3 "Shredder" Repeater', alpha: 45, margin: 8 },
  { name: "Havoc Scattergun", alpha: 47, margin: 8 },
  { name: "9-Series Longsword Cannon", alpha: 49, margin: 9 },
  { name: "Breakneck S4 Gatling", alpha: 52, margin: 10 },
];

describe("computeDeflectionCheck vs erkul", () => {
  const { results } = computeDeflectionCheck(
    ERKUL_GLADIUS_ROWS.map((row) => weapon(row.name, { physical: row.alpha })),
    armor(),
    shield(),
    1,
    1,
  );

  it.each(ERKUL_GLADIUS_ROWS)(
    "matches erkul's margin for $name",
    ({ name, margin }) => {
      const entry = results.find((result) => result.weapon.name === name)!;
      expect(Math.round(entry.margin!)).toBe(margin);
    },
  );

  it("matches erkul's ordering and threshold split", () => {
    expect(results.map((entry) => entry.weapon.name)).toEqual(
      ERKUL_GLADIUS_ROWS.map((row) => row.name),
    );

    // erkul draws "threshold crossed" after the Sawbuck: 4 deflected, 4 pierce.
    expect(
      results.slice(0, 4).every((entry) => entry.outcome === "deflected"),
    ).toBe(true);
    expect(results.slice(4).every((entry) => entry.outcome === "pierces")).toBe(
      true,
    );
  });
});

describe("computeDeflectionCheck", () => {
  it("reproduces erkul's worked example", () => {
    // Tigerstrike T-19P: 23 raw physical against the Gladius.
    // 23 × (1 - 0.45) × (1 - 0.25) = 9.49, under the 11 threshold.
    const { results } = computeDeflectionCheck(
      [weapon("Tigerstrike T-19P", { physical: 23 })],
      armor(),
      shield(),
      1,
      1,
    );

    const physical = results[0].types.find((t) => t.key === "physical")!;
    expect(physical.effective).toBeCloseTo(9.49, 2);
    expect(physical.deflection).toBe(11);
    expect(results[0].outcome).toBe("deflected");
  });

  it("pierces once the shot clears the threshold", () => {
    // 45 raw → 45 × 0.55 × 0.75 = 18.56, comfortably past 11.
    // (0.75 here is 1 - shield resistance, not the armor multiplier.)
    const { results, pierceCount } = computeDeflectionCheck(
      [weapon("Shredder", { physical: 45 })],
      armor(),
      shield(),
      1,
      1,
    );

    expect(results[0].outcome).toBe("pierces");
    expect(results[0].margin).toBeCloseTo(7.56, 2);
    expect(pierceCount).toBe(1);
  });

  it("reports a fully shielded weapon as absorbed, not deflected", () => {
    // Regression: a size 10 energy cannon against a 100%-energy-absorbing
    // shield is stopped by the shield. Calling that "deflected" implied the
    // armor's 9-point threshold turned away 5000 damage, which is nonsense.
    const { results, absorbedCount, deflectedCount } = computeDeflectionCheck(
      [weapon("Heavy Laser Cannon", { energy: 5000 }, "10")],
      armor(),
      shield(),
      1,
      1,
    );

    const energy = results[0].types.find((t) => t.key === "energy")!;
    expect(energy.absorbed).toBe(true);
    expect(energy.effective).toBe(0);

    expect(results[0].outcome).toBe("absorbed");
    expect(results[0].margin).toBeNull();
    expect(results[0].best).toBeNull();

    expect(absorbedCount).toBe(1);
    expect(deflectedCount).toBe(0);
  });

  it("lets that same weapon through once the shields drop", () => {
    const { results } = computeDeflectionCheck(
      [weapon("Heavy Laser Cannon", { energy: 5000 }, "10")],
      armor(),
      shield(),
      0,
      1,
    );

    // Shields gone: nothing absorbed, no resistance, so the full 5000 lands
    // against a 9-point energy threshold.
    expect(results[0].outcome).toBe("pierces");
    expect(results[0].types[0].effective).toBeCloseTo(5000);
  });

  it("interpolates absorption across the range as shields fail", () => {
    // At half health physical absorption is 22.5% and resistance 12.5%, so
    // 23 × 0.775 × 0.875 = 15.6 now clears the 11 threshold.
    const { results } = computeDeflectionCheck(
      [weapon("Tigerstrike T-19P", { physical: 23 })],
      armor(),
      shield(),
      0.5,
      1,
    );

    expect(results[0].types[0].effective).toBeCloseTo(15.6, 1);
    expect(results[0].outcome).toBe("pierces");
  });

  it("lets everything through once shields are down", () => {
    // No absorption and no resistance, so the full 23 beats the 11 threshold.
    const { results } = computeDeflectionCheck(
      [weapon("Tigerstrike T-19P", { physical: 23 })],
      armor(),
      shield(),
      0,
      1,
    );

    expect(results[0].types[0].effective).toBeCloseTo(23, 2);
    expect(results[0].outcome).toBe("pierces");
  });

  it("sorts by margin so the threshold split is contiguous", () => {
    const { results } = computeDeflectionCheck(
      [
        weapon("Big", { physical: 60 }),
        weapon("Small", { physical: 10 }),
        weapon("Medium", { physical: 30 }),
      ],
      armor(),
      shield(),
      1,
      1,
    );

    expect(results.map((entry) => entry.weapon.name)).toEqual([
      "Small",
      "Medium",
      "Big",
    ]);

    const firstPiercing = results.findIndex(
      (entry) => entry.outcome === "pierces",
    );
    expect(
      results
        .slice(firstPiercing)
        .every((entry) => entry.outcome === "pierces"),
    ).toBe(true);
  });

  it("skips weapons that deal no damage at all", () => {
    const { results } = computeDeflectionCheck(
      [weapon("Empty", {})],
      armor(),
      shield(),
      1,
      1,
    );

    expect(results).toEqual([]);
  });

  it("counts a weapon as piercing when any single type clears its threshold", () => {
    const { results } = computeDeflectionCheck(
      [weapon("Mixed", { physical: 45, energy: 5000 })],
      armor(),
      shield(),
      1,
      1,
    );

    expect(results[0].outcome).toBe("pierces");
    // Energy is absorbed, so physical is what carries the verdict.
    expect(results[0].best?.key).toBe("physical");
  });
});

describe("computeDeflectionCheck rules read off erkul's footnote", () => {
  it("compares alpha per pellet, not per shot", () => {
    // 8 pellets of 45 each: as one 360-damage shot it would pierce easily,
    // but each pellet meets the threshold alone.
    const { results } = computeDeflectionCheck(
      [weapon("Scattergun", { physical: 360 }, "3", { pelletsPerShot: 8 })],
      armor(),
      shield(),
      1,
      1,
    );

    expect(results[0].types[0].raw).toBeCloseTo(45);
    expect(results[0].types[0].effective).toBeCloseTo(18.56, 2);
  });

  it("excludes laser beams", () => {
    const { results } = computeDeflectionCheck(
      [
        weapon("Beam Laser", { energy: 900 }, "3", { beam: true }),
        weapon("Normal Cannon", { physical: 45 }),
      ],
      armor(),
      shield(),
      1,
      1,
    );

    expect(results.map((entry) => entry.weapon.name)).toEqual([
      "Normal Cannon",
    ]);
  });

  it("scales deflection linearly with armor health", () => {
    // erkul: an Asgard at 51% armor reports 71 physical against 139 at full.
    const asgard = [
      hardpoint(HardpointCategoryEnum.ARMOR, {
        health: 23760,
        damagePhysical: 0.7,
        deflectionPhysical: 139,
      }),
    ];

    const { results } = computeDeflectionCheck(
      [weapon("Probe", { physical: 1000 })],
      computeArmorStats(asgard),
      computeShieldStats([]),
      1,
      0.51,
    );

    expect(results[0].types[0].deflection).toBeCloseTo(70.89, 2);
  });

  it("removes deflection entirely at zero armor health", () => {
    const { results } = computeDeflectionCheck(
      [weapon("Buzzsaw", { physical: 18 })],
      armor(),
      shield(),
      1,
      0,
    );

    // 7.43 effective beats a threshold of 0.
    expect(results[0].types[0].deflection).toBe(0);
    expect(results[0].outcome).toBe("pierces");
  });
});

// The Asgard is the ship that tells the two candidate formulas apart. Its armor
// reduces physical by 30%, so if that reduction fed the deflection test these
// margins would each be ~6 further from zero. Read off erkul at 0% shields /
// 100% armor, where physical deflection is 139.
const ERKUL_ASGARD_ZERO_SHIELDS = [
  { name: "YellowJacket GT-210 Gatling", alpha: 8, margin: -131 },
  { name: "Scorpion GT-215 Gatling", alpha: 13, margin: -126 },
  { name: "Deathroll S2 Gatling", alpha: 14, margin: -125 },
  { name: 'MRX "Torrent"', alpha: 18, margin: -121 },
  { name: 'SW16BR1 "Buzzsaw" Repeater', alpha: 18, margin: -121 },
  { name: "Mantis GT-220 Gatling", alpha: 19, margin: -120 },
  { name: 'SW16BR2 "Sawbuck" Repeater', alpha: 24, margin: -115 },
  { name: 'SW16BR3 "Shredder" Repeater', alpha: 45, margin: -94 },
];

describe("computeDeflectionCheck vs erkul (Asgard, shields down)", () => {
  const asgard = [
    hardpoint(HardpointCategoryEnum.ARMOR, {
      health: 23760,
      damagePhysical: 0.7,
      damageEnergy: 0.5,
      deflectionPhysical: 139,
      deflectionEnergy: 88,
    }),
    hardpoint(HardpointCategoryEnum.SHIELDGENERATOR, {
      maxHealth: 42240,
      maxRegen: 0,
      absorption: {
        physical: { min: 0, max: 0.45 },
        energy: { min: 1, max: 1 },
      },
      resistance: {
        physical: { min: 0, max: 0.25 },
        energy: { min: 0, max: 0 },
      },
    }),
  ];

  const { results } = computeDeflectionCheck(
    ERKUL_ASGARD_ZERO_SHIELDS.map((row) =>
      weapon(row.name, { physical: row.alpha }),
    ),
    computeArmorStats(asgard),
    computeShieldStats(asgard),
    0,
    1,
  );

  it.each(ERKUL_ASGARD_ZERO_SHIELDS)(
    "matches erkul's margin for $name with shields down",
    ({ name, margin }) => {
      const entry = results.find((result) => result.weapon.name === name)!;
      expect(Math.round(entry.margin!)).toBe(margin);
    },
  );

  it("does not apply the armor damage multiplier to the deflection test", () => {
    const entry = results.find(
      (result) => result.weapon.name === "Mantis GT-220 Gatling",
    )!;

    // Raw alpha reaches the armor untouched once the shield is gone.
    expect(entry.types[0].effective).toBeCloseTo(19);
    // Had the 0.7 physical reduction applied it would be 13.3.
    expect(entry.types[0].effective).not.toBeCloseTo(13.3);
  });
});
