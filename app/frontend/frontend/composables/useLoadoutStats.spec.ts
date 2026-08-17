import { describe, expect, it } from "vitest";
import {
  HardpointCategoryEnum,
  type Hardpoint,
  type ComponentWeapon,
} from "@/services/fyApi";
import { computeLoadoutStats } from "./useLoadoutStats";
import { WEAPON_POOL_PORT } from "./useLoadoutSim";

function weaponHardpoint(
  typeData: ComponentWeapon,
  children: Hardpoint[] = [],
  component: Partial<NonNullable<Hardpoint["component"]>> = {},
): Hardpoint {
  return {
    id: Math.random().toString(),
    name: "weapon",
    category: HardpointCategoryEnum.WEAPONS,
    component: {
      name: "Weapon",
      typeData,
      ...component,
    } as Hardpoint["component"],
    hardpoints: children,
    createdAt: "",
    updatedAt: "",
  } as Hardpoint;
}

// A power plant so the loadout has segments to allocate (the weapon power ratio
// follows the real allocation whenever segments exist).
function plant(powerBase = 40): Hardpoint {
  return {
    id: Math.random().toString(),
    name: "plant",
    category: HardpointCategoryEnum.POWERPLANT,
    component: {
      name: "Power Plant",
      size: "2",
      typeData: { powerBase },
    } as Hardpoint["component"],
    hardpoints: [],
    createdAt: "",
    updatedAt: "",
  } as Hardpoint;
}

