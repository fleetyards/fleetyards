import { computed, toValue, type MaybeRefOrGetter } from "vue";
import { HardpointCategoryEnum, type Hardpoint } from "@/services/fyApi";
import {
  allocatePower,
  componentBlocks,
  POWER_FAMILIES,
  totalSegments,
  weaponPoolBlocks,
  weaponPoolRatio,
  WEAPON_POOL_PORT,
  type AllocationState,
  type FlightMode,
  type PortOverrides,
  type PowerFamily,
  type PowerPort,
} from "./powerSim";

export { WEAPON_POOL_PORT, type PortOverrides } from "./powerSim";

// One controllable unit inside a column: a single component (or the shared
// weapon pool). `min` is the mandatory floor — the unit is either off (0) or on
// at ≥ `min` segments (min === capacity for all-critical systems like the QD).
// `capacity` is every rendered slot; `fillable` is how many can actually take
// power (they differ only for the weapon pool, which shows its full pool but is
// fillable only up to the mounted energy weapons' demand).
export type PowerColumnMember = {
  portPath: string;
  label?: string;
  allocated: number;
  capacity: number;
  fillable: number;
  min: number;
};

// A single column in the pip UI. Most families render one column per component;
// grouped families (shields, tractor/towing beams) stack every component into
// one column with a `members` entry per generator/beam so each can be toggled
// individually. Column-level `allocated`/`capacity`/`min` sum the members.
export type PowerColumn = PowerColumnMember & {
  family: PowerFamily;
  members: PowerColumnMember[];
};

// Families whose components stack into a single column (each still individually
// toggleable). Everything else — notably coolers — is one column per component.
const GROUPED_FAMILIES = new Set<PowerFamily>([
  "shield",
  "tractorBeam",
  "towingbeam",
]);

// Families that emit extra component heat on top of their active segments
// (erkul's `l` term in the heat-generation sum): shields, life support, radar
// and the quantum drive.
const EXTRA_HEAT_FAMILIES = new Set<PowerFamily>([
  "shield",
  "lifeSupport",
  "radar",
  "qdrive",
]);

// Families whose active segments generate no heat load (matching erkul, where
// powering the tractor/towing beams doesn't change the cooling ratio).
const NON_HEAT_FAMILIES = new Set<PowerFamily>(["tractorBeam", "towingbeam"]);

// A component's power-range modifier curve — `{start, modifier}` breakpoints
// sorted ascending by `start`. The modifier for a given active-segment count is
// the entry with the greatest `start` ≤ segments (erkul's `L`), default 1.
type PowerRange = { start: number; modifier: number };

function toRanges(raw: unknown): PowerRange[] {
  if (!raw || typeof raw !== "object") return [];
  return Object.values(raw as Record<string, unknown>)
    .filter((r): r is Record<string, unknown> => !!r && typeof r === "object")
    .map((r) => ({ start: numeric(r.start), modifier: numeric(r.modifier) }))
    .sort((a, b) => a.start - b.start);
}

function rangeModifier(ranges: PowerRange[], segments: number): number {
  let modifier = 1;
  for (const range of ranges) {
    if (range.start <= segments) modifier = range.modifier;
    else break;
  }
  return modifier;
}

// A power-drawing component captured for the heat pass: its allocated segments
// come from the allocation state (by portPath). Coolers additionally carry the
// coolant they produce at full power (`coolingRate`); `irNominal` is the
// component's infrared signature emission at full power.
type HeatComponent = {
  portPath: string;
  family: PowerFamily;
  units: number;
  ranges: PowerRange[];
  coolingRate: number;
  irNominal: number;
  emNominal: number;
};

// A power plant as an EM source (plants emit the most EM, weighted by ship-wide
// power utilization) and a segment source.
type PowerPlant = {
  units: number;
  size: number;
  poweredOn: boolean;
  emNominal: number;
  ranges: PowerRange[];
};

// A weapon's EM contribution (per-weapon nominal + its power-range curve).
type WeaponEmSource = { emNominal: number; ranges: PowerRange[] };

