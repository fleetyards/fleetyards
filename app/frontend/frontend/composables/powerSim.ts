// Ship power-segment allocation — ported from erkul's `co()` engine
// (chunk-FWWRRMGF.js). A power plant produces a number of power *segments*; the
// IFCS distributes them across component families (weapons, shields, engines,
// …). This module reproduces that default auto-distribution and is the engine
// the future interactive pip UI will drive (users override per-family targets).
//
// Ported so far: the allocation state + atomic primitives (D/W/$/nt/et/ot) and
// the SCM/NAV base+fill passes (Zn/Jn). Deferred (documented in
// docs/exec-plans/flight-power-heat-sim.md): the cooler heat-balancing pass
// (`ft`, needs the heat model), the refinement passes (`Ct`/`rt`), and building
// the ports from live loadout data.

export type PowerFamily =
  | "weapon"
  | "engine"
  | "shield"
  | "qdrive"
  | "radar"
  | "lifeSupport"
  | "coolers"
  | "qed"
  | "emp"
  | "miningLaser"
  | "salvage"
  | "tractorBeam"
  | "towingbeam";

export const POWER_FAMILIES: PowerFamily[] = [
  "weapon",
  "engine",
  "shield",
  "qdrive",
  "radar",
  "lifeSupport",
  "coolers",
  "qed",
  "emp",
  "miningLaser",
  "salvage",
  "tractorBeam",
  "towingbeam",
];

// A single allocatable segment block. erkul models each family as a set of
// size-1 blocks (e.g. the weapon pool is `poolSize` blocks, of which
// `consumption` are enabled); `critical` blocks (life support) must be powered.
export type PowerPort = {
  portPath: string;
  family: PowerFamily;
  size: number;
  critical?: boolean;
  disabled?: boolean;
  selected?: boolean;
};

export type FlightMode = "SCM" | "NAV";

export type AllocationState = {
  remaining: number;
  perFamily: Record<PowerFamily, number>;
  perPort: Record<string, number>;
};

function emptyState(total: number): AllocationState {
  const perFamily = Object.fromEntries(
    POWER_FAMILIES.map((f) => [f, 0]),
  ) as Record<PowerFamily, number>;
  return { remaining: total, perFamily, perPort: {} };
}

// D: the atomic allocate — mark a block selected and debit the pools.
function alloc(state: AllocationState, port: PowerPort): void {
  port.selected = true;
  state.perPort[port.portPath] =
    (state.perPort[port.portPath] ?? 0) + port.size;
  state.perFamily[port.family] += port.size;
  state.remaining -= port.size;
}

// W: base pass — allocate only the *critical* blocks that still fit.
function allocCritical(ports: PowerPort[], state: AllocationState): void {
  for (const p of ports) {
    if (!p.disabled && p.critical && !p.selected && p.size <= state.remaining) {
      alloc(state, p);
    }
  }
}

// Fill a single port (component) toward `target` total segments for that port,
// taking blocks that still fit. The shared weapon pool is one port; every other
// component is its own port.
function fillPortTo(
  ports: PowerPort[],
  portPath: string,
  target: number,
  state: AllocationState,
): void {
  for (const p of ports) {
    if (p.portPath !== portPath || p.disabled || p.selected) continue;
    if ((state.perPort[portPath] ?? 0) >= target) break;
    if (p.size > state.remaining) break;
    alloc(state, p);
  }
}

// The shared weapon-pool port. All weapon blocks share this portPath so the pool
// is one column in the UI and one override key.
export const WEAPON_POOL_PORT = "weaponPool";

// User pip choices: target segments per component (by portPath), the weapon pool
// keyed by WEAPON_POOL_PORT.
export type PortOverrides = Record<string, number>;

export type AllocateOptions = {
  mode?: FlightMode;
  // Weapon fill target = min(weaponConsumptionPoints, weaponPoolSize).
  weaponConsumption: number;
  weaponPoolSize: number;
  overrides?: PortOverrides;
};

const SCM_PRIORITY: PowerFamily[] = [
  "lifeSupport",
  "miningLaser",
  "salvage",
  "emp",
  "weapon",
  "shield",
  "radar",
  "engine",
  "coolers",
  "qdrive",
  "qed",
  "tractorBeam",
  "towingbeam",
];

const NAV_PRIORITY: PowerFamily[] = [
  "lifeSupport",
  "miningLaser",
  "salvage",
  "qdrive",
  "radar",
  "engine",
  "shield",
  "coolers",
  "weapon",
  "emp",
  "qed",
  "tractorBeam",
  "towingbeam",
];

