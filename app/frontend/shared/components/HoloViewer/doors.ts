import {
  BoxGeometry,
  Group,
  Matrix4,
  Mesh,
  MeshBasicMaterial,
  type Object3D,
  PropertyBinding,
  Quaternion,
  Vector3,
} from "three";

export type HoloDoorKeyframe = {
  t: number;
  translation: number[];
  rotation: number[];
};

// A door of the holo, drawn closed. Each keyframe moves a part rigidly in the
// holo's frame, applied over where the part sits closed.
type DoorBox = { center: number[]; axes: number[][]; halfSize: number[] };

export type HoloDoor = {
  id: string;
  durationS: number;
  // Around every moving part, hidden ones too.
  bounds?: DoorBox | null;
  // Around only what shows from outside, and the hull nodes that make that up:
  // what the pointer finds the door by and what lights up.
  outline?: DoorBox | null;
  outlineNodes?: string[];
  parts: { part: number; object: string; keyframes: HoloDoorKeyframe[] }[];
};

type BoundPart = {
  node: Object3D;
  closed: Matrix4;
  // The part's parent in the holo's frame, and back.
  parent: Matrix4;
  parentInverse: Matrix4;
  keyframes: HoloDoorKeyframe[];
};

export type BoundDoor = {
  door: HoloDoor;
  parts: BoundPart[];
};

export const DOOR_COLOR = "#9cf0b0";

// Where each part sits closed, as the holo was loaded: a part bound again
// after it moved still closes to the same place.
const closedPoses = new WeakMap<Object3D, Matrix4>();

const TARGET_OPACITY = 0.28;
const MARK_OPACITY = 0.45;
const RENDER_ORDER = 12;

export const doorsLayoutKey = (doors: HoloDoor[] = []): string =>
  doors
    .map(
      (door) =>
        `${door.id}:${door.parts.map((part) => `${part.part}/${part.object}/${part.keyframes.length}`).join(",")}:${(door.outlineNodes ?? []).join("+")}`,
    )
    .join(";");

// The holo names a door's parts `door_<id>_<part>` and says so in their
// extras; an older export may carry them under their game-file name instead.
export const bindDoors = (scene: Object3D, doors: HoloDoor[]): BoundDoor[] => {
  const byExtras = new Map<string, Object3D>();

  scene.traverse((node) => {
    const { kind, doorId, part } = node.userData;
    if (kind === "door" && doorId !== undefined && part !== undefined) {
      byExtras.set(`${doorId}#${part}`, node);
    }
  });

  scene.updateMatrixWorld(true);
  const sceneInverse = scene.matrixWorld.clone().invert();

  return doors
    .map((door) => ({
      door,
      parts: door.parts.flatMap((part) => {
        // The loader strips the characters a node name may not carry.
        const node =
          byExtras.get(`${door.id}#${part.part}`) ??
          scene.getObjectByName(PropertyBinding.sanitizeNodeName(part.object));

        if (!node?.parent || !part.keyframes.length) return [];

        let closed = closedPoses.get(node);
        if (!closed) {
          node.updateMatrix();
          closed = node.matrix.clone();
          closedPoses.set(node, closed);
        }
        const parent = sceneInverse.clone().multiply(node.parent.matrixWorld);

        return [
          {
            node,
            closed,
            parent,
            parentInverse: parent.clone().invert(),
            keyframes: [...part.keyframes].sort((a, b) => a.t - b.t),
          },
        ];
      }),
    }))
    .filter((bound) => bound.parts.length);
};

const translation = new Vector3();
const nextTranslation = new Vector3();
const rotation = new Quaternion();
const nextRotation = new Quaternion();
const unit = new Vector3(1, 1, 1);
const delta = new Matrix4();
const local = new Matrix4();

// The rigid move at `amount` of the way open, between the keyframes around it.
const sample = (keyframes: HoloDoorKeyframe[], amount: number) => {
  let index = keyframes.findIndex((keyframe) => keyframe.t >= amount);
  if (index === -1) index = keyframes.length - 1;

  const next = keyframes[index];
  const previous = keyframes[Math.max(0, index - 1)];
  const span = next.t - previous.t;
  const along = span > 0 ? (amount - previous.t) / span : 1;

  translation
    .fromArray(previous.translation)
    .lerp(nextTranslation.fromArray(next.translation), along);
  rotation
    .fromArray(previous.rotation)
    .slerp(nextRotation.fromArray(next.rotation), along);

  return delta.compose(translation, rotation, unit);
};