// FleetYards hardpoint category → erkul power family. Only the families erkul
// feeds power segments to are mapped; every other category (thrusters, fuel,
// cargo, seats, …) draws no segments. A mapped component still contributes
// ports only when it actually declares a Power draw (`powerConsumption`).
export const POWER_FAMILY_BY_CATEGORY: Partial<
  Record<HardpointCategoryEnum, PowerFamily>
> = {
  [HardpointCategoryEnum.WEAPONS]: "weapon",
  [HardpointCategoryEnum.WEAPON_MOUNTS]: "weapon",
  [HardpointCategoryEnum.TURRET]: "weapon",
  [HardpointCategoryEnum.SHIELDGENERATOR]: "shield",
  [HardpointCategoryEnum.COOLER]: "coolers",
  [HardpointCategoryEnum.RADAR]: "radar",
  [HardpointCategoryEnum.QUANTUMDRIVE]: "qdrive",
  [HardpointCategoryEnum.QUANTUMENFORCEMENTDEVICE]: "qed",
  [HardpointCategoryEnum.EMP]: "emp",
  [HardpointCategoryEnum.LIFESUPPORT]: "lifeSupport",
  [HardpointCategoryEnum.CONTROLLER]: "engine",
  [HardpointCategoryEnum.SALVAGEMUNCHING]: "salvage",
};

export type LoadoutSimResult = {
  totalSegments: number;
  remaining: number;
  perFamily: Record<PowerFamily, number>;
  // Per-component (+ weapon pool) columns for the pip UI, in display order.
  columns: PowerColumn[];
  // Weapon sustained-DPS ratio at the *current* allocation (reflects overrides).
  weaponPoolRatio: number;
  // Weapon sustained-DPS ratio with weapons at maximum pips (other families
  // dropped to their mandatory minimums) — the max-power model sustained DPS
  // uses as its baseline. Equals min(1, poolSize/consumption) unless the plant
  // literally can't deliver enough segments to fill the pool.
  weaponMaxRatio: number;
  // Shield power ratio (allocated shield segments / capacity) — scales shield
  // HP/regen; 0 when shields are unpowered.
  shieldPoolRatio: number;
  // Engine power relative to the default distribution — scales flight speed and
  // handling; 1 at the default, 0 when the engine is fully unpowered.
  enginePowerRatio: number;
  // Effective aim-assist range (m) at the current radar power, and the radar's
  // max (for the bar's full scale). 0 when there's no radar / it's unpowered.
  aimAssist: number;
  aimAssistMax: number;
  // Heat: coolant produced per second at the current allocation, the maximum
  // coolers could produce, the heat generated, and the cooling load — heat ÷
  // coolant (erkul's `coolingRatio`, uncapped so > 1 when under-cooled; 0 with
  // no active cooler). It also drives the IR signature.
  coolingPerSec: number;
  coolingMaxPerSec: number;
  heatGeneration: number;
  coolingRatio: number;
  // Emitted infrared signature at the current allocation (scaled by cooling).
  emittedIr: number;
  // Emitted electromagnetic signature at the current allocation.
  emittedEm: number;
};

// Ships run only the first N shields at once (the vehicle's Dynamic Shield power
// pool `maxItemCount`); the rest are unpowered backups. 2 is the game default.
export const DEFAULT_SHIELD_MAX_ITEM_COUNT = 2;

type Collected = {
  plants: PowerPlant[];
  weaponUnits: number;
  weaponEmSources: WeaponEmSource[];
  otherPorts: PowerPort[];
  portLabels: Record<string, string>;
  shieldsSeen: number;
  radarAim?: { min: number; max: number };
  components: HeatComponent[];
};

function numeric(value: unknown): number {
  const n = Number(value);
  return Number.isFinite(n) ? n : 0;
}

