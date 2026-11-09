import {
  type AnimationClip,
  type Bone,
  Color,
  Group,
  LinearSRGBColorSpace,
  PointLight,
  SpotLight,
  Vector3,
  type Object3D,
  Skeleton,
  type SkinnedMesh,
} from "three";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { clone as cloneSkinned } from "three/examples/jsm/utils/SkeletonUtils.js";
import type { CharacterRig } from "./character/types";
import { extrasLoadingManager, prepareGltfLoader } from "./gltfLoader";

// A worn piece skinned to the body's skeleton: its own copy of the bones it
// uses, named as the body's are, in the same bind pose.
export type RigPiece = {
  path: string;
  size?: number;
  // Painted: drawn with its own materials, not the holo's.
  textured?: boolean;
  // The plain rig, loaded in place of a painted one that does not load. The
  // piece is still known by its path, so a mount hung from it stays put.
  fallbackPath?: string;
  // Hung from the mount an earlier piece brought rather than its own copy of
  // it: a backpack from the core it is worn on.
  hangs?: boolean;
  // The piece whose mount it must hang from: left off when that piece's rig
  // does not carry it, rather than hung from a namesake underneath.
  from?: string;
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
  // The rig piece whose own copy of the bone it hangs from. Left off the
  // figure when that piece's rig does not carry it, rather than hung from a
  // namesake underneath: an undersuit's holster sits inside the leg armour.
  from?: string;
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

// A light of the game's own rig for the figure, from its feet in glTF axes.
export type RigLight = {
  type: string;
  position: number[];
  direction?: number[];
  color: number[];
  intensity: number;
  range?: number;
  decay?: number;
  angle?: number;
  penumbra?: number;
};

export type HoloRig = {
  pieces: RigPiece[];
  lights?: RigLight[];
  // Under a worn undersuit, or a helmet that hides the head: not drawn.
  hide?: BodyRegion[];
  attachments?: RigAttachment[];
  // The clips that pose the body and every piece by bone name.
  animations?: string;
  clip?: string;
  // A plinth under the figure's feet.
  pedestal?: boolean;
  // The user's own character: its face on the body's head, with its hair,
  // brows, beard and piercings.
  character?: CharacterRig;
  // Under a helmet that leaves the head on show: the neck drawn as the
  // undersuit's collar.
  collar?: boolean;
};

const clips = new Map<string, Promise<AnimationClip[]>>();

export const loadClips = (path: string) => {
  let loaded = clips.get(path);

  if (!loaded) {
    loaded = prepareGltfLoader(new GLTFLoader(extrasLoadingManager))
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

// Helper bones a hanging piece takes from the pieces before it.
const SHARED_HELPERS = new Set(["backpack_attach_1_override"]);

// The piece's skinned meshes, bound to the body's bones in place of the
// piece's own copies, so one pose moves the whole figure. A piece carries
// helper bones of its own -- a magazine pouch's, a helmet light's -- which are
// grafted onto the body under the bone they hang from and handed back, so the
// caller can take them off again. A mesh naming a bone that hangs from
// nothing the body has is left out rather than drawn frozen in its bind pose.
// The bones it grafts join `bones`, so a later piece hangs from them too: a
// backpack from the core's own backpack bone. Every other piece brings its own
// copy: an undersuit's backpack bone sits inside the core worn over it.
export const bindToBones = (
  piece: Object3D,
  bones: Map<string, Bone>,
  {
    hangs = false,
    from,
    source,
  }: { hangs?: boolean; from?: string; source?: string } = {},
) => {
  const grafted: Bone[] = [];
  const meshes: SkinnedMesh[] = [];
  // What each graft replaced in `bones`, so a mesh left out takes its grafts
  // back rather than leaving mounts of a piece that is not drawn.
  const replaced: [string, Bone | undefined][] = [];

  piece.traverse((node) => {
    if ((node as SkinnedMesh).isSkinnedMesh) meshes.push(node as SkinnedMesh);
  });

  // Marks this piece's own grafts, so a bone it already grafted is found
  // again rather than grafted twice.
  const token = Symbol(piece.name);

  const resolve = (bone: Bone): Bone | undefined => {
    const known = bones.get(bone.name);

    if (known) {
      // The body's own skeleton, or a bone this piece grafted already.
      if (!known.userData.grafted || known.userData.graftedBy === token) {
        return known;
      }

      // A bone another piece brought: its own, unless it hangs from it.
      if (
        hangs &&
        SHARED_HELPERS.has(bone.name) &&
        known.parent?.name === bone.parent?.name
      ) {
        return !from || known.userData.source === from ? known : undefined;
      }
    } else if (hangs && from && SHARED_HELPERS.has(bone.name)) {
      return undefined;
    }

    const parent = bone.parent as Bone | null;
    const anchor = parent?.isBone ? resolve(parent) : undefined;
    if (!anchor) return undefined;

    // Its subtree comes along. Each bone is found under its name from now on,
    // over a namesake an earlier piece grafted: an outer layer's holster, not
    // the undersuit's beneath it, is where a weapon goes.
    anchor.add(bone);
    grafted.push(bone);
    bone.traverse((node) => {
      node.userData.grafted = true;
      node.userData.graftedBy = token;
      node.userData.source = source;
      if ((node as Bone).isBone) {
        replaced.push([node.name, bones.get(node.name)]);
        bones.set(node.name, node as Bone);
      }
    });

    return bone;
  };

  const bound = meshes.filter((mesh) => {
    const graftedBefore = grafted.length;
    const replacedBefore = replaced.length;
    const mapped = mesh.skeleton.bones.map(resolve);

    if (mapped.some((bone) => !bone)) {
      console.warn(
        "A rigged part names bones the body does not have",
        mesh.name,
      );
      grafted.splice(graftedBefore).forEach((bone) => bone.removeFromParent());
      replaced
        .splice(replacedBefore)
        .reverse()
        .forEach(([name, previous]) => {
          if (previous) bones.set(name, previous);
          else bones.delete(name);
        });
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
        ...rig.pieces.map((piece) =>
          [
            piece.path,
            piece.hangs ? "hangs" : "",
            piece.from ?? "",
            piece.textured ? "textured" : "",
            piece.fallbackPath ?? "",
          ].join("|"),
        ),
        // Everything that changes how a part is drawn: a helper that arrives
        // later moves it, a painted holo that failed swaps it.
        ...(rig.attachments ?? []).map((attachment) =>
          JSON.stringify([
            attachment.path,
            attachment.bone,
            attachment.textured,
            attachment.fallbackPath,
            attachment.helper,
            attachment.from,
          ]),
        ),
        rig.character ? `character:${rig.character.key}` : "",
        rig.collar ? "collar" : "",
      ].join(";")
    : "";

export const rigTextured = (rig?: HoloRig) =>
  !!rig?.pieces.some((piece) => piece.textured) ||
  !!rig?.attachments?.some((attachment) => attachment.textured);

export const rigSize = (rig?: HoloRig) =>
  [...(rig?.pieces ?? []), ...(rig?.attachments ?? [])].reduce(
    (sum, part) => sum + (part.size ?? 0),
    0,
  );

// The rig's lights as three.js lights under one group, each spot aimed down its
// direction. The group goes into the figure's frame, so the lights turn and
// centre with it.
export const buildRigLights = (lights: RigLight[]) => {
  const group = new Group();

  lights.forEach((light) => {
    const color = new Color().setRGB(
      light.color[0],
      light.color[1],
      light.color[2],
      LinearSRGBColorSpace,
    );
    const position = new Vector3().fromArray(light.position);

    if (light.type === "spot" && light.direction) {
      const spot = new SpotLight(
        color,
        light.intensity,
        light.range ?? 0,
        light.angle ?? Math.PI / 6,
        light.penumbra ?? 0.2,
        light.decay ?? 2,
      );
      spot.position.copy(position);
      spot.target.position.copy(
        position.clone().add(new Vector3().fromArray(light.direction)),
      );
      group.add(spot, spot.target);
    } else {
      const point = new PointLight(
        color,
        light.intensity,
        light.range ?? 0,
        light.decay ?? 2,
      );
      point.position.copy(position);
      group.add(point);
    }
  });

  return group;
};

export const rigLightsKey = (rig?: HoloRig) =>
  JSON.stringify(rig?.lights ?? []);
