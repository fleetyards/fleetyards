import { describe, expect, it } from "vitest";
import type { ModelDefense } from "@/services/fyApi";
import { armorStatsFrom } from "./useArmorStats";
import { shieldStatsFrom } from "./useShieldStats";
import type { LoadoutWeapon } from "./usePenetrationCheck";
import {
  effectiveHp,
  killProfile,
  regenUptime,
  timeToKill,
  type KillProfile,
} from "./useTimeToKill";

// Shields soak a flat half of physical and all of everything else; the armor
// plate takes half of the physical damage that reaches it.
const TARGET: ModelDefense = {
  id: "target",
  name: "Target",
  slug: "target",
  hullHealth: 2000,
  armor: {
    health: 500,
    deflectionPhysical: 10,
    selfResistancePhysical: 0.5,
  },
  shields: [
    {
      maxHealth: 1000,
      maxRegen: 50,
      damagedRegenDelay: 1,
      absorption: { physical: { min: 0.5, max: 0.5 } },
    },
  ],
};

const FULL = { shieldHealth: 1, armorHealth: 1 };

function profileOf(model: ModelDefense): KillProfile {
  return killProfile(
    model,
    shieldStatsFrom(model.shields),
    armorStatsFrom(model.armor),
  );
}

function gun(
  type: "physical" | "energy",
  perShot: number,
  sustained: number,
  duty: LoadoutWeapon["duty"] = { ratio: 1, offTime: 0, cycle: 0 },
  count = 1,
): LoadoutWeapon {
  return {
    id: `${type}-${perShot}`,
    name: type,
    beam: false,
    pelletsPerShot: 1,
    damagePerShot: {
      physical: 0,
      energy: 0,
      distortion: 0,
      thermal: 0,
      [type]: perShot,
    },
    count,
    sustainedDps: {
      physical: 0,
      energy: 0,
      distortion: 0,
      thermal: 0,
      [type]: sustained,
    },
    duty,
  };
}

describe("effectiveHp", () => {
  it("counts the physical that bleeds through the shield against the armor", () => {
    // 2000 raw drains the shield (half absorbed) while the other half takes
    // the armor's 500 HP at its 0.5 self multiplier; the hull adds 2000.
    const ehp = effectiveHp(profileOf(TARGET), FULL);

    expect(ehp.physical).toBeCloseTo(4000);
  });

  it("stacks shield, armor and hull for a type the shield soaks whole", () => {
    const ehp = effectiveHp(profileOf(TARGET), FULL);

    expect(ehp.energy).toBeCloseTo(3500);
    expect(ehp.thermal).toBeCloseTo(3500);
  });

  it("measures distortion against the shields alone", () => {
    expect(effectiveHp(profileOf(TARGET), FULL).distortion).toBeCloseTo(1000);
  });

  it("starts from the damaged state", () => {
    const ehp = effectiveHp(profileOf(TARGET), {
      shieldHealth: 0,
      armorHealth: 0,
    });

    expect(ehp.energy).toBeCloseTo(2000);
    expect(ehp.distortion).toBeCloseTo(0);
  });

  it("has no figure without hull health or shields", () => {
    const ehp = effectiveHp(
      profileOf({ ...TARGET, hullHealth: undefined, shields: [] }),
      FULL,
    );

    expect(ehp.physical).toBeNull();
    expect(ehp.distortion).toBeNull();
  });
});

describe("timeToKill", () => {
  it("divides the effective HP by the loadout's sustained damage", () => {
    const ttk = timeToKill(
      profileOf(TARGET),
      [gun("physical", 30, 100, undefined, 2)],
      FULL,
    );

    expect(ttk.shieldsDown).toBeCloseTo(10);
    expect(ttk.kill).toBeCloseTo(20);
  });

  it("lets the armor turn a gun away until the shields are down", () => {
    // 15 per shot, halved by the shield, does not beat a deflection of 10, so
    // the armor takes nothing until the shields are gone.
    const ttk = timeToKill(
      profileOf(TARGET),
      [gun("physical", 15, 100, undefined, 2)],
      FULL,
    );

    expect(ttk.shieldsDown).toBeCloseTo(10);
    expect(ttk.kill).toBeCloseTo(25);
  });

  it("lets the shields regenerate through a loadout's pauses", () => {
    // Three seconds off in every ten, one of them inside the regen delay: the
    // shields regenerate 20% of the time, 10 HP/s against 100 DPS.
    const ttk = timeToKill(
      profileOf(TARGET),
      [gun("energy", 50, 100, { ratio: 0.7, offTime: 3, cycle: 10 })],
      FULL,
    );

    expect(ttk.shieldsDown).toBeCloseTo(1000 / 90);
    expect(ttk.kill).toBeCloseTo(1000 / 90 + 5 + 20);
  });

  it("never drops shields that regenerate faster than the loadout hurts them", () => {
    const ttk = timeToKill(
      profileOf({
        ...TARGET,
        shields: [{ ...TARGET.shields[0], maxRegen: 1000 }],
      }),
      [gun("energy", 50, 100, { ratio: 0.5, offTime: 11, cycle: 20 })],
      FULL,
    );

    expect(ttk.shieldsDown).toBe(Infinity);
    expect(ttk.kill).toBe(Infinity);
  });

  it("has no kill time without hull health", () => {
    const ttk = timeToKill(
      profileOf({ ...TARGET, hullHealth: undefined }),
      [gun("energy", 50, 100)],
      FULL,
    );

    expect(ttk.shieldsDown).toBeCloseTo(10);
    expect(ttk.kill).toBeNull();
  });
});

describe("regenUptime", () => {
  it("is zero while any gun fires without stopping", () => {
    expect(
      regenUptime(
        [
          gun("energy", 50, 100, { ratio: 0.7, offTime: 3, cycle: 10 }),
          gun("physical", 30, 100),
        ],
        1,
      ),
    ).toBe(0);
  });

  it("ignores a gun that deals no sustained damage", () => {
    expect(
      regenUptime(
        [
          gun("energy", 50, 100, { ratio: 0.7, offTime: 3, cycle: 10 }),
          gun("physical", 30, 0),
        ],
        1,
      ),
    ).toBeCloseTo(0.2);
  });

  it("is zero when every pause is shorter than the regen delay", () => {
    expect(
      regenUptime(
        [gun("energy", 50, 100, { ratio: 0.9, offTime: 1, cycle: 10 })],
        1.5,
      ),
    ).toBe(0);
  });

  it("multiplies the pauses of independent guns", () => {
    expect(
      regenUptime(
        [
          gun("energy", 50, 100, { ratio: 0.7, offTime: 3, cycle: 10 }),
          gun("energy", 60, 100, { ratio: 0.5, offTime: 5, cycle: 10 }),
        ],
        1,
      ),
    ).toBeCloseTo(0.2 * 0.4);
  });
});