// Walk the hardpoint tree, gathering the powered plants (segment sources), the
// summed weapon Power draw (the shared pool), and the per-component blocks for
// every other power-drawing family. Shields beyond `shieldMaxItemCount` are
// backups and draw no power.
function collectPorts(
  hardpoints: Hardpoint[] | undefined,
  acc: Collected,
  shieldMaxItemCount: number,
): Collected {
  for (const hardpoint of hardpoints ?? []) {
    const typeData = hardpoint.component?.typeData as
      Record<string, unknown> | undefined;
    const category = hardpoint.category;

    if (typeData && category) {
      if (category === HardpointCategoryEnum.POWERPLANT) {
        const units = numeric(typeData.powerBase);
        if (units > 0) {
          acc.plants.push({
            units,
            size: numeric(hardpoint.component?.size),
            poweredOn: true,
            emNominal: numeric(typeData.signatureEm),
            ranges: toRanges(typeData.powerRanges),
          });
        }
      } else {
        // Tractor/towing beams are miscategorised (weapons/turret/unknown), so
        // their component type is the reliable signal — it also keeps them out
        // of the shared weapon pool.
        const componentType = hardpoint.component?.type;
        let family = POWER_FAMILY_BY_CATEGORY[category];
        if (componentType === "TractorBeam") family = "tractorBeam";
        else if (componentType === "TowingBeam") family = "towingbeam";
        const draw = numeric(typeData.powerConsumption);
        if (family === "weapon") {
          acc.weaponUnits += draw;
          const emNominal = numeric(typeData.signatureEm);
          if (emNominal > 0) {
            acc.weaponEmSources.push({
              emNominal,
              ranges: toRanges(typeData.powerRanges),
            });
          }
        } else if (family && draw > 0) {
          // Shields past the active cap are unpowered backups.
          const isBackupShield =
            family === "shield" && ++acc.shieldsSeen > shieldMaxItemCount;
          if (!isBackupShield) {
            // One column per component (each shield generator included) so any
            // single generator can be toggled independently.
            const minimumFraction =
              typeData.powerMinimumFraction == null
                ? undefined
                : numeric(typeData.powerMinimumFraction);
            acc.otherPorts.push(
              ...componentBlocks(hardpoint.id, family, {
                units: draw,
                minimumFraction,
              }),
            );
            acc.components.push({
              portPath: hardpoint.id,
              family,
              units: draw,
              ranges: toRanges(typeData.powerRanges),
              coolingRate:
                family === "coolers" ? numeric(typeData.coolingRate) : 0,
              irNominal: numeric(typeData.signatureIr),
              emNominal: numeric(typeData.signatureEm),
            });
            if (hardpoint.component?.name) {
              acc.portLabels[hardpoint.id] = hardpoint.component.name;
            }
            // Capture the radar's aim-assist range for the power-pane readout.
            if (
              family === "radar" &&
              !acc.radarAim &&
              typeData.aimAssistRange
            ) {
              acc.radarAim = {
                min: numeric(typeData.aimAssistMin),
                max: numeric(typeData.aimAssistRange),
              };
            }
          }
        }
      }
    }

    if (hardpoint.hardpoints?.length) {
      collectPorts(hardpoint.hardpoints, acc, shieldMaxItemCount);
    }
  }

  return acc;
}

// The weapon ratio with weapons maxed: after every family's mandatory (critical)
// blocks are reserved, weapons fill their pool with what's left. Falls back to
// the segment-independent min(1, poolSize/consumption) when there is no plant
// data to cap against — so it never regresses ships whose plant power isn't
// (yet) parsed.
function computeWeaponMaxRatio(
  pool: number,
  consumption: number,
  segments: number,
  otherPorts: PowerPort[],
): number {
  if (pool <= 0 || consumption <= 0) return 1;
  const uncapped = Math.min(1, pool / consumption);
  if (segments <= 0) return uncapped;

  const nonWeaponCritical = otherPorts
    .filter((port) => port.critical)
    .reduce((sum, port) => sum + port.size, 0);
  const enabled = Math.min(pool, consumption);
  const weaponMax = Math.max(
    0,
    Math.min(enabled, segments - nonWeaponCritical),
  );
  return Math.min(uncapped, weaponMax / consumption);
}

