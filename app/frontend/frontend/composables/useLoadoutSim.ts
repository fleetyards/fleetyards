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

// A single power column in the pip UI — one component, or the shared weapon
// pool. `label` is the component name (undefined for the weapon pool). `min` is
// the mandatory floor: the component is either off (0) or on at ≥ `min`
// segments (min === capacity for all-critical systems like the quantum drive).
export type PowerColumn = {
  portPath: string;
  family: PowerFamily;
  label?: string;
  allocated: number;
  capacity: number;
  min: number;
};

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
};

// Ships run only the first N shields at once (the vehicle's Dynamic Shield power
// pool `maxItemCount`); the rest are unpowered backups. 2 is the game default.
export const DEFAULT_SHIELD_MAX_ITEM_COUNT = 2;

// The active shields share a pool (like weapons), so they aggregate into one
// column / override key rather than one per generator.
export const SHIELD_POOL_PORT = "shieldPool";

type Collected = {
  plants: { units: number; size: number; poweredOn: boolean }[];
  weaponUnits: number;
  otherPorts: PowerPort[];
  portLabels: Record<string, string>;
  shieldsSeen: number;
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
        const family = POWER_FAMILY_BY_CATEGORY[category];
        const draw = numeric(typeData.powerConsumption);
        if (family === "weapon") {
          acc.weaponUnits += draw;
        } else if (family && draw > 0) {
          // Shields past the active cap are unpowered backups.
          const isBackupShield =
            family === "shield" && ++acc.shieldsSeen > shieldMaxItemCount;
          if (!isBackupShield) {
            // Shields share a pool → one aggregate column; every other family
            // is one column per component.
            const portPath =
              family === "shield" ? SHIELD_POOL_PORT : hardpoint.id;
            const minimumFraction =
              typeData.powerMinimumFraction == null
                ? undefined
                : numeric(typeData.powerMinimumFraction);
            acc.otherPorts.push(
              ...componentBlocks(portPath, family, {
                units: draw,
                minimumFraction,
              }),
            );
            if (family !== "shield" && hardpoint.component?.name) {
              acc.portLabels[hardpoint.id] = hardpoint.component.name;
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

// Group the allocation into display columns: one per component (+ the shared
// weapon pool), ordered by family, dropping ports with no capacity.
function buildColumns(
  ports: PowerPort[],
  portLabels: Record<string, string>,
  state: AllocationState,
): PowerColumn[] {
  const byPort = new Map<
    string,
    { family: PowerFamily; capacity: number; critical: number }
  >();
  const order: string[] = [];
  for (const port of ports) {
    let entry = byPort.get(port.portPath);
    if (!entry) {
      entry = { family: port.family, capacity: 0, critical: 0 };
      byPort.set(port.portPath, entry);
      order.push(port.portPath);
    }
    if (!port.disabled) {
      entry.capacity += port.size;
      if (port.critical) entry.critical += port.size;
    }
  }

  const columns = order
    .map((portPath) => {
      const entry = byPort.get(portPath) as {
        family: PowerFamily;
        capacity: number;
        critical: number;
      };
      return {
        portPath,
        family: entry.family,
        label: portPath === WEAPON_POOL_PORT ? undefined : portLabels[portPath],
        allocated: state.perPort[portPath] ?? 0,
        capacity: entry.capacity,
        // Mandatory floor: a component is either off or on at ≥ this many
        // segments (equals capacity for all-critical systems like the QD).
        min: entry.critical,
      };
    })
    .filter((column) => column.capacity > 0);

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

  // Shield power ratio = allocated shield segments / shield capacity (0 when
  // shields are unpowered, 1 when there are no shields). Drives shield HP/regen.
  const shieldColumn = columns.find((column) => column.family === "shield");
  const shieldPoolRatio =
    shieldColumn && shieldColumn.capacity > 0
      ? Math.min(1, shieldColumn.allocated / shieldColumn.capacity)
      : 1;

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
