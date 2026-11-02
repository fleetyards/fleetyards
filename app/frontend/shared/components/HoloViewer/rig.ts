import {
  type AnimationClip,
  type Bone,
  type Object3D,
  Skeleton,
  type SkinnedMesh,
} from "three";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { clone as cloneSkinned } from "three/examples/jsm/utils/SkeletonUtils.js";
import { prepareGltfLoader } from "./gltfLoader";

// A worn piece skinned to the body's skeleton: its own copy of the bones it
// uses, named as the body's are, in the same bind pose.
export type RigPiece = {
  path: string;
  size?: number;
};

// A rigid item pinned to one of the figure's bones -- a weapon in a holster or
// a hand, a backpack on its mount -- drawn from its ordinary holo.
export type RigAttachment = {
  path: string;
  bone: string;
  size?: number;
  // Painted: drawn with its own materials, not the holo's.
  textured?: boolean;
  // Loaded in place of a painted holo that does not load, and drawn plain.
  fallbackPath?: string;
  // The point on the item that meets the bone, in its holo's frame: where a
  // rifle hooks onto a back mount. Without one the holo's origin does.
  helper?: {
    position: number[];
    rotation: number[];
  };
};

// The body's parts a worn piece covers: a bare foot would otherwise show
// through a thin boot.
export type BodyRegion = "head" | "torso" | "arms" | "legs";

export type HoloRig = {
  pieces: RigPiece[];
  // Under a worn undersuit: not drawn at all.
  hide?: BodyRegion[];
  // Under armour alone: drawn as a dark undersuit, which is what shows
  // through an opening in the armour in the game.
  cover?: BodyRegion[];
  attachments?: RigAttachment[];
  // The clips that pose the body and every piece by bone name.
  animations?: string;
  clip?: string;
  // A plinth under the figure's feet.
  pedestal?: boolean;
};

const clips = new Map<string, Promise<AnimationClip[]>>();

export const loadClips = (path: string) => {
  let loaded = clips.get(path);

  if (!loaded) {
    loaded = prepareGltfLoader(new GLTFLoader())
      .loadAsync(path)
      .then((gltf) => gltf.animations);
    loaded.catch(() => clips.delete(path));
    clips.set(path, loaded);
  }

  return loaded;
};

// A piece's own copy to bind and graft. A plain clone keeps its skinned meshes
// pointing at the cached piece's bones, and grafting those would take them out
// of the cache's tree for good. Geometry and materials stay shared with the
// cache, which frees them.
export const cloneRigPiece = (scene: Object3D) => {
  const copy = cloneSkinned(scene);

  copy.traverse((node) => {
    node.userData.shared = true;
  });

  return copy;
};

export const bonesByName = (root: Object3D) => {
  const bones = new Map<string, Bone>();

  root.traverse((node) => {
    if ((node as Bone).isBone) bones.set(node.name, node as Bone);
  });

  return bones;
};

// The piece's skinned meshes, bound to the body's bones in place of the
// piece's own copies, so one pose moves the whole figure. A piece carries
// helper bones of its own -- a magazine pouch's, a helmet light's -- which are
// grafted onto the body under the bone they hang from and handed back, so the
// caller can take them off again. A mesh naming a bone that hangs from
// nothing the body has is left out rather than drawn frozen in its bind pose.
// The bones it grafts join `bones`, so a later piece hangs from them too: a
// backpack from the core's own backpack bone.
export const bindToBones = (piece: Object3D, bones: Map<string, Bone>) => {
  const grafted: Bone[] = [];
  const meshes: SkinnedMesh[] = [];

  piece.traverse((node) => {
    if ((node as SkinnedMesh).isSkinnedMesh) meshes.push(node as SkinnedMesh);
  });

  const resolve = (bone: Bone): Bone | undefined => {
    const known = bones.get(bone.name);
    // A helper another piece grafted is shared only where it hangs from the
    // same bone -- the core's backpack bone, for the backpack. A namesake
    // somewhere else is this piece's own.
    const elsewhere =
      known?.userData.grafted && known.parent?.name !== bone.parent?.name;
    if (known && !elsewhere) return known;

    const parent = bone.parent as Bone | null;
    const anchor = parent?.isBone ? resolve(parent) : undefined;
    if (!anchor) return undefined;

    // Its subtree comes along; each of its bones is found under it from now on.
    anchor.add(bone);
    grafted.push(bone);
    bone.traverse((node) => {
      node.userData.grafted = true;
      if ((node as Bone).isBone && !bones.has(node.name)) {
        bones.set(node.name, node as Bone);
      }
    });

    return bone;
  };

  const bound = meshes.filter((mesh) => {
    const mapped = mesh.skeleton.bones.map(resolve);

    if (mapped.some((bone) => !bone)) {
      console.warn(
        "A rigged part names bones the body does not have",
        mesh.name,
      );
      return false;
    }

    mesh.bind(
      new Skeleton(mapped as Bone[], mesh.skeleton.boneInverses),
      mesh.bindMatrix,
    );
    // Posed away from the bind pose, the stored bounds no longer hold.
    mesh.frustumCulled = false;

    return true;
  });

  return { meshes: bound, grafted };
};

// Which region a part of the body is, from where it sits in the body's own
// bind pose: below the hips a leg, out past the shoulders an arm, and the
// trunk otherwise; the head comes as meshes of its own. Measured against the
// body's height, so it holds for any body the export adds.
export const bodyRegion = (mesh: SkinnedMesh, height: number): BodyRegion => {
  if (/head|eyes|teeth/i.test(mesh.name)) return "head";

  const position = mesh.geometry.getAttribute("position");
  const index = mesh.geometry.getIndex();
  const count = index ? index.count : position.count;
  const step = Math.max(1, Math.floor(count / 600));

  let x = 0;
  let up = 0;
  let samples = 0;
  for (let corner = 0; corner < count; corner += step) {
    const vertex = index ? index.getX(corner) : corner;
    x += Math.abs(position.getX(vertex));
    up += position.getZ(vertex);
    samples += 1;
  }

  if (!samples) return "torso";
  if (up / samples < height * 0.64) return "legs";
  if (x / samples > height * 0.13) return "arms";

  return "torso";
};

export const rigLayoutKey = (rig?: HoloRig) =>
  rig
    ? [
        ...rig.pieces.map((piece) => piece.path),
        // Everything that changes how a part is drawn: a helper that arrives
        // later moves it, a painted holo that failed swaps it.
        ...(rig.attachments ?? []).map((attachment) =>
          JSON.stringify([
            attachment.path,
            attachment.bone,
            attachment.textured,
            attachment.fallbackPath,
            attachment.helper,
          ]),
        ),
      ].join(";")
    : "";

export const rigTextured = (rig?: HoloRig) =>
  !!rig?.attachments?.some((attachment) => attachment.textured);

export const rigSize = (rig?: HoloRig) =>
  [...(rig?.pieces ?? []), ...(rig?.attachments ?? [])].reduce(
    (sum, part) => sum + (part.size ?? 0),
    0,
  );
