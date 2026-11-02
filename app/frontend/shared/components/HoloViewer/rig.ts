import {
  type AnimationClip,
  type Bone,
  type Object3D,
  Skeleton,
  type SkinnedMesh,
} from "three";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { prepareGltfLoader } from "./gltfLoader";

// A worn piece skinned to the body's skeleton: its own copy of the bones it
// uses, named as the body's are, in the same bind pose.
export type RigPiece = {
  path: string;
  size?: number;
};

export type HoloRig = {
  pieces: RigPiece[];
  // The clips that pose the body and every piece by bone name.
  animations?: string;
  clip?: string;
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
  rig ? rig.pieces.map((piece) => piece.path).join(";") : "";

export const rigSize = (rig?: HoloRig) =>
  rig?.pieces.reduce((sum, piece) => sum + (piece.size ?? 0), 0) ?? 0;
