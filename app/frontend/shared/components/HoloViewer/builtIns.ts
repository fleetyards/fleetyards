import {
  type Material,
  Mesh,
  MeshBasicMaterial,
  type Object3D,
  DoubleSide,
} from "three";

// An item the hull holo keeps, which no loadout changes: by its port, and the
// node the holo draws it as.
export type HoloBuiltIn = {
  id: string;
  node?: string | null;
};

export const BUILT_IN_COLOR = "#ffcf5c";

const OPACITY = 0.35;
const POINTED_OPACITY = 0.7;
const RENDER_ORDER = 8;

export const builtInsKey = (builtIns: HoloBuiltIn[] = []): string =>
  builtIns.map((builtIn) => `${builtIn.id}@${builtIn.node ?? ""}`).join(";");

// The holo marks each such node with its port in the extras; the loader makes a
// repeated node name unique, so the name alone finds only the first.
const nodesFor = (scene: Object3D, builtIns: HoloBuiltIn[]) => {
  const ids = new Map<string, string>();
  for (const builtIn of builtIns) {
    ids.set(builtIn.id, builtIn.id);
    if (builtIn.node) ids.set(builtIn.node, builtIn.id);
  }

  const found: [Object3D, string][] = [];
  scene.traverse((node) => {
    const port = node.userData.kind === "item" ? node.userData.port : undefined;
    const id = (port && ids.get(port)) ?? undefined;
    if (id) found.push([node, id]);
  });

  if (found.length) return found;

  return builtIns.flatMap((builtIn) => {
    const node = builtIn.node ? scene.getObjectByName(builtIn.node) : undefined;

    return node ? [[node, builtIn.id] as [Object3D, string]] : [];
  });
};

// A tinted copy laid over each mesh of a built-in item, drawn through the hull
// so the item shows wherever it sits. Returned so they can be faded and
// removed again.
export const markBuiltIns = (scene: Object3D, builtIns: HoloBuiltIn[]) => {
  const marks: Mesh<Mesh["geometry"], MeshBasicMaterial>[] = [];

  for (const [node, id] of nodesFor(scene, builtIns)) {
    const meshes: Mesh[] = [];
    node.traverse((child) => {
      const mesh = child as Mesh;
      if (
        mesh.isMesh &&
        !mesh.userData.overlay &&
        !mesh.userData.wire &&
        !mesh.userData.depth
      ) {
        meshes.push(mesh);
      }
    });

    for (const mesh of meshes) {
      const mark = new Mesh(
        mesh.geometry,
        new MeshBasicMaterial({
          color: BUILT_IN_COLOR,
          transparent: true,
          opacity: 0,
          depthTest: false,
          depthWrite: false,
          side: DoubleSide,
        }),
      );
      mark.userData.overlay = true;
      mark.userData.builtInId = id;
      mark.renderOrder = RENDER_ORDER;
      mark.visible = false;
      mesh.add(mark);
      marks.push(mark);
    }
  }

  return marks;
};

export const paintBuiltIns = (
  marks: Mesh<Mesh["geometry"], MeshBasicMaterial>[],
  amount: number,
  pointed?: string,
) => {
  for (const mark of marks) {
    const opacity =
      mark.userData.builtInId === pointed ? POINTED_OPACITY : OPACITY;
    mark.material.opacity = opacity * amount;
    mark.visible = amount > 0;
  }
};

export const unmarkBuiltIns = (marks: Mesh[]) => {
  for (const mark of marks) {
    mark.removeFromParent();
    (mark.material as Material).dispose();
  }
};
