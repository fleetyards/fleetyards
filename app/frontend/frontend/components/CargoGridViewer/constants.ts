import type { CargoHold } from "@/services/fyApi";

export type ContainerRequest = {
  size: number;
  quantity: number;
};

export type ShipEntry = {
  name: string;
  cargoHolds: CargoHold[];
  color: string;
};

export const SHIP_COLORS = ["#82dbc5", "#ff9e80", "#b39ddb", "#90caf9"];

export const SCU_UNIT = 1.25;

export const CONTAINER_DEFS = [
  { size: 32, x: 8, y: 2, z: 2 },
  { size: 24, x: 6, y: 2, z: 2 },
  { size: 16, x: 4, y: 2, z: 2 },
  { size: 8, x: 2, y: 2, z: 2 },
  { size: 4, x: 2, y: 2, z: 1 },
  { size: 2, x: 2, y: 1, z: 1 },
  { size: 1, x: 1, y: 1, z: 1 },
];

export const CONTAINER_COLORS: Record<number, string> = {
  1: "#4fc3f7",
  2: "#81c784",
  4: "#fff176",
  8: "#ffb74d",
  16: "#ff8a65",
  24: "#ba68c8",
  32: "#e57373",
};

function tryPlaceInGrid(
  def: { x: number; y: number; z: number },
  gridX: number,
  gridY: number,
  gridZ: number,
  occupied: Uint8Array,
): boolean {
  const idx = (x: number, y: number, z: number) =>
    x + y * gridX + z * gridX * gridY;

  const orientations = [
    { cx: def.x, cy: def.y, cz: def.z },
    { cx: def.y, cy: def.x, cz: def.z },
  ];

  for (const orient of orientations) {
    if (orient.cx > gridX || orient.cy > gridY || orient.cz > gridZ) continue;

    for (let gz = 0; gz <= gridZ - orient.cz; gz++) {
      for (let gy = 0; gy <= gridY - orient.cy; gy++) {
        for (let gx = 0; gx <= gridX - orient.cx; gx++) {
          let fits = true;
          for (let dz = 0; dz < orient.cz && fits; dz++) {
            for (let dy = 0; dy < orient.cy && fits; dy++) {
              for (let dx = 0; dx < orient.cx && fits; dx++) {
                if (occupied[idx(gx + dx, gy + dy, gz + dz)]) fits = false;
              }
            }
          }
          if (!fits) continue;

          for (let dz = 0; dz < orient.cz; dz++) {
            for (let dy = 0; dy < orient.cy; dy++) {
              for (let dx = 0; dx < orient.cx; dx++) {
                occupied[idx(gx + dx, gy + dy, gz + dz)] = 1;
              }
            }
          }
          return true;
        }
      }
    }
  }
  return false;
}

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
      while (tryPlaceInGrid(def, gridX, gridY, gridZ, occupied)) {
        counts[def.size] = (counts[def.size] || 0) + 1;
      }
    }
  }

  return counts;
}