// Group the allocation into display columns: one member per component (+ the
// shared weapon pool), with grouped families stacking their members into a
// single column. Ordered by family, dropping ports with no capacity.
function buildColumns(
  ports: PowerPort[],
  portLabels: Record<string, string>,
  state: AllocationState,
): PowerColumn[] {
  const byPort = new Map<
    string,
    {
      family: PowerFamily;
      capacity: number;
      fillable: number;
      critical: number;
    }
  >();
  const order: string[] = [];
  for (const port of ports) {
    let entry = byPort.get(port.portPath);
    if (!entry) {
      entry = { family: port.family, capacity: 0, fillable: 0, critical: 0 };
      byPort.set(port.portPath, entry);
      order.push(port.portPath);
    }
    // Every block is a rendered slot; only enabled ones can take power. They
    // differ only for the weapon pool's headroom past the weapons' demand.
    entry.capacity += port.size;
    if (!port.disabled) {
      entry.fillable += port.size;
      if (port.critical) entry.critical += port.size;
    }
  }

  const columns: PowerColumn[] = [];
  const grouped = new Map<PowerFamily, PowerColumn>();
  for (const portPath of order) {
    const entry = byPort.get(portPath)!;
    if (entry.capacity <= 0) continue;
    const member: PowerColumnMember = {
      portPath,
      label: portPath === WEAPON_POOL_PORT ? undefined : portLabels[portPath],
      allocated: state.perPort[portPath] ?? 0,
      capacity: entry.capacity,
      fillable: entry.fillable,
      // Mandatory floor: a component is either off or on at ≥ this many
      // segments (equals capacity for all-critical systems like the QD).
      min: entry.critical,
    };

    if (GROUPED_FAMILIES.has(entry.family)) {
      let column = grouped.get(entry.family);
      if (!column) {
        column = {
          ...member,
          allocated: 0,
          capacity: 0,
          fillable: 0,
          min: 0,
          label: undefined,
          family: entry.family,
          members: [],
        };
        grouped.set(entry.family, column);
        columns.push(column);
      }
      column.members.push(member);
      column.allocated += member.allocated;
      column.capacity += member.capacity;
      column.fillable += member.fillable;
      column.min += member.min;
    } else {
      columns.push({ ...member, family: entry.family, members: [member] });
    }
  }

  return columns.sort(
    (a, b) =>
      POWER_FAMILIES.indexOf(a.family) - POWER_FAMILIES.indexOf(b.family),
  );
}

// Heat pass (erkul's `Ze`/`G`): coolers turn active power segments into coolant;
// every powered component generates heat. `coolingRatio` is the cooling *load* —
// heat generated ÷ coolant provided — so it rises above 1 when the active
// coolers can't keep up, and is 0 when no cooler is powered (there is no active
// cooling system to load). It also drives the IR signature.
function computeHeat(
  components: HeatComponent[],
  usedSegments: number,
  perPort: Record<string, number>,
): {
  coolingPerSec: number;
  coolingMaxPerSec: number;
  heatGeneration: number;
  coolingRatio: number;
  emittedIr: number;
} {
  let coolingPerSec = 0;
  let coolingMaxPerSec = 0;
  let extraHeat = 0;
  let nonHeatSegments = 0;
  let irRaw = 0;

  for (const component of components) {
    const active = perPort[component.portPath] ?? 0;
    if (component.family === "coolers" && component.units > 0) {
      const modifier = rangeModifier(component.ranges, active);
      coolingPerSec +=
        component.coolingRate * (active / component.units) * modifier;
      coolingMaxPerSec +=
        component.coolingRate *
        rangeModifier(component.ranges, component.units);
      // IR is emitted by the active coolers (erkul's `gr` over heat sources).
      if (active > 0) {
        irRaw += component.irNominal * (active / component.units) * modifier;
      }
    }
    if (active > 0 && EXTRA_HEAT_FAMILIES.has(component.family)) {
      extraHeat += active * rangeModifier(component.ranges, active);
    }
    if (NON_HEAT_FAMILIES.has(component.family)) {
      nonHeatSegments += active;
    }
  }

  // Heat generated = every active power segment (minus the families that emit
  // none, e.g. tractor beams), plus the extra component heat.
  const heatGeneration = usedSegments - nonHeatSegments + extraHeat;
  // Cooling load: heat ÷ coolant provided (uncapped, so > 1 when under-cooled);
  // 0 when no cooler is powered.
  const coolingRatio = coolingPerSec > 0 ? heatGeneration / coolingPerSec : 0;
  // Emitted IR signature scales with the active cooling (0 when cooling is off).
  const emittedIr = irRaw * coolingRatio;

  return {
    coolingPerSec,
    coolingMaxPerSec,
    heatGeneration,
    coolingRatio,
    emittedIr,
  };
}

