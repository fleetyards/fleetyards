import type { CargoHold, MediaFile } from "@/services/fyApi";
import type { RouteLocationRaw } from "vue-router";
import {
  CONTAINER_COLORS,
  CONTAINER_DEFS,
  SCU_UNIT,
  placeInGrid,
} from "@/shared/utils/CargoContainers";

export { CONTAINER_COLORS, CONTAINER_DEFS, SCU_UNIT };

export type ContainerRequest = {
  size: number;
  quantity: number;
};

export type ShipEntry = {
  name: string;
  cargoHolds: CargoHold[];
  color: string;
  image?: MediaFile;
  route?: RouteLocationRaw;
};

export const SHIP_COLORS = ["#82dbc5", "#ff9e80", "#b39ddb", "#90caf9"];

// A hold is loaded in whole crates, so a measured volume becomes the fewest
// containers that carry it: the largest that fits, then the remainder. What is
// left under the smallest crate has nothing to travel in and is dropped.
export function containersForVolume(scu: number): Record<number, number> {
  const counts: Record<number, number> = {};
  let remaining = Math.floor(scu);

  for (const def of CONTAINER_DEFS) {
    if (remaining < def.size) continue;

    const quantity = Math.floor(remaining / def.size);
    counts[def.size] = quantity;
    remaining -= quantity * def.size;
  }

  return counts;
}

// Ordered by the crates rather than by the object's keys, which JavaScript
// hands back smallest first - the viewer reads the load largest first.
export const encodeContainerCounts = (counts: Record<number, number>): string =>
  CONTAINER_DEFS.filter((def) => Number(counts[def.size]) > 0)
    .map((def) => `${def.size}x${counts[def.size]}`)
    .join(",");

// Anything the URL carries that is not a container this viewer draws is
// dropped rather than trusted: the query is as editable as the page's inputs.
export const parseContainerCounts = (
  value: unknown,
): Record<number, number> => {
  const counts: Record<number, number> = {};

  if (typeof value !== "string") return counts;

  for (const pair of value.split(",")) {
    const [rawSize, rawQuantity] = pair.split("x");
    const size = Number(rawSize);
    const quantity = Math.floor(Number(rawQuantity));

    if (!CONTAINER_DEFS.some((def) => def.size === size)) continue;
    if (!Number.isFinite(quantity) || quantity <= 0) continue;

    counts[size] = quantity;
  }

  return counts;
};

export function computeGreedyFill(
  cargoHolds: CargoHold[],
): Record<number, number> {
  const counts: Record<number, number> = {};

  for (const hold of cargoHolds) {
    const gridX = Math.floor(hold.dimensions.x / SCU_UNIT);
    const gridY = Math.floor(hold.dimensions.y / SCU_UNIT);
    const gridZ = Math.floor(hold.dimensions.z / SCU_UNIT);
    const occupied = new Uint8Array(gridX * gridY * gridZ);
    const maxSize = hold.maxContainerSize?.size || 32;

    for (const def of CONTAINER_DEFS) {
      if (def.size > maxSize) continue;
      while (placeInGrid(def, gridX, gridY, gridZ, occupied)) {
        counts[def.size] = (counts[def.size] || 0) + 1;
      }
    }
  }

  return counts;
}
