import {
  BoxGeometry,
  EdgesGeometry,
  Group,
  LineBasicMaterial,
  LineSegments,
  Mesh,
  MeshBasicMaterial,
  type Object3D,
} from "three";

// A box drawn on the holo in its own frame: a place on the ship rather than a
// part, such as where it services the ships landed in it.
export type HoloBox = {
  id: string;
  position: [number, number, number];
  rotation: [number, number, number, number];
  // Along the box's own x, up and depth axes.
  size: [number, number, number];
  highlighted?: boolean;
};

// Apart from the hull's blue and the colours of the editor's tabs.
const COLOR = "#4fd1a5";

const FILL_OPACITY = 0.12;
const HIGHLIGHT_FILL_OPACITY = 0.3;
const EDGE_OPACITY = 0.6;
const HIGHLIGHT_EDGE_OPACITY = 1;

// Above every layer of the holo, and drawn through the hull: the areas sit
// inside the ship, where the hull's surface would hide them.
const RENDER_ORDER = 10;

export const boxesLayoutKey = (boxes: HoloBox[] = []): string =>
  boxes
    .map(
      (box) =>
        `${box.id}@${box.position.join(",")}/${box.rotation.join(",")}/${box.size.join(",")}`,
    )
    .join(";");

export const boxesHighlightKey = (boxes: HoloBox[] = []): string =>
  boxes.map((box) => (box.highlighted ? 1 : 0)).join("");

export const buildBoxes = (boxes: HoloBox[]) => {
  const root = new Group();

  for (const box of boxes) {
    const geometry = new BoxGeometry(...box.size);

    const fill = new Mesh(
      geometry,
      new MeshBasicMaterial({
        color: COLOR,
        transparent: true,
        depthTest: false,
        depthWrite: false,
      }),
    );
    fill.renderOrder = RENDER_ORDER;

    const edges = new LineSegments(
      new EdgesGeometry(geometry),
      new LineBasicMaterial({
        color: COLOR,
        transparent: true,
        depthTest: false,
        depthWrite: false,
      }),
    );
    edges.renderOrder = RENDER_ORDER + 1;

    fill.add(edges);
    fill.position.fromArray(box.position);
    fill.quaternion.fromArray(box.rotation);
    fill.userData.boxId = box.id;
    root.add(fill);
  }

  applyBoxHighlights(root, boxes);

  return root;
};

export const applyBoxHighlights = (root: Object3D, boxes: HoloBox[]) => {
  root.children.forEach((child, index) => {
    const highlighted = !!boxes[index]?.highlighted;
    const fill = child as Mesh<BoxGeometry, MeshBasicMaterial>;
    const edges = fill.children[0] as LineSegments<
      EdgesGeometry,
      LineBasicMaterial
    >;

    fill.material.opacity = highlighted ? HIGHLIGHT_FILL_OPACITY : FILL_OPACITY;
    edges.material.opacity = highlighted
      ? HIGHLIGHT_EDGE_OPACITY
      : EDGE_OPACITY;
  });
};

export const disposeBoxes = (root: Object3D) => {
  root.traverse((node) => {
    const mesh = node as Mesh;
    if (!mesh.geometry) return;

    mesh.geometry.dispose();
    (mesh.material as MeshBasicMaterial).dispose();
  });
};
