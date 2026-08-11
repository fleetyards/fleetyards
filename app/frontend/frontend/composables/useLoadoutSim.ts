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
  // Effective aim-assist range (m) at the current radar power, and the radar's
  // max (for the bar's full scale). 0 when there's no radar / it's unpowered.
  aimAssist: number;
  aimAssistMax: number;
};

// Ships run only the first N shields at once (the vehicle's Dynamic Shield power
// pool `maxItemCount`); the rest are unpowered backups. 2 is the game default.
export const DEFAULT_SHIELD_MAX_ITEM_COUNT = 2;

type Collected = {
  plants: { units: number; size: number; poweredOn: boolean }[];
  weaponUnits: number;
  otherPorts: PowerPort[];
  portLabels: Record<string, string>;
  shieldsSeen: number;
  radarAim?: { min: number; max: number };
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
      otherPorts: [],
      portLabels: {},
      shieldsSeen: 0,
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

  return {
    totalSegments: segments,
    remaining: state.remaining,
    perFamily: state.perFamily,
    columns,
    // No fixed weapon pool → the ship's guns are power-unlimited (ratio 1).
    weaponPoolRatio: pool <= 0 ? 1 : weaponPoolRatio(state, consumption),
    weaponMaxRatio: computeWeaponMaxRatio(
      pool,
      consumption,
      segments,
      acc.otherPorts,
    ),
    shieldPoolRatio,
    aimAssist,
    aimAssistMax,
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
