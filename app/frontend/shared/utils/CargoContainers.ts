export const SCU_UNIT = 1.25;

// Length, width and height in SCU cells, height last.
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

// A container's corner cell in the grid and its extent in cells.
export type ContainerPlacement = {
  size: number;
  x: number;
  y: number;
  z: number;
  cx: number;
  cy: number;
  cz: number;
};

// The first free spot for one container, lengthwise along the grid or across
// it, marked as taken in `occupied`.
export const placeInGrid = (
  def: (typeof CONTAINER_DEFS)[number],
  gridX: number,
  gridY: number,
  gridZ: number,
  occupied: Uint8Array,
): ContainerPlacement | undefined => {
  const idx = (x: number, y: number, z: number) =>
    x + y * gridX + z * gridX * gridY;

  const orientations = [
    { cx: def.x, cy: def.y, cz: def.z },
    { cx: def.y, cy: def.x, cz: def.z },
  ];

  for (const { cx, cy, cz } of orientations) {
    if (cx > gridX || cy > gridY || cz > gridZ) continue;

    for (let gz = 0; gz <= gridZ - cz; gz++) {
      for (let gy = 0; gy <= gridY - cy; gy++) {
        for (let gx = 0; gx <= gridX - cx; gx++) {
          let fits = true;
          for (let dz = 0; dz < cz && fits; dz++) {
            for (let dy = 0; dy < cy && fits; dy++) {
              for (let dx = 0; dx < cx && fits; dx++) {
                if (occupied[idx(gx + dx, gy + dy, gz + dz)]) fits = false;
              }
            }
          }
          if (!fits) continue;

          for (let dz = 0; dz < cz; dz++) {
            for (let dy = 0; dy < cy; dy++) {
              for (let dx = 0; dx < cx; dx++) {
                occupied[idx(gx + dx, gy + dy, gz + dz)] = 1;
              }
            }
          }

          return { size: def.size, x: gx, y: gy, z: gz, cx, cy, cz };
        }
      }
    }
  }

  return undefined;
};

// A grid of whole SCU cells filled largest containers first, as a hold is
// loaded for the most cargo in the fewest crates.
export const packGrid = (
  gridX: number,
  gridY: number,
  gridZ: number,
  maxSize = 32,
): ContainerPlacement[] => {
  const placements: ContainerPlacement[] = [];
  if (gridX <= 0 || gridY <= 0 || gridZ <= 0) return placements;

  const occupied = new Uint8Array(gridX * gridY * gridZ);

  for (const def of CONTAINER_DEFS) {
    if (def.size > maxSize) continue;

    let placement = placeInGrid(def, gridX, gridY, gridZ, occupied);
    while (placement) {
      placements.push(placement);
      placement = placeInGrid(def, gridX, gridY, gridZ, occupied);
    }
  }

  return placements;
};
