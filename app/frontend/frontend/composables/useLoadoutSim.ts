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
  weaponPoolRatio: number;
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
          acc.otherPorts.push(
            ...componentBlocks(hardpoint.id, family, { units: draw }),
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

// The default power auto-distribution for a loadout: build the family ports from
// the installed components, run erkul's allocation over the plants' segments,
// and expose the per-family segments + the weapon sustained-DPS `poolRatio`.
// This is the read-only default; the pip UI will later override the targets.
export function useLoadoutSim(
  hardpoints: MaybeRefOrGetter<Hardpoint[] | undefined>,
  weaponPoolSize: MaybeRefOrGetter<number | undefined>,
  mode: MaybeRefOrGetter<FlightMode> = () => "SCM",
) {
  return computed<LoadoutSimResult>(() => {
    const acc = collectPorts(toValue(hardpoints), {
      plants: [],
      weaponUnits: 0,
      otherPorts: [],
    });
    const pool = toValue(weaponPoolSize) ?? 0;
    const segments = totalSegments(acc.plants);
    const consumption = Math.ceil(acc.weaponUnits);

    const ports: PowerPort[] = [
      ...weaponPoolBlocks("weaponPool", acc.weaponUnits, pool),
      ...acc.otherPorts,
    ];

    const state = allocatePower(ports, segments, {
      mode: toValue(mode),
      weaponConsumption: consumption,
      weaponPoolSize: pool,
    });

    return {
      totalSegments: segments,
      remaining: state.remaining,
      perFamily: state.perFamily,
      // No fixed weapon pool → the ship's guns are power-unlimited (ratio 1).
      weaponPoolRatio: pool <= 0 ? 1 : weaponPoolRatio(state, consumption),
    };
  });
}