// EM signature (erkul's `yr`): power plants weighted by ship-wide power
// utilization, weapons weighted by their pool fill ratio, and every other
// powered component scaled by its active-segment fraction — each × its
// power-range modifier and nominal EM emission.
function computeEm(
  plants: PowerPlant[],
  weaponEmSources: WeaponEmSource[],
  components: HeatComponent[],
  perPort: Record<string, number>,
  usedSegments: number,
  totalSegments: number,
  weaponAllocated: number,
  weaponRatio: number,
): number {
  let em = 0;

  const poweredPlants = plants.filter((plant) => plant.poweredOn);
  if (poweredPlants.length > 0 && totalSegments > 0) {
    const utilization = usedSegments / totalSegments;
    const perPlant = Math.round(usedSegments) / poweredPlants.length;
    const plantSum = poweredPlants.reduce(
      (sum, plant) =>
        sum + plant.emNominal * rangeModifier(plant.ranges, perPlant),
      0,
    );
    em += plantSum * utilization;
  }

  if (weaponAllocated > 0 && weaponRatio > 0) {
    const weaponSum = weaponEmSources.reduce(
      (sum, weapon) =>
        sum + weapon.emNominal * rangeModifier(weapon.ranges, weaponAllocated),
      0,
    );
    em += weaponSum * weaponRatio;
  }

  for (const component of components) {
    const active = perPort[component.portPath] ?? 0;
    if (active <= 0 || component.units <= 0) continue;
    em +=
      component.emNominal *
      rangeModifier(component.ranges, active) *
      (active / component.units);
  }

  return em;
}

