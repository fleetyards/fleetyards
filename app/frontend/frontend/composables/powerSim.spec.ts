import { describe, expect, it } from "vitest";
import { allocatePower, weaponPoolRatio, type PowerPort } from "./powerSim";

// erkul's `ue`: the weapon pool is `poolSize` size-1 blocks, of which the first
// `consumption` are enabled (the rest disabled).
function weaponBlocks(poolSize: number, consumption: number): PowerPort[] {
  return Array.from({ length: poolSize }, (_, i) => ({
    portPath: `w${i}`,
    family: "weapon" as const,
    size: 1,
    disabled: i >= consumption,
  }));
}

function block(
  portPath: string,
  family: PowerPort["family"],
  extra: Partial<PowerPort> = {},
): PowerPort {
  return { portPath, family, size: 1, ...extra };
}

describe("allocatePower", () => {
  it("fills weapons to min(consumption, poolSize) when power is ample (Asgard)", () => {
    // Asgard: weapon pool 4, consumption 8 → weapon gets 4 → ratio 0.5.
    const ports = weaponBlocks(4, 8);
    const state = allocatePower(ports, 20, {
      weaponConsumption: 8,
      weaponPoolSize: 4,
    });

    expect(state.perFamily.weapon).toBe(4);
    expect(weaponPoolRatio(state, 8)).toBeCloseTo(0.5);
  });

  it("caps weapon segments at consumption when the pool is larger", () => {
    // pool 10 but only 3 consumption → weapon fills to 3, ratio 1.
    const ports = weaponBlocks(10, 3);
    const state = allocatePower(ports, 20, {
      weaponConsumption: 3,
      weaponPoolSize: 10,
    });

    expect(state.perFamily.weapon).toBe(3);
    expect(weaponPoolRatio(state, 3)).toBe(1);
  });

  it("starves weapons when segments run out — the case the sim adds over max-power", () => {
    // Life support (critical, 2) + shield (3) consume first; only 3 segments
    // total, so weapons can't reach their pool of 4 → ratio drops below 0.5.
    const ports: PowerPort[] = [
      block("ls0", "lifeSupport", { critical: true }),
      block("ls1", "lifeSupport", { critical: true }),
      ...weaponBlocks(4, 8),
    ];
    const state = allocatePower(ports, 3, {
      weaponConsumption: 8,
      weaponPoolSize: 4,
    });

    // 2 segments to life support (critical, base), 1 left for the weapon fill.
    expect(state.perFamily.lifeSupport).toBe(2);
    expect(state.perFamily.weapon).toBe(1);
    expect(weaponPoolRatio(state, 8)).toBeCloseTo(1 / 8);
  });

  it("gives the weapon base segment before shields fill (SCM priority)", () => {
    const ports: PowerPort[] = [
      ...weaponBlocks(4, 8),
      block("s0", "shield"),
      block("s1", "shield"),
    ];
    // Only 1 segment: the weapon base (nt weapon 1) takes it before shield fill.
    const state = allocatePower(ports, 1, {
      weaponConsumption: 8,
      weaponPoolSize: 4,
    });

    expect(state.perFamily.weapon).toBe(1);
    expect(state.perFamily.shield).toBe(0);
  });
});