// co(): the auto-distribution — mandatory criticals first, then each component
// filled toward its target (a per-port override, else its natural maximum) in
// family-priority order. The cooler heat-balancing pass is not yet ported.
export function allocatePower(
  ports: PowerPort[],
  totalSegments: number,
  opts: AllocateOptions,
): AllocationState {
  const mode = opts.mode ?? "SCM";
  const state = emptyState(totalSegments);
  const overrides = opts.overrides ?? {};
  const of = (f: PowerFamily) => ports.filter((p) => p.family === f);
  const weaponCap = Math.min(opts.weaponConsumption, opts.weaponPoolSize);
  const priority = mode === "SCM" ? SCM_PRIORITY : NAV_PRIORITY;

  // Base pass: mandatory critical blocks per family, in priority order.
  for (const family of priority) allocCritical(of(family), state);

  // Fill pass: each distinct component (portPath) up to its target.
  for (const family of priority) {
    const familyPorts = of(family);
    const seen = new Set<string>();
    for (const port of familyPorts) {
      if (seen.has(port.portPath)) continue;
      seen.add(port.portPath);
      const isWeapon = family === "weapon";
      const target =
        overrides[port.portPath] ??
        (isWeapon ? weaponCap : Number.POSITIVE_INFINITY);
      fillPortTo(
        familyPorts,
        port.portPath,
        isWeapon ? Math.min(target, weaponCap) : target,
        state,
      );
    }
  }

  return state;
}

// The weapon family's sustained-DPS power ratio = allocated weapon segments /
// weapon consumption (erkul's `poolRatio`). Equals `min(1, poolSize/consumption)`
// on ships with ample power, and less when the ship is segment-starved.
export function weaponPoolRatio(
  state: AllocationState,
  weaponConsumption: number,
): number {
  if (weaponConsumption <= 0) return 1;
  return Math.min(1, state.perFamily.weapon / weaponConsumption);
}

// --- Port construction (erkul `z`/`K`/`le`/`ue`/`Et`) --------------------
// Builds the `PowerPort[]` blocks a loadout feeds to `allocatePower`, from each
// component's Power draw. A component drawing `units` power becomes ~`round(units)`
// size-1 blocks, of which the minimum (`round(units × minimumFraction)`, or 1
// when there is no explicit minimum) is a single `critical` block that must stay
// powered. Weapons are special-cased into the shared weapon pool (`ue`).

// A component's Power consumption, as read from parsed `power_consumption` /
// `power_ranges`. `minimumFraction` is the flow's `minimumConsumptionFraction`
// (0 for almost every component today).
export type PowerDraw = {
  units: number;
  minimumFraction?: number;
};

// K: the size of the mandatory (critical) block. Defaults to 1 segment when the
// component declares no minimum fraction (`minimumFraction || 1/units`).
function criticalSize(units: number, minimumFraction?: number): number {
  if (units <= 0) return 0;
  const fraction = minimumFraction || 1 / units;
  return Math.round(units * fraction);
}

// le: a single non-weapon component's blocks — one `critical` block sized `K`,
// then `round(units − K)` regular size-1 blocks.
export function componentBlocks(
  portPath: string,
  family: PowerFamily,
  draw: PowerDraw | undefined,
): PowerPort[] {
  if (!draw || draw.units <= 0) return [];
  const critical = criticalSize(draw.units, draw.minimumFraction);
  const regular = Math.max(0, Math.round(draw.units - critical));
  const blocks: PowerPort[] = [];
  if (critical > 0) {
    blocks.push({ portPath, family, size: critical, critical: true });
  }
  for (let i = 0; i < regular; i++) {
    blocks.push({ portPath, family, size: 1 });
  }
  return blocks;
}

// ue: the shared weapon pool — `poolSize` size-1 blocks, of which the first
// `ceil(Σ units)` (the summed weapon consumption) are enabled. All blocks share
// one portPath so the pool is a single column / override key.
export function weaponPoolBlocks(
  portPath: string,
  weaponUnitsSum: number,
  poolSize: number,
): PowerPort[] {
  const consumption = Math.ceil(weaponUnitsSum);
  return Array.from({ length: poolSize }, (_, i) => ({
    portPath,
    family: "weapon" as const,
    size: 1,
    disabled: i >= consumption,
  }));
}

// Et: total available segments from the powered plants. A single plant yields
// its `units`; multiple plants add a `(count − 1) × Σ size` coupling bonus.
export function totalSegments(
  plants: { units: number; size: number; poweredOn: boolean }[],
): number {
  const powered = plants.filter((p) => p.poweredOn);
  if (powered.length === 0) return 0;
  let units = 0;
  let sizeSum = 0;
  for (const p of powered) {
    units += Math.round(p.units / powered.length);
    sizeSum += p.size;
  }
  return units + (powered.length - 1) * sizeSum;
}
