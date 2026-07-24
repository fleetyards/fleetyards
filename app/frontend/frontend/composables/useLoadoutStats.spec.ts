import { describe, expect, it } from "vitest";
import {
  HardpointCategoryEnum,
  type Hardpoint,
  type ComponentWeapon,
} from "@/services/fyApi";
import { computeLoadoutStats } from "./useLoadoutStats";

function weaponHardpoint(
  typeData: ComponentWeapon,
  children: Hardpoint[] = [],
  component: Partial<NonNullable<Hardpoint["component"]>> = {},
): Hardpoint {
  return {
    id: Math.random().toString(),
    name: "weapon",
    category: HardpointCategoryEnum.WEAPONS,
    component: { name: "Weapon", typeData, ...component } as Hardpoint["component"],
    hardpoints: children,
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

  it("returns a per-weapon list sorted by DPS descending", () => {
    const stats = computeLoadoutStats([
      weaponHardpoint(
        { fireRate: 60, damagePerShot: { energy: 100 } },
        [],
        { name: "Small Gun", size: "1" },
      ),
      weaponHardpoint(
        { fireRate: 60, damagePerShot: { energy: 900 } },
        [],
        { name: "Big Gun", size: "4" },
      ),
    ]);

    expect(stats.weapons.map((w) => w.name)).toEqual(["Big Gun", "Small Gun"]);
    expect(stats.weapons[0].dps).toBeCloseTo(900);
    expect(stats.weapons[0].size).toBe("4");
  });
});