export const poseDoor = (bound: BoundDoor, amount: number) => {
  for (const part of bound.parts) {
    // Shut is where the holo has it, whatever the first keyframe says.
    if (amount <= 0) {
      part.closed.decompose(
        part.node.position,
        part.node.quaternion,
        part.node.scale,
      );
      continue;
    }

    local
      .copy(part.parentInverse)
      .multiply(sample(part.keyframes, amount))
      .multiply(part.parent)
      .multiply(part.closed);
    local.decompose(part.node.position, part.node.quaternion, part.node.scale);
  }
};

// Click targets around the closed doors, drawn only while pointed at: around
// what shows of a door where the export says, around all of it otherwise.
export const buildDoorTargets = (doors: HoloDoor[]) => {
  const root = new Group();

  for (const door of doors) {
    const box = door.outline ?? door.bounds;
    if (!box) continue;

    const { center, axes, halfSize } = box;
    const target = new Mesh(
      new BoxGeometry(halfSize[0] * 2, halfSize[1] * 2, halfSize[2] * 2),
      new MeshBasicMaterial({
        color: DOOR_COLOR,
        transparent: true,
        opacity: TARGET_OPACITY,
        depthTest: false,
        depthWrite: false,
        visible: false,
      }),
    );
    target.renderOrder = RENDER_ORDER;

    const basis = new Matrix4().makeBasis(
      new Vector3().fromArray(axes[0]),
      new Vector3().fromArray(axes[1]),
      new Vector3().fromArray(axes[2]),
    );
    target.quaternion.setFromRotationMatrix(basis);
    target.position.fromArray(center);
    target.userData.doorId = door.id;
    root.add(target);
  }

  return root;
};

// A tinted copy over each mesh of a door's visible nodes, moving with them.
export type DoorMarks = Map<
  string,
  Mesh<Mesh["geometry"], MeshBasicMaterial>[]
>;

export const markDoors = (scene: Object3D, doors: HoloDoor[]): DoorMarks => {
  const marks: DoorMarks = new Map();

  for (const door of doors) {
    const meshes: Mesh[] = [];

    for (const name of door.outlineNodes ?? []) {
      scene
        .getObjectByName(PropertyBinding.sanitizeNodeName(name))
        ?.traverse((child) => {
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
    }

    if (!meshes.length) continue;

    marks.set(
      door.id,
      meshes.map((mesh) => {
        const mark = new Mesh(
          mesh.geometry,
          new MeshBasicMaterial({
            color: DOOR_COLOR,
            transparent: true,
            opacity: MARK_OPACITY,
            depthTest: false,
            depthWrite: false,
          }),
        );
        mark.userData.overlay = true;
        mark.renderOrder = RENDER_ORDER;
        mark.visible = false;
        mesh.add(mark);

        return mark;
      }),
    );
  }

  return marks;
};

export const unmarkDoors = (marks: DoorMarks) => {
  marks.forEach((list) =>
    list.forEach((mark) => {
      mark.removeFromParent();
      mark.material.dispose();
    }),
  );
  marks.clear();
};

// The pointed door, or every door, lit up by its own meshes where they are
// known, by its box otherwise.
export const pointDoorTarget = (
  root: Object3D,
  id?: string,
  marks: DoorMarks = new Map(),
  all = false,
) => {
  for (const child of root.children) {
    const doorId = child.userData.doorId;
    ((child as Mesh).material as MeshBasicMaterial).visible =
      (all || doorId === id) && !marks.has(doorId);
  }

  marks.forEach((list, doorId) =>
    list.forEach((mark) => {
      mark.visible = all || doorId === id;
    }),
  );
};

export const disposeDoorTargets = (root: Object3D) => {
  root.traverse((node) => {
    const mesh = node as Mesh<BoxGeometry, MeshBasicMaterial>;
    if (!mesh.isMesh) return;

    mesh.geometry.dispose();
    mesh.material.dispose();
  });
};