// Pure core: build the family ports from a loadout, run erkul's allocation over
// the plants' segments, and expose the per-component columns and the weapon
// sustained-DPS ratios (current allocation + max-weapon).
export function simulateLoadoutPower(
  hardpoints: Hardpoint[] | undefined,
  weaponPoolSize: number | undefined,
  mode: FlightMode = "SCM",
  overrides?: PortOverrides,
  shieldMaxItemCount: number = DEFAULT_SHIELD_MAX_ITEM_COUNT,
): LoadoutSimResult {
  const acc = collectPorts(
    hardpoints,
    {
      plants: [],
      weaponUnits: 0,
      weaponEmSources: [],
      otherPorts: [],
      portLabels: {},
      shieldsSeen: 0,
      components: [],
    },
    shieldMaxItemCount,
  );
  const pool = weaponPoolSize ?? 0;
  const segments = totalSegments(acc.plants);
  const consumption = Math.ceil(acc.weaponUnits);

  const ports: PowerPort[] = [
    ...weaponPoolBlocks(WEAPON_POOL_PORT, acc.weaponUnits, pool),
    ...acc.otherPorts,
  ];

  const allocateOpts = {
    mode,
    weaponConsumption: consumption,
    weaponPoolSize: pool,
  };

  // The default distribution (no user input).
  const baseline = allocatePower(ports, segments, allocateOpts);

  // Once the user assigns pips, pin every untouched component to its baseline
  // and honor the overrides — so freed pips return to the pool rather than
  // being greedily re-grabbed by another primary family (e.g. shields).
  let state = baseline;
  if (overrides && Object.keys(overrides).length > 0) {
    const targets: PortOverrides = {};
    const seen = new Set<string>();
    for (const port of ports) {
      if (seen.has(port.portPath)) continue;
      seen.add(port.portPath);
      targets[port.portPath] =
        overrides[port.portPath] ?? baseline.perPort[port.portPath] ?? 0;
    }
    state = allocatePower(ports, segments, {
      ...allocateOpts,
      overrides: targets,
    });
  }

  const columns = buildColumns(ports, acc.portLabels, state);

  // Shield power ratio = allocated shield segments / total shield capacity
  // across every active generator (0 when shields are unpowered, 1 when there
  // are no shields). Drives shield HP/regen and scales with a disabled generator.
  const shieldColumns = columns.filter((column) => column.family === "shield");
  const shieldCapacity = shieldColumns.reduce((sum, c) => sum + c.capacity, 0);
  const shieldAllocated = shieldColumns.reduce(
    (sum, c) => sum + c.allocated,
    0,
  );
  const shieldPoolRatio =
    shieldCapacity > 0 ? Math.min(1, shieldAllocated / shieldCapacity) : 1;

  // Engine (thruster) power relative to the default distribution — scales the
  // flight stats. 1 at the default allocation (the ship's rated figures already
  // reflect it), lower as the user pulls engine pips, higher as they add them.
  // 1 when the ship has no engine power family (nothing to scale against).
  const hasEngine = columns.some((column) => column.family === "engine");
  const engineBaseline = baseline.perFamily.engine;
  const engineCurrent = state.perFamily.engine;
  const enginePowerRatio = !hasEngine
    ? 1
    : engineBaseline > 0
      ? engineCurrent / engineBaseline
      : engineCurrent > 0
        ? 1
        : 0;

  // Radar power ratio → effective aim-assist range (erkul's `or`): interpolated
  // between the radar's min and max by radar power, 0 when the radar is off.
  const radarColumn = columns.find((column) => column.family === "radar");
  const radarPoolRatio =
    radarColumn && radarColumn.capacity > 0
      ? Math.min(1, radarColumn.allocated / radarColumn.capacity)
      : 0;
  const aimAssistMax = acc.radarAim?.max ?? 0;
  const aimAssist =
    acc.radarAim && radarPoolRatio > 0
      ? Math.round(
          acc.radarAim.min +
            (acc.radarAim.max - acc.radarAim.min) * radarPoolRatio,
        )
      : 0;

  const usedSegments = segments - state.remaining;
  const heat = computeHeat(acc.components, usedSegments, state.perPort);
  const weaponRatioValue = pool <= 0 ? 1 : weaponPoolRatio(state, consumption);
  const emittedEm = computeEm(
    acc.plants,
    acc.weaponEmSources,
    acc.components,
    state.perPort,
    usedSegments,
    segments,
    state.perPort[WEAPON_POOL_PORT] ?? 0,
    weaponRatioValue,
  );

  return {
    totalSegments: segments,
    remaining: state.remaining,
    perFamily: state.perFamily,
    columns,
    // No fixed weapon pool → the ship's guns are power-unlimited (ratio 1).
    weaponPoolRatio: weaponRatioValue,
    weaponMaxRatio: computeWeaponMaxRatio(
      pool,
      consumption,
      segments,
      acc.otherPorts,
    ),
    shieldPoolRatio,
    enginePowerRatio,
    aimAssist,
    aimAssistMax,
    coolingPerSec: heat.coolingPerSec,
    coolingMaxPerSec: heat.coolingMaxPerSec,
    heatGeneration: heat.heatGeneration,
    coolingRatio: heat.coolingRatio,
    emittedIr: heat.emittedIr,
    emittedEm,
  };
}

// Reactive wrapper around simulateLoadoutPower for use in components.
export function useLoadoutSim(
  hardpoints: MaybeRefOrGetter<Hardpoint[] | undefined>,
  weaponPoolSize: MaybeRefOrGetter<number | undefined>,
  mode: MaybeRefOrGetter<FlightMode> = () => "SCM",
  overrides: MaybeRefOrGetter<PortOverrides | undefined> = () => undefined,
  shieldMaxItemCount: MaybeRefOrGetter<number | undefined> = () => undefined,
) {
  return computed<LoadoutSimResult>(() =>
    simulateLoadoutPower(
      toValue(hardpoints),
      toValue(weaponPoolSize),
      toValue(mode),
      toValue(overrides),
      toValue(shieldMaxItemCount) ?? DEFAULT_SHIELD_MAX_ITEM_COUNT,
    ),
  );
}
