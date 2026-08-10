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
  // User pip choices: target segments per family. A family with an override is
  // filled to that target instead of greedily — the interactive pip UI's input.
  overrides?: Partial<Record<PowerFamily, number>>;
};

// co(): the default auto-distribution (base pass Zn, then fill pass Jn), with an
// optional per-family override target (the pip UI). The cooler heat-balancing
// pass and refinements are not yet ported.
export function allocatePower(
  ports: PowerPort[],
  totalSegments: number,
  opts: AllocateOptions,
): AllocationState {
  const mode = opts.mode ?? "SCM";
  const state = emptyState(totalSegments);
  const of = (f: PowerFamily) => ports.filter((p) => p.family === f);

  // Fill a family to its override target if the user set one, else greedily.
  const fill = (f: PowerFamily) => {
    const target = opts.overrides?.[f];
    if (target === undefined) fillGreedy(of(f), state);
    else fillTo(of(f), f, target, state);
  };

  // Zn — base: critical blocks per family in priority order, weapon base 1.
  allocCritical(of("lifeSupport"), state);
  allocCritical(of("miningLaser"), state);
  allocCritical(of("salvage"), state);
  if (mode === "SCM") {
    allocCritical(of("emp"), state);
    // Weapons get a 1-segment base, unless the user explicitly overrides them
    // to fewer (letting the pip UI take weapons down to 0).
    const weaponBaseCap =
      opts.overrides?.weapon === undefined
        ? 1
        : Math.min(1, opts.overrides.weapon);
    weaponBase(of("weapon"), weaponBaseCap, state);
    allocCritical(of("shield"), state);
  } else {
    allocCritical(of("qdrive"), state);
  }
  allocCritical(of("radar"), state);
  allocCritical(of("engine"), state);

  // Jn — fill.
  fill("miningLaser");
  fill("salvage");
  if (mode === "SCM") {
    const weaponDefault = Math.min(opts.weaponConsumption, opts.weaponPoolSize);
    const weaponTarget = opts.overrides?.weapon ?? weaponDefault;
    fillTo(
      of("weapon"),
      "weapon",
      Math.min(weaponTarget, opts.weaponPoolSize, opts.weaponConsumption),
      state,
    );
    fill("shield");
    fill("radar");
    fill("engine");
  } else {
    fill("qdrive");
    fill("radar");
    fill("engine");
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
// `ceil(Σ units)` (the summed weapon consumption) are enabled.
export function weaponPoolBlocks(
  portPathPrefix: string,
  weaponUnitsSum: number,
  poolSize: number,
): PowerPort[] {
  const consumption = Math.ceil(weaponUnitsSum);
  return Array.from({ length: poolSize }, (_, i) => ({
    portPath: `${portPathPrefix}#${i}`,
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
