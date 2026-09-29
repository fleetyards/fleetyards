// Ship power-segment allocation. A power plant produces a number of power
// *segments*; the IFCS distributes them across component families (weapons,
// shields, engines, …). This module reproduces the game's default
// distribution and drives the interactive pip UI (users override per-port
// targets).

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

// A single allocatable segment block. Each family is modelled as a set of
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

// The atomic allocate — mark a block selected and debit the pools.
function alloc(state: AllocationState, port: PowerPort): void {
  port.selected = true;
  state.perPort[port.portPath] =
    (state.perPort[port.portPath] ?? 0) + port.size;
  state.perFamily[port.family] += port.size;
  state.remaining -= port.size;
}

// Base pass — allocate only the *critical* blocks that still fit.
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
  // Cooler output and heat generation. Without it the default distribution
  // skips every cooler pass.
  heat?: HeatModel;
};

export type Allocation = Pick<AllocationState, "perPort" | "perFamily">;

// A cooler as the heat passes see it. Below its `floor` (the mandatory block)
// it produces nothing.
export type CoolerModel = {
  portPath: string;
  units: number;
  floor: number;
  // Coolant per second at `segments` active segments.
  cooling: (segments: number) => number;
  // EM / IR emitted at `segments` active segments.
  signature: (segments: number) => { em: number; ir: number };
};

