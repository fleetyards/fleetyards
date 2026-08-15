import type { CargoHold } from "@/services/fyApi";
import { CONTAINER_DEFS, SCU_UNIT } from "./constants";

export interface ContainerCapacity {
  size: number;
  maxQuantity: number;
}

// How many containers of one size fit across every hold, taking the best of the
// two floor orientations per hold. Holds refuse containers larger than their
// declared maximum; an undeclared maximum means the hold takes anything.
export function containersOfSize(
  holds: CargoHold[],
  containerSize: number,
): number {
  const def = CONTAINER_DEFS.find((entry) => entry.size === containerSize);

  if (!def) {
    return 0;
  }

  let total = 0;

  for (const hold of holds) {
    const maxSize = hold.maxContainerSize?.size || 32;

    if (def.size > maxSize) {
      continue;
    }

    const gridX = hold.dimensions.x / SCU_UNIT;
    const gridY = hold.dimensions.y / SCU_UNIT;
    const gridZ = hold.dimensions.z / SCU_UNIT;

    const orientations = [
      { cx: def.x, cy: def.y, cz: def.z },
      { cx: def.y, cy: def.x, cz: def.z },
    ];

    let best = 0;

    for (const orientation of orientations) {
      if (
        orientation.cx > gridX ||
        orientation.cy > gridY ||
        orientation.cz > gridZ
      ) {
        continue;
      }

      const count =
        Math.floor(gridX / orientation.cx) *
        Math.floor(gridY / orientation.cy) *
        Math.floor(gridZ / orientation.cz);

      if (count > best) {
        best = count;
      }
    }

    total += best;
  }

  return total;
}

export function containerCapacities(holds: CargoHold[]): ContainerCapacity[] {
  return CONTAINER_DEFS.map((def) => ({
    size: def.size,
    maxQuantity: containersOfSize(holds, def.size),
  })).filter((entry) => entry.maxQuantity > 0);
}

export function maxContainerSize(holds: CargoHold[]): number | undefined {
  if (!holds.length) {
    return undefined;
  }

  const sizes = holds
    .map((hold) => hold.maxContainerSize?.size)
    .filter((size): size is number => !!size);

  return sizes.length ? Math.max(...sizes) : undefined;
}
