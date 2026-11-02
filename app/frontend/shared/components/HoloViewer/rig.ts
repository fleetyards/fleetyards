import {
  type AnimationClip,
  type Bone,
  type Box3,
  CylinderGeometry,
  DoubleSide,
  Group,
  type Material,
  Mesh,
  MeshBasicMaterial,
  MeshStandardMaterial,
  type Object3D,
  RingGeometry,
  Skeleton,
  type SkinnedMesh,
  Vector3,
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
};

export type HoloRig = {
  pieces: RigPiece[];
  attachments?: RigAttachment[];
  // The clips that pose the body and every piece by bone name.
  animations?: string;
  clip?: string;
  // A plinth under the figure's feet.
  pedestal?: boolean;
};

const PEDESTAL_HEIGHT = 0.08;
const PEDESTAL_SEGMENTS = 96;

// A dark disc a little wider than the figure's stance, with a rim in the
// holo's colour, its top flush with the soles.
export const buildPedestal = (figure: Box3, rimColor: string) => {
  const size = figure.getSize(new Vector3());
  const center = figure.getCenter(new Vector3());
  const radius = (Math.max(size.x, size.z) / 2) * 1.4;

  const group = new Group();
  group.position.set(center.x, figure.min.y, center.z);

  const base = new Mesh(
    new CylinderGeometry(
      radius,
      radius * 1.06,
      PEDESTAL_HEIGHT,
      PEDESTAL_SEGMENTS,
    ),
    new MeshStandardMaterial({
      color: "#2b3036",
      metalness: 0.5,
      roughness: 0.55,
    }),
  );
  base.position.y = -PEDESTAL_HEIGHT / 2;

  const rim = new Mesh(
    new RingGeometry(radius * 0.94, radius, PEDESTAL_SEGMENTS),
    new MeshBasicMaterial({ color: rimColor, side: DoubleSide }),
  );
  rim.rotation.x = -Math.PI / 2;
  rim.position.y = 0.001;

  group.add(base, rim);
  group.userData.pedestal = true;

  return group;
};

export const disposePedestal = (pedestal: Object3D) => {
  pedestal.traverse((node) => {
    const mesh = node as Mesh;
    if (!mesh.isMesh) return;

    mesh.geometry.dispose();
    (mesh.material as Material).dispose();
  });
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
export const bindToBones = (piece: Object3D, bodyBones: Map<string, Bone>) => {
  const bones = new Map(bodyBones);
  const grafted: Bone[] = [];
  const meshes: SkinnedMesh[] = [];

  piece.traverse((node) => {
    if ((node as SkinnedMesh).isSkinnedMesh) meshes.push(node as SkinnedMesh);
  });

  const resolve = (bone: Bone): Bone | undefined => {
    const known = bones.get(bone.name);
    if (known) return known;

    const parent = bone.parent as Bone | null;
    const anchor = parent?.isBone ? resolve(parent) : undefined;
    if (!anchor) return undefined;

    // Its subtree comes along; each of its bones is found under it from now on.
    anchor.add(bone);
    grafted.push(bone);
    bone.traverse((node) => {
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

export const rigLayoutKey = (rig?: HoloRig) =>
  rig
    ? [
        ...rig.pieces.map((piece) => piece.path),
        ...(rig.attachments ?? []).map(
          (attachment) => `${attachment.path}@${attachment.bone}`,
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
