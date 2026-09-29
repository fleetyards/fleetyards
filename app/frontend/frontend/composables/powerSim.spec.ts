import { describe, expect, it } from "vitest";
import {
  allocatePower,
  componentBlocks,
  totalSegments,
  weaponPoolBlocks,
  weaponPoolRatio,
  type CoolerModel,
  type HeatModel,
  type PowerPort,
} from "./powerSim";

// The weapon pool is `poolSize` size-1 blocks (all sharing one
// portPath), of which the first `consumption` are enabled (the rest disabled).
function weaponBlocks(poolSize: number, consumption: number): PowerPort[] {
  return Array.from({ length: poolSize }, (_, i) => ({
    portPath: "weaponPool",
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

// A cooler of `units` blocks (the first one critical) producing
// `perSegment` coolant per active segment.
function cooler(
  portPath: string,
  units: number,
  perSegment: number,
  emPerSegment = 0,
): { ports: PowerPort[]; model: CoolerModel } {
  return {
    ports: Array.from({ length: units }, (_, i) =>
      block(portPath, "coolers", { critical: i === 0 }),
    ),
    model: {
      portPath,
      units,
      floor: 1,
      cooling: (segments) => segments * perSegment,
      signature: (segments) => ({ em: segments * emPerSegment, ir: 0 }),
    },
  };
}

// Every powered segment makes one unit of heat.
function heatOf(...coolers: CoolerModel[]): HeatModel {
  return {
    coolers,
    generation: ({ perFamily }) =>
      Object.values(perFamily).reduce((sum, value) => sum + value, 0),
  };
}

function blocks(portPath: string, family: PowerPort["family"], count: number) {
  return Array.from({ length: count }, () => block(portPath, family));
}

const noWeapons = { weaponConsumption: 0, weaponPoolSize: 0 };

describe("allocatePower cooler passes", () => {
  it("sizes the first cooler to the fewest segments that cover the heat", () => {
    const a = cooler("a", 4, 2);
    const state = allocatePower([...a.ports, ...blocks("s", "shield", 3)], 20, {
      ...noWeapons,
      heat: heatOf(a.model),
    });

    // 3 shield + n cooler segments of heat against 2n cooling → n = 3.
    expect(state.perPort.a).toBe(3);
    expect(state.perFamily.shield).toBe(3);
  });

  it("brings the other coolers online until cooling covers the heat", () => {
    const a = cooler("a", 2, 2);
    const b = cooler("b", 4, 2);
    const state = allocatePower(
      [...a.ports, ...b.ports, ...blocks("s", "shield", 6)],
      20,
      { ...noWeapons, heat: heatOf(a.model, b.model) },
    );

    expect(state.perPort.a).toBe(2);
    expect(state.perPort.b).toBe(4);
    expect(state.perFamily.shield).toBe(6);
  });

  it("sheds radar before shields when the coolers can't keep up", () => {
    const a = cooler("a", 2, 2);
    const state = allocatePower(
      [...a.ports, ...blocks("s", "shield", 3), ...blocks("r", "radar", 3)],
      20,
      { ...noWeapons, heat: heatOf(a.model) },
    );

    // Cooling tops out at 4: the cooler's own 2 segments leave room for 2 more.
    expect(state.perPort.a).toBe(2);
    expect(state.perFamily.radar).toBe(0);
    expect(state.perFamily.shield).toBe(2);
  });

  it("tops life support up only while the coolers keep up", () => {
    const lifeSupport = () => [
      block("ls", "lifeSupport", { critical: true }),
      ...blocks("ls", "lifeSupport", 3),
    ];
    const a = cooler("a", 4, 2);

    const cooled = allocatePower([...a.ports, ...lifeSupport()], 20, {
      ...noWeapons,
      heat: heatOf(a.model),
    });
    expect(cooled.perFamily.lifeSupport).toBe(1);

    const unmodelled = allocatePower(lifeSupport(), 20, noWeapons);
    expect(unmodelled.perFamily.lifeSupport).toBe(4);
  });

  it("splits the cooler segments to the lowest signature that still cools", () => {
    const loud = cooler("loud", 3, 2, 10);
    const quiet = cooler("quiet", 3, 2, 1);
    const state = allocatePower(
      [...loud.ports, ...quiet.ports, ...blocks("s", "shield", 2)],
      20,
      { ...noWeapons, heat: heatOf(loud.model, quiet.model) },
    );

    expect(state.perPort.loud).toBeUndefined();
    expect(state.perPort.quiet).toBe(2);
    expect(state.perFamily.coolers).toBe(2);
  });

  it("leaves the coolers where the targets put them", () => {
    const a = cooler("a", 4, 2);
    const state = allocatePower([...a.ports, ...blocks("s", "shield", 6)], 20, {
      ...noWeapons,
      heat: heatOf(a.model),
      overrides: { a: 1, s: 6 },
    });

    expect(state.perPort.a).toBe(1);
    expect(state.perFamily.shield).toBe(6);
  });
});

describe("componentBlocks (le)", () => {
  it("returns nothing for a component with no power draw", () => {
    expect(componentBlocks("p", "radar", undefined)).toEqual([]);
    expect(componentBlocks("p", "radar", { units: 0 })).toEqual([]);
  });

  it("defaults to one critical block plus regular size-1 blocks (no minimum)", () => {
    // units 3, no minimumFraction → critical = round(3 × 1/3) = 1, regular = 2.
    const blocks = componentBlocks("rad", "radar", { units: 3 });
    expect(blocks).toHaveLength(3);
    expect(blocks[0]).toMatchObject({ size: 1, critical: true });
    expect(blocks.slice(1).every((b) => b.size === 1 && !b.critical)).toBe(
      true,
    );
    expect(blocks.reduce((s, b) => s + b.size, 0)).toBe(3);
  });

  it("sizes the critical block from an explicit minimum fraction", () => {
    // units 4, minimumFraction 0.5 → critical = round(4 × 0.5) = 2, regular = 2.
    const blocks = componentBlocks("ls", "lifeSupport", {
      units: 4,
      minimumFraction: 0.5,
    });
    expect(blocks[0]).toMatchObject({ size: 2, critical: true });
    expect(blocks.filter((b) => !b.critical)).toHaveLength(2);
    expect(blocks.reduce((s, b) => s + b.size, 0)).toBe(4);
  });
});

describe("weaponPoolBlocks (ue)", () => {
  it("builds poolSize blocks, enabling the first ceil(Σ units)", () => {
    // Asgard: pool 4, summed weapon units 7.8 → ceil = 8, all 4 enabled.
    const blocks = weaponPoolBlocks("wpn", 7.8, 4);
    expect(blocks).toHaveLength(4);
    expect(blocks.every((b) => !b.disabled)).toBe(true);
  });

  it("disables blocks beyond the summed consumption", () => {
    const blocks = weaponPoolBlocks("wpn", 2.4, 6);
    // ceil(2.4) = 3 enabled, 3 disabled.
    expect(blocks.filter((b) => !b.disabled)).toHaveLength(3);
    expect(blocks.filter((b) => b.disabled)).toHaveLength(3);
  });
});

describe("totalSegments (Et)", () => {
  it("returns the plant's units for a single powered plant", () => {
    expect(totalSegments([{ units: 20, size: 2, poweredOn: true }])).toBe(20);
  });

  it("ignores unpowered plants", () => {
    expect(
      totalSegments([
        { units: 20, size: 2, poweredOn: true },
        { units: 15, size: 2, poweredOn: false },
      ]),
    ).toBe(20);
  });

  it("adds the multi-plant coupling bonus ((count − 1) × Σ size)", () => {
    // two plants: round(20/2)+round(16/2) = 10+8 = 18, plus (2−1)×(2+2) = 4 → 22.
    expect(
      totalSegments([
        { units: 20, size: 2, poweredOn: true },
        { units: 16, size: 2, poweredOn: true },
      ]),
    ).toBe(22);
  });

  it("returns 0 when no plant is powered", () => {
    expect(totalSegments([{ units: 20, size: 2, poweredOn: false }])).toBe(0);
  });
});
