import {
  BoxGeometry,
  EdgesGeometry,
  Group,
  LineBasicMaterial,
  LineSegments,
  Mesh,
  MeshBasicMaterial,
  type Material,
  type Object3D,
} from "three";
import {
  CONTAINER_COLORS,
  packGrid,
  SCU_UNIT,
} from "@/shared/utils/CargoContainers";

// A cargo grid in the holo's frame.
export type HoloCargoGrid = {
  id: string;
  position: number[];
  rotation: number[];
  // Along the grid's own x, up and depth axes.
  size: number[];
};

export const CARGO_GRID_COLOR = "#7fd8ff";

const GRID_EDGE_OPACITY = 0.55;
const POINTED_EDGE_OPACITY = 1;
const CONTAINER_FILL_OPACITY = 0.32;
const CONTAINER_EDGE_OPACITY = 0.85;
// Room between neighbouring containers, so each one reads on its own.
const CONTAINER_GAP = 0.06;
// Grown from this share of their size as they fade in.
const REVEAL_FROM = 0.7;

// Drawn through the hull like the boxes, the grids inside the ship.
const RENDER_ORDER = 9;

// A float measured off the export is a hair under a whole cell at times.
const cells = (metres: number) => Math.floor(metres / SCU_UNIT + 1e-3);

export const cargoLayoutKey = (grids: HoloCargoGrid[] = []): string =>
  grids
    .map(
      (grid) =>
        `${grid.id}@${grid.position.join(",")}/${grid.rotation.join(",")}/${grid.size.join(",")}`,
    )
    .join(";");

const seeThrough = (color: string, opacity: number) => ({
  color,
  transparent: true,
  opacity,
  depthTest: false,
  depthWrite: false,
});

const keepOpacity = (material: Material) => {
  material.userData.opacity = material.opacity;

  return material;
};

export const buildCargo = (grids: HoloCargoGrid[]) => {
  const root = new Group();
  const geometries = new Map<string, BoxGeometry>();

  const boxOf = (x: number, y: number, z: number) => {
    const key = `${x}/${y}/${z}`;
    let geometry = geometries.get(key);
    if (!geometry) {
      geometry = new BoxGeometry(x, y, z);
      geometries.set(key, geometry);
    }

    return geometry;
  };

  for (const grid of grids) {
    const [width, height, depth] = grid.size;
    const group = new Group();
    group.position.fromArray(grid.position);
    group.quaternion.fromArray(grid.rotation);
    group.userData.cargoGridId = grid.id;

    const outline = new LineSegments(
      new EdgesGeometry(boxOf(width, height, depth)),
      keepOpacity(
        new LineBasicMaterial(seeThrough(CARGO_GRID_COLOR, GRID_EDGE_OPACITY)),
      ),
    );
    outline.renderOrder = RENDER_ORDER;
    outline.userData.outline = true;
    group.add(outline);

    // What the pointer finds the grid by: the whole volume, empty cells too.
    const pick = new Mesh(
      boxOf(width, height, depth),
      new MeshBasicMaterial({ visible: false }),
    );
    pick.userData.cargoGridId = grid.id;
    group.add(pick);

    // Packed lengthwise along x, across along depth, stacked up.
    const placements = packGrid(cells(width), cells(depth), cells(height));

    for (const placement of placements) {
      const color = CONTAINER_COLORS[placement.size];
      const geometry = boxOf(
        placement.cx * SCU_UNIT - CONTAINER_GAP,
        placement.cz * SCU_UNIT - CONTAINER_GAP,
        placement.cy * SCU_UNIT - CONTAINER_GAP,
      );

      const container = new Mesh(
        geometry,
        keepOpacity(
          new MeshBasicMaterial(seeThrough(color, CONTAINER_FILL_OPACITY)),
        ),
      );
      container.renderOrder = RENDER_ORDER;
      container.position.set(
        -width / 2 + (placement.x + placement.cx / 2) * SCU_UNIT,
        -height / 2 + (placement.z + placement.cz / 2) * SCU_UNIT,
        -depth / 2 + (placement.y + placement.cy / 2) * SCU_UNIT,
      );
      container.userData.containerSize = placement.size;

      const edges = new LineSegments(
        new EdgesGeometry(geometry),
        keepOpacity(
          new LineBasicMaterial(seeThrough(color, CONTAINER_EDGE_OPACITY)),
        ),
      );
      edges.renderOrder = RENDER_ORDER + 1;
      container.add(edges);
      group.add(container);
    }

    root.add(group);
  }

  root.userData.geometries = [...geometries.values()];

  return root;
};

// Faded and grown in from each grid's centre, the containers settling in as
// they come.
export const revealCargo = (root: Object3D, amount: number) => {
  root.visible = amount > 0;
  root.userData.reveal = amount;

  for (const group of root.children) {
    group.scale.setScalar(REVEAL_FROM + (1 - REVEAL_FROM) * amount);
    const pointed = group.userData.cargoGridId === root.userData.pointed;

    group.traverse((node) => {
      const material = (node as Mesh).material as Material | undefined;
      if (!material) return;

      const base =
        node.userData.outline && pointed
          ? POINTED_EDGE_OPACITY
          : (material.userData.opacity ?? 1);
      material.opacity = base * amount;
    });
  }
};

// The grid under the pointer, its outline drawn bright.
export const pointCargo = (root: Object3D, id?: string) => {
  root.userData.pointed = id;
  revealCargo(root, (root.userData.reveal as number | undefined) ?? 1);
};

// The pick boxes, for the pointer to be cast against.
export const cargoTargets = (root: Object3D) =>
  root.children.flatMap((group) =>
    group.children.filter((child) => child.userData.cargoGridId),
  );

export const disposeCargo = (root: Object3D) => {
  root.traverse((node) => {
    const mesh = node as Mesh;
    if (!mesh.material) return;

    (mesh.material as Material).dispose();
    if (mesh instanceof LineSegments) mesh.geometry.dispose();
  });

  (root.userData.geometries as BoxGeometry[] | undefined)?.forEach((geometry) =>
    geometry.dispose(),
  );
};
