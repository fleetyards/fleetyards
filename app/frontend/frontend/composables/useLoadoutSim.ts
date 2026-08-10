import { computed, toValue, type MaybeRefOrGetter } from "vue";
import { HardpointCategoryEnum, type Hardpoint } from "@/services/fyApi";
import {
  allocatePower,
  componentBlocks,
  totalSegments,
  weaponPoolBlocks,
  weaponPoolRatio,
  type FlightMode,
  type PowerFamily,
  type PowerPort,
} from "./powerSim";

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
  // Weapon sustained-DPS ratio in the *default* SCM auto-distribution.
  weaponPoolRatio: number;
  // Weapon sustained-DPS ratio with weapons at maximum pips (other families
  // dropped to their mandatory minimums) — the max-power model sustained DPS
  // uses. Equals min(1, poolSize/consumption) unless the plant literally can't
  // deliver enough segments to fill the pool.
  weaponMaxRatio: number;
};

type Collected = {
  plants: { units: number; size: number; poweredOn: boolean }[];
  weaponUnits: number;
  otherPorts: PowerPort[];
};

function numeric(value: unknown): number {
  const n = Number(value);
  return Number.isFinite(n) ? n : 0;
}

// Walk the hardpoint tree, gathering the powered plants (segment sources), the
// summed weapon Power draw (the shared pool), and the per-component blocks for
// every other power-drawing family.
function collectPorts(
  hardpoints: Hardpoint[] | undefined,
  acc: Collected,
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
        }
      }
    }

    if (hardpoint.hardpoints?.length) {
      collectPorts(hardpoint.hardpoints, acc);
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

// Pure core: build the family ports from a loadout, run erkul's allocation over
// the plants' segments, and expose the per-family segments and the weapon
// sustained-DPS ratios (default SCM split + max-weapon).
export function simulateLoadoutPower(
  hardpoints: Hardpoint[] | undefined,
  weaponPoolSize: number | undefined,
  mode: FlightMode = "SCM",
): LoadoutSimResult {
  const acc = collectPorts(hardpoints, {
    plants: [],
    weaponUnits: 0,
    otherPorts: [],
  });
  const pool = weaponPoolSize ?? 0;
  const segments = totalSegments(acc.plants);
  const consumption = Math.ceil(acc.weaponUnits);

  const ports: PowerPort[] = [
    ...weaponPoolBlocks("weaponPool", acc.weaponUnits, pool),
    ...acc.otherPorts,
  ];

  const state = allocatePower(ports, segments, {
    mode,
    weaponConsumption: consumption,
    weaponPoolSize: pool,
  });

  return {
    totalSegments: segments,
    remaining: state.remaining,
    perFamily: state.perFamily,
    // No fixed weapon pool → the ship's guns are power-unlimited (ratio 1).
    weaponPoolRatio: pool <= 0 ? 1 : weaponPoolRatio(state, consumption),
    weaponMaxRatio: computeWeaponMaxRatio(
      pool,
      consumption,
      segments,
      acc.otherPorts,
    ),
  };
}

// Reactive wrapper around simulateLoadoutPower for use in components.
export function useLoadoutSim(
  hardpoints: MaybeRefOrGetter<Hardpoint[] | undefined>,
  weaponPoolSize: MaybeRefOrGetter<number | undefined>,
  mode: MaybeRefOrGetter<FlightMode> = () => "SCM",
) {
  return computed<LoadoutSimResult>(() =>
    simulateLoadoutPower(
      toValue(hardpoints),
      toValue(weaponPoolSize),
      toValue(mode),
    ),
  );
}
