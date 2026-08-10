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

// $: greedily fill a family until a block doesn't fit.
function fillGreedy(ports: PowerPort[], state: AllocationState): void {
  for (const p of ports) {
    if (p.disabled || p.selected) continue;
    if (p.size > state.remaining) break;
    alloc(state, p);
  }
}

// nt: allocate weapon blocks up to `cap` segments (the weapon base).
function weaponBase(
  ports: PowerPort[],
  cap: number,
  state: AllocationState,
): void {
  const target = Math.min(cap, state.remaining);
  let taken = 0;
  for (const p of ports) {
    if (taken >= target) break;
    if (p.disabled || p.selected) continue;
    if (p.size > state.remaining) break;
    alloc(state, p);
    taken += p.size;
  }
}

// et/ot: fill a family up to `target` total segments for that family.
function fillTo(
  ports: PowerPort[],
  family: PowerFamily,
  target: number,
  state: AllocationState,
): void {
  const need = target - state.perFamily[family];
  if (need <= 0) return;
  let taken = 0;
  for (const p of ports) {
    if (p.disabled || p.selected) continue;
    if (taken + p.size > need || p.size > state.remaining) break;
    alloc(state, p);
    taken += p.size;
    if (taken >= need) break;
  }
}

export type AllocateOptions = {
  mode?: FlightMode;
  // Weapon fill target = min(weaponConsumptionPoints, weaponPoolSize).
  weaponConsumption: number;
  weaponPoolSize: number;
};

// co(): the default auto-distribution (base pass Zn, then fill pass Jn).
// The cooler heat-balancing pass and refinements are not yet ported.
export function allocatePower(
  ports: PowerPort[],
  totalSegments: number,
  opts: AllocateOptions,
): AllocationState {
  const mode = opts.mode ?? "SCM";
  const state = emptyState(totalSegments);
  const of = (f: PowerFamily) => ports.filter((p) => p.family === f);

  // Zn — base: critical blocks per family in priority order, weapon base 1.
  allocCritical(of("lifeSupport"), state);
  allocCritical(of("miningLaser"), state);
  allocCritical(of("salvage"), state);
  if (mode === "SCM") {
    allocCritical(of("emp"), state);
    weaponBase(of("weapon"), 1, state);
    allocCritical(of("shield"), state);
  } else {
    allocCritical(of("qdrive"), state);
  }
  allocCritical(of("radar"), state);
  allocCritical(of("engine"), state);

  // Jn — fill.
  fillGreedy(of("miningLaser"), state);
  fillGreedy(of("salvage"), state);
  if (mode === "SCM") {
    fillTo(
      of("weapon"),
      "weapon",
      Math.min(opts.weaponConsumption, opts.weaponPoolSize),
      state,
    );
    fillGreedy(of("shield"), state);
    fillGreedy(of("radar"), state);
    fillGreedy(of("engine"), state);
  } else {
    fillGreedy(of("qdrive"), state);
    fillGreedy(of("radar"), state);
    fillGreedy(of("engine"), state);
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