export type HeatModel = {
  // In installation order. The first cooler is sized before the fill pass.
  coolers: CoolerModel[];
  // Heat generated per second by an allocation.
  generation: (allocation: Allocation) => number;
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

// Quantum drive draws no power in SCM — it's a NAV-mode system.
const NAV_ONLY_FAMILIES: PowerFamily[] = ["qdrive"];

// With per-port targets, the families that fill to their maximum when a port
// has no target of its own; every other family stays at its critical floor.
const PRIMARY_FILL: Record<FlightMode, PowerFamily[]> = {
  SCM: ["weapon", "shield", "radar", "engine"],
  NAV: ["qdrive", "engine", "radar"],
};

// Fills each port toward its target: a per-port override, else a primary
// family's maximum, else its critical floor.
function allocateToTargets(
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

  // Skip a component when it's turned off (target 0), or when it's a NAV-only
  // system (quantum drive) in SCM that the user hasn't explicitly powered.
  const skip = (family: PowerFamily, portPath: string) => {
    if (overrides[portPath] === 0) return true;
    return (
      mode === "SCM" &&
      NAV_ONLY_FAMILIES.includes(family) &&
      overrides[portPath] === undefined
    );
  };

  // Base pass: mandatory critical blocks per family, in priority order.
  for (const family of priority) {
    allocCritical(
      of(family).filter((port) => !skip(family, port.portPath)),
      state,
    );
  }

  // Fill pass: each component to its target. An explicit override wins; else a
  // primary family fills to its max, and every other family stays at its
  // critical floor (its pips return to the pool).
  const primary = PRIMARY_FILL[mode];
  for (const family of priority) {
    const familyPorts = of(family);
    const isWeapon = family === "weapon";
    const isPrimary = primary.includes(family);
    const seen = new Set<string>();
    for (const port of familyPorts) {
      if (seen.has(port.portPath)) continue;
      seen.add(port.portPath);
      if (skip(family, port.portPath)) continue;

      const override = overrides[port.portPath];
      let target: number;
      if (override !== undefined) target = override;
      else if (isPrimary)
        target = isWeapon ? weaponCap : Number.POSITIVE_INFINITY;
      else continue; // non-primary, no override → criticals only

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

// Distributes the plant's segments across the ports. With `overrides` every
// port is filled toward its target; otherwise the game's default distribution
// runs, balancing the coolers against heat when a heat model is given.
export function allocatePower(
  ports: PowerPort[],
  totalSegments: number,
  opts: AllocateOptions,
): AllocationState {
  // Reset selection so the same ports can be re-allocated (e.g. baseline pass
  // then override pass).
  for (const port of ports) port.selected = false;
  if (opts.overrides) return allocateToTargets(ports, totalSegments, opts);
  return defaultDistribution(ports, totalSegments, opts);
}

// Heat comparisons tolerate float noise from the power-range modifiers.
const EPSILON = 1e-9;

// The heat-balance loop gives up after this many steps.
const MAX_BALANCE_STEPS = 200;

// Families the balance loop sheds a segment from when the ship runs hot: the
// preferred ones first, then the full list in order.
const SHED_FIRST: Record<FlightMode, PowerFamily[]> = {
  SCM: ["radar", "shield"],
  NAV: ["radar"],
};
const SHED_ANY: Record<FlightMode, PowerFamily[]> = {
  SCM: ["engine", "radar", "shield", "weapon", "lifeSupport"],
  NAV: ["radar", "engine", "weapon", "lifeSupport"],
};
// Families the balance loop grows into spare cooling headroom.
const GROW: PowerFamily[] = ["engine"];

// Signature scores within this margin count as a tie.
const SCORE_TIE = 1e-6;

class Distribution {
  readonly state: AllocationState;
  private readonly byFamily = new Map<PowerFamily, PowerPort[]>();

  constructor(
    readonly ports: PowerPort[],
    totalSegments: number,
    readonly mode: FlightMode,
    readonly weaponCap: number,
    readonly heat: HeatModel | undefined,
  ) {
    this.state = emptyState(totalSegments);
    for (const port of ports) {
      const list = this.byFamily.get(port.family) ?? [];
      list.push(port);
      this.byFamily.set(port.family, list);
    }
  }

  get coolers(): CoolerModel[] {
    return this.heat?.coolers ?? [];
  }

  family(family: PowerFamily): PowerPort[] {
    return this.byFamily.get(family) ?? [];
  }

  free(port: PowerPort): void {
    port.selected = false;
    const { state } = this;
    state.perPort[port.portPath] =
      (state.perPort[port.portPath] ?? 0) - port.size;
    if (state.perPort[port.portPath] <= 0) delete state.perPort[port.portPath];
    state.perFamily[port.family] -= port.size;
    state.remaining += port.size;
  }

  // Every critical block of a family that still fits.
  critical(family: PowerFamily): void {
    allocCritical(this.family(family), this.state);
  }

  // Blocks in order until one no longer fits.
  fill(family: PowerFamily): void {
    for (const port of this.family(family)) {
      if (port.disabled || port.selected) continue;
      if (port.size > this.state.remaining) break;
      alloc(this.state, port);
    }
  }

  // Up to `amount` more segments for a family.
  fillBy(family: PowerFamily, amount: number): void {
    this.fillBlocks(this.family(family), amount);
  }

  // Up to `amount` more segments for one port.
  fillPortBy(portPath: string, family: PowerFamily, amount: number): void {
    this.fillBlocks(
      this.family(family).filter((port) => port.portPath === portPath),
      amount,
    );
  }

  private fillBlocks(blocks: PowerPort[], amount: number): void {
    if (amount <= 0) return;
    let added = 0;
    for (const port of blocks) {
      if (port.disabled || port.selected) continue;
      if (added + port.size > amount || port.size > this.state.remaining) break;
      alloc(this.state, port);
      added += port.size;
      if (added >= amount) break;
    }
  }

  // Frees the last powered, non-critical block of the first family that has
  // one.
  shedOne(families: PowerFamily[]): boolean {
    for (const family of families) {
      const blocks = this.family(family);
      for (let i = blocks.length - 1; i >= 0; i--) {
        const port = blocks[i];
        if (!port.selected || port.critical) continue;
        this.free(port);
        return true;
      }
    }
    return false;
  }

  // Powers the next block of the first family whose block fits both the
  // segments left and the cooling headroom.
  growOne(families: PowerFamily[], headroom: number): boolean {
    for (const family of families) {
      for (const port of this.family(family)) {
        if (port.disabled || port.selected) continue;
        if (port.size > this.state.remaining || port.size > headroom + EPSILON)
          break;
        alloc(this.state, port);
        return true;
      }
    }
    return false;
  }

  balance(): { cooling: number; heat: number } {
    let cooling = 0;
    for (const cooler of this.coolers) {
      const segments = this.state.perPort[cooler.portPath] ?? 0;
      if (cooler.floor > 0 && segments >= cooler.floor) {
        cooling += cooler.cooling(segments);
      }
    }
    return { cooling, heat: this.heat?.generation(this.state) ?? 0 };
  }

  overheated(): boolean {
    const { cooling, heat } = this.balance();
    return heat > cooling + EPSILON;
  }

  snapshot() {
    return {
      selected: this.ports.map((port) => port.selected),
      remaining: this.state.remaining,
      perPort: { ...this.state.perPort },
      perFamily: { ...this.state.perFamily },
    };
  }

  restore(snapshot: ReturnType<Distribution["snapshot"]>): void {
    this.ports.forEach((port, i) => {
      port.selected = snapshot.selected[i];
    });
    this.state.remaining = snapshot.remaining;
    for (const key of Object.keys(this.state.perPort)) {
      delete this.state.perPort[key];
    }
    Object.assign(this.state.perPort, snapshot.perPort);
    Object.assign(this.state.perFamily, snapshot.perFamily);
  }
}

function defaultDistribution(
  ports: PowerPort[],
  totalSegments: number,
  opts: AllocateOptions,
): AllocationState {
  const mode = opts.mode ?? "SCM";
  const weaponCap = Math.min(opts.weaponConsumption, opts.weaponPoolSize);
  const d = new Distribution(ports, totalSegments, mode, weaponCap, opts.heat);

  basePass(d);

  const primary = d.coolers.at(0);
  if (primary && d.state.remaining > 0) {
    const segments = primaryCoolerSegments(d, primary);
    if (segments > 0) d.fillPortBy(primary.portPath, "coolers", segments);
  }

  fillPass(d);
  if (mode === "SCM" && d.state.remaining > 0) powerOtherCoolers(d, primary);
  balanceHeat(d, primary);
  if (mode === "SCM" && d.state.remaining > 0) topUpLifeSupport(d);
  splitCoolers(d);

  return d.state;
}

// The mandatory minimum per family, in priority order. Weapons get a single
// segment in SCM; the quantum drive only runs in NAV.
function basePass(d: Distribution): void {
  d.critical("lifeSupport");
  d.critical("miningLaser");
  d.critical("salvage");
  if (d.mode === "SCM") {
    d.critical("emp");
    weaponBase(d);
    d.critical("shield");
  } else {
    d.critical("qdrive");
  }
  d.critical("radar");
  d.critical("engine");
}

function weaponBase(d: Distribution): void {
  const target = Math.min(1, d.state.remaining);
  let added = 0;
  for (const port of d.family("weapon")) {
    if (added >= target) break;
    if (port.disabled || port.selected) continue;
    if (port.size > d.state.remaining) break;
    alloc(d.state, port);
    added += port.size;
  }
}

function fillPass(d: Distribution): void {
  d.fill("miningLaser");
  d.fill("salvage");
  if (d.mode === "SCM") {
    d.fillBy("weapon", d.weaponCap - d.state.perFamily.weapon);
    d.fill("shield");
    d.fill("radar");
    d.fill("engine");
  } else {
    d.fill("engine");
  }
}

// The smallest segment count from the cooler's floor up whose cooling covers
// the heat the ship would make once the fill pass has run on what is left.
function primaryCoolerSegments(d: Distribution, cooler: CoolerModel): number {
  if (!d.heat || cooler.floor <= 0 || cooler.floor > d.state.remaining) {
    return 0;
  }
  const max = Math.min(cooler.units, d.state.remaining);
  for (let segments = cooler.floor; segments <= max; segments++) {
    const heat = d.heat.generation(projectFill(d, cooler, segments));
    if (cooler.cooling(segments) >= heat) return segments;
  }
  return max;
}

// The allocation the fill pass would reach with `segments` on the cooler,
// counted per family. A family's projected segments are credited to its first
// enabled port.
function projectFill(
  d: Distribution,
  cooler: CoolerModel,
  segments: number,
): Allocation {
  const perPort = { ...d.state.perPort };
  const perFamily = { ...d.state.perFamily };
  perPort[cooler.portPath] = (perPort[cooler.portPath] ?? 0) + segments;
  perFamily.coolers += segments;
  let budget = d.state.remaining - segments;

  const project = (family: PowerFamily, target: number) => {
    const blocks = d.family(family).filter((port) => !port.disabled);
    if (blocks.length === 0 || budget <= 0) return;
    const capacity = blocks.reduce((sum, port) => sum + port.size, 0);
    const add = Math.min(
      Math.max(0, target - perFamily[family]),
      budget,
      capacity - perFamily[family],
    );
    if (add <= 0) return;
    perFamily[family] += add;
    const first = blocks[0].portPath;
    perPort[first] = (perPort[first] ?? 0) + add;
    budget -= add;
  };

  if (d.mode === "SCM") {
    project("weapon", d.weaponCap);
    project("shield", Number.POSITIVE_INFINITY);
    project("radar", Number.POSITIVE_INFINITY);
  }
  project("engine", Number.POSITIVE_INFINITY);

  return { perPort, perFamily };
}

// Brings the remaining coolers online block by block until cooling covers the
// heat.
function powerOtherCoolers(
  d: Distribution,
  primary: CoolerModel | undefined,
): void {
  for (const cooler of d.coolers) {
    if (cooler === primary) continue;
    for (const port of d.family("coolers")) {
      if (port.portPath !== cooler.portPath) continue;
      if (port.disabled || port.selected) continue;
      if (port.size > d.state.remaining) break;
      const { cooling, heat } = d.balance();
      if (cooling + EPSILON >= heat) return;
      alloc(d.state, port);
      if (d.state.remaining <= 0) return;
    }
  }
}

// Moves segments until cooling covers heat with as little spare as possible.
// Running hot: bring a cooler up to its floor, else shed a segment. Running
// cool: trim the primary cooler, else grow the engines into the headroom, else
// trade a shed segment for engine segments.
function balanceHeat(d: Distribution, primary: CoolerModel | undefined): void {
  if (d.coolers.length === 0) return;
  const shedFirst = SHED_FIRST[d.mode];
  const shedAny = SHED_ANY[d.mode];

  for (let step = 0; step < MAX_BALANCE_STEPS; step++) {
    const { cooling, heat } = d.balance();
    if (heat > cooling + EPSILON) {
      if (
        raiseCoolerToFloor(d, shedAny) ||
        d.shedOne(shedFirst) ||
        d.shedOne(shedAny)
      ) {
        continue;
      }
      return;
    }
    if (trimPrimaryCooler(d, primary)) continue;
    if (d.state.remaining <= 0) return;
    if (d.growOne(GROW, cooling - heat)) continue;
    if (!tradeForGrowth(d, shedFirst)) return;
  }
}

// Powers the first cooler sitting below its floor, shedding segments to make
// room for its mandatory block.
function raiseCoolerToFloor(d: Distribution, shed: PowerFamily[]): boolean {
  for (const cooler of d.coolers) {
    if (cooler.floor <= 0) continue;
    if ((d.state.perPort[cooler.portPath] ?? 0) >= cooler.floor) continue;
    while (d.state.remaining < cooler.floor) {
      if (!d.shedOne(shed)) return false;
    }
    d.fillPortBy(cooler.portPath, "coolers", cooler.floor);
    return true;
  }
  return false;
}

// Frees the primary cooler's last block when it stays above its floor and the
// ship stays cooled without it.
function trimPrimaryCooler(
  d: Distribution,
  primary: CoolerModel | undefined,
): boolean {
  if (!primary) return false;
  const powered = d
    .family("coolers")
    .filter((port) => port.selected && port.portPath === primary.portPath);
  const last = powered.at(-1);
  const total = powered.reduce((sum, port) => sum + port.size, 0);
  if (!last || total - last.size < primary.floor) return false;
  d.free(last);
  if (d.overheated()) {
    alloc(d.state, last);
    return false;
  }
  return true;
}

// Sheds one segment from a preferred family and regrows the engines into the
// freed headroom; kept only when it powers more segments and stays cooled.
function tradeForGrowth(d: Distribution, shed: PowerFamily[]): boolean {
  for (const family of shed) {
    const before = d.snapshot();
    if (!d.shedOne([family])) continue;
    for (
      let step = 0;
      step < MAX_BALANCE_STEPS && d.state.remaining > 0;
      step++
    ) {
      const { cooling, heat } = d.balance();
      if (!d.growOne(GROW, cooling - heat)) break;
    }
    if (d.state.remaining < before.remaining && !d.overheated()) return true;
    d.restore(before);
  }
  return false;
}

// Tops life support up block by block while the coolers keep up.
function topUpLifeSupport(d: Distribution): void {
  const hasCoolers = d.coolers.length > 0;
  for (const port of d.family("lifeSupport")) {
    if (port.disabled || port.selected) continue;
    if (port.size > d.state.remaining) break;
    alloc(d.state, port);
    if (hasCoolers && d.overheated()) {
      d.free(port);
      break;
    }
  }
}

// With two or more coolers, keeps their total and re-splits it to the
// combination that still covers the heat at the lowest EM + IR signature. IR
// counts at the cooling load it runs at. Ties go to the split that loads the
// earlier coolers more.
function splitCoolers(d: Distribution): void {
  const coolers = d.coolers.filter((cooler) => cooler.floor > 0);
  if (coolers.length < 2 || !d.heat) return;
  const total = d.state.perFamily.coolers;
  if (total <= 0) return;

  const others = { ...d.state.perPort };
  for (const cooler of coolers) delete others[cooler.portPath];

  const evaluate = (split: number[]) => {
    const perPort = { ...others };
    let cooling = 0;
    let em = 0;
    let ir = 0;
    split.forEach((segments, i) => {
      const cooler = coolers[i];
      if (segments > 0) perPort[cooler.portPath] = segments;
      if (segments < cooler.floor) return;
      cooling += cooler.cooling(segments);
      const signature = cooler.signature(segments);
      em += signature.em;
      ir += signature.ir;
    });
    const heat = d.heat!.generation({
      perPort,
      perFamily: d.state.perFamily,
    });
    const load = cooling > 0 ? Math.min(1, heat / cooling) : heat > 0 ? 1 : 0;
    return { covers: cooling + EPSILON >= heat, score: em + load * ir };
  };

  const current = coolers.map(
    (cooler) => d.state.perPort[cooler.portPath] ?? 0,
  );
  const initial = evaluate(current);
  if (!initial.covers) return;

  let best = current;
  let bestScore = initial.score;
  for (const split of coolerSplits(coolers, total)) {
    const { covers, score } = evaluate(split);
    if (!covers) continue;
    const better = score < bestScore - SCORE_TIE;
    const tie = score < bestScore + SCORE_TIE && lexicallyGreater(split, best);
    if (better || tie) {
      bestScore = score;
      best = split;
    }
  }
  if (best === current) return;

  const paths = new Set(coolers.map((cooler) => cooler.portPath));
  for (const port of d.family("coolers")) {
    if (port.selected && paths.has(port.portPath)) d.free(port);
  }
  best.forEach((segments, i) => {
    if (segments > 0) d.fillPortBy(coolers[i].portPath, "coolers", segments);
  });
}

// Every way to spread `total` segments over the coolers, each cooler either off
// or between its floor and its units.
function coolerSplits(coolers: CoolerModel[], total: number): number[][] {
  const splits: number[][] = [];
  const current: number[] = [];
  const walk = (index: number, left: number) => {
    if (index === coolers.length) {
      if (left === 0) splits.push([...current]);
      return;
    }
    const cooler = coolers[index];
    current.push(0);
    walk(index + 1, left);
    current.pop();
    for (let s = cooler.floor; s <= cooler.units && s <= left; s++) {
      current.push(s);
      walk(index + 1, left - s);
      current.pop();
    }
  };
  walk(0, total);
  return splits;
}

function lexicallyGreater(a: number[], b: number[]): boolean {
  for (let i = 0; i < a.length; i++) {
    if (a[i] !== b[i]) return a[i] > b[i];
  }
  return false;
}

// The weapon family's sustained-DPS power ratio = allocated weapon segments /
// weapon consumption (`poolRatio`). Equals `min(1, poolSize/consumption)`
// on ships with ample power, and less when the ship is segment-starved.
export function weaponPoolRatio(
  state: AllocationState,
  weaponConsumption: number,
): number {
  if (weaponConsumption <= 0) return 1;
  return Math.min(1, state.perFamily.weapon / weaponConsumption);
}

// --- Port construction ---------------------------------------------------
// Builds the `PowerPort[]` blocks a loadout feeds to `allocatePower`, from each
// component's Power draw. A component drawing `units` power becomes ~`round(units)`
// size-1 blocks, of which the minimum (`round(units × minimumFraction)`, or 1
// when there is no explicit minimum) is a single `critical` block that must stay
// powered. Weapons are special-cased into the shared weapon pool.

// A component's Power consumption, as read from parsed `power_consumption` /
// `power_ranges`. `minimumFraction` is the flow's `minimumConsumptionFraction`
// (0 for almost every component today).
export type PowerDraw = {
  units: number;
  minimumFraction?: number;
};

// The size of the mandatory (critical) block. Defaults to 1 segment when the
// component declares no minimum fraction (`minimumFraction || 1/units`).
export function criticalSize(units: number, minimumFraction?: number): number {
  if (units <= 0) return 0;
  const fraction = minimumFraction || 1 / units;
  return Math.round(units * fraction);
}

// A single non-weapon component's blocks — one `critical` block sized `K`,
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

// The shared weapon pool — `poolSize` size-1 blocks, of which the first
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

// Total available segments from the powered plants. A single plant yields
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