describe("computeLoadoutStats", () => {
  it("returns empty stats when there are no weapons", () => {
    const stats = computeLoadoutStats([]);

    expect(stats.hasData).toBe(false);
    expect(stats.weaponCount).toBe(0);
    expect(stats.dps.total).toBe(0);
    expect(stats.alpha.total).toBe(0);
  });

  it("computes projectile DPS as alpha × fireRate / 60", () => {
    const stats = computeLoadoutStats([
      weaponHardpoint({
        fireRate: 60,
        pelletsPerShot: 1,
        damagePerShot: { energy: 4670.46 },
      }),
    ]);

    expect(stats.weaponCount).toBe(1);
    expect(stats.alpha.energy).toBeCloseTo(4670.46);
    expect(stats.dps.energy).toBeCloseTo(4670.46);
  });

  it("multiplies by pellet count and doubles the fire rate correctly", () => {
    const stats = computeLoadoutStats([
      weaponHardpoint({
        fireRate: 120,
        pelletsPerShot: 4,
        damagePerShot: { physical: 10 },
      }),
    ]);

    // alpha = 10 × 4 = 40; dps = 40 × 120 / 60 = 80
    expect(stats.alpha.physical).toBeCloseTo(40);
    expect(stats.dps.physical).toBeCloseTo(80);
  });

  it("uses damagePerSecond directly for beam weapons and skips alpha", () => {
    const stats = computeLoadoutStats([
      weaponHardpoint({
        beam: true,
        damagePerSecond: { energy: 500 },
      }),
    ]);

    expect(stats.dps.energy).toBeCloseTo(500);
    expect(stats.alpha.total).toBe(0);
  });

  it("excludes missiles from the totals", () => {
    const stats = computeLoadoutStats([
      weaponHardpoint({
        trackingSignal: "cross_section",
        damagePerShot: { physical: 9999 },
      } as ComponentWeapon),
    ]);

    expect(stats.weaponCount).toBe(0);
    expect(stats.hasData).toBe(false);
  });

  it("recurses into nested turret hardpoints and sums damage types", () => {
    const stats = computeLoadoutStats([
      weaponHardpoint(
        {
          fireRate: 60,
          damagePerShot: { energy: 100 },
        },
        [
          weaponHardpoint({
            fireRate: 60,
            damagePerShot: { physical: 50, distortion: 25 },
          }),
        ],
      ),
    ]);

    expect(stats.weaponCount).toBe(2);
    expect(stats.dps.energy).toBeCloseTo(100);
    expect(stats.dps.physical).toBeCloseTo(50);
    expect(stats.dps.distortion).toBeCloseTo(25);
    expect(stats.dps.total).toBeCloseTo(175);
  });

  it("has no sustained penalty when a weapon lacks regen and heat data", () => {
    const stats = computeLoadoutStats([
      weaponHardpoint({ fireRate: 60, damagePerShot: { energy: 100 } }),
    ]);

    expect(stats.dps.total).toBeCloseTo(100);
    expect(stats.sustainedDps.total).toBeCloseTo(100);
    expect(stats.weapons[0].sustainedDps).toBeCloseTo(100);
  });

  it("applies the energy-pool duty cycle to sustained DPS", () => {
    // pool 10 empties in 10s at 1 shot/s; refills at 5/s → 2s; no cooldown.
    // ratio = 10 / (10 + 0 + 2) = 0.8333
    const stats = computeLoadoutStats([
      weaponHardpoint({
        fireRate: 60,
        damagePerShot: { energy: 100 },
        regen: {
          maxAmmoLoad: 10,
          maxRegenPerSecond: 5,
          regenerationCooldown: 0,
        },
      }),
    ]);

    expect(stats.dps.energy).toBeCloseTo(100);
    expect(stats.sustainedDps.energy).toBeCloseTo(83.333, 2);
  });

  it("applies the overheat duty cycle to sustained DPS for ballistics", () => {
    // 10 heat/s reaches 100 in 10s; 10s overheat lockout → ratio 0.5
    const stats = computeLoadoutStats([
      weaponHardpoint({
        fireRate: 60,
        heatPerShot: 10,
        damagePerShot: { physical: 100 },
        heat: {
          overheatTemperature: 100,
          overheatFixTime: 10,
        },
      }),
    ]);

    expect(stats.dps.physical).toBeCloseTo(100);
    expect(stats.sustainedDps.physical).toBeCloseTo(50);
  });

  it("returns a per-weapon list sorted by DPS descending", () => {
    const stats = computeLoadoutStats([
      weaponHardpoint({ fireRate: 60, damagePerShot: { energy: 100 } }, [], {
        name: "Small Gun",
        size: "1",
      }),
      weaponHardpoint({ fireRate: 60, damagePerShot: { energy: 900 } }, [], {
        name: "Big Gun",
        size: "4",
      }),
    ]);

    expect(stats.weapons.map((w) => w.name)).toEqual(["Big Gun", "Small Gun"]);
    expect(stats.weapons[0].dps).toBeCloseTo(900);
    expect(stats.weapons[0].size).toBe("4");
    expect(stats.weapons[0].type).toBe("energy");
  });

  it("zeroes all weapon damage when energy weapons are unpowered (0 pips)", () => {
    const weapon = weaponHardpoint({
      fireRate: 60,
      pelletsPerShot: 1,
      damagePerShot: { energy: 100 },
      powerConsumption: 2,
      regen: { maxAmmoLoad: 10, maxRegenPerSecond: 5, regenerationCooldown: 0 },
    });

    expect(computeLoadoutStats([plant(), weapon], 4).dps.total).toBeGreaterThan(
      0,
    );

    const off = computeLoadoutStats([plant(), weapon], 4, {
      [WEAPON_POOL_PORT]: 0,
    });
    expect(off.dps.total).toBe(0);
    expect(off.sustainedDps.total).toBe(0);
    expect(off.alpha.total).toBe(0);
  });

  it("needs a weapon pip for ballistics, then fires them unthrottled", () => {
    // Heat-limited (no energy pool). Like erkul, ballistics still need the
    // weapon system powered (≥1 pip) to fire, but once on they aren't
    // throttled by the weapon pool — only their overheat duty cycle applies.
    const weapon = weaponHardpoint({
      fireRate: 60,
      pelletsPerShot: 1,
      damagePerShot: { physical: 100 },
      powerConsumption: 0.1,
      heat: { overheatTemperature: 100, overheatFixTime: 10 },
      heatPerShot: 10,
    });

    // 0 pips → off.
    const off = computeLoadoutStats([plant(), weapon], 4, {
      [WEAPON_POOL_PORT]: 0,
    });
    expect(off.dps.total).toBe(0);
    expect(off.alpha.total).toBe(0);

    // Powered → full burst and heat-limited sustained (0.5), not power-scaled.
    const on = computeLoadoutStats([plant(), weapon], 4);
    expect(on.dps.total).toBeCloseTo(100);
    expect(on.alpha.total).toBeCloseTo(100);
    expect(on.sustainedDps.total).toBeCloseTo(50);
  });
});
