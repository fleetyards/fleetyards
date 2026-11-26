import {
  type Bone,
  Box3,
  BufferAttribute,
  type BufferGeometry,
  CanvasTexture,
  Color,
  type Material,
  Matrix4,
  type Mesh,
  type MeshStandardMaterial,
  type Object3D,
  type SkinnedMesh,
  SRGBColorSpace,
  type Texture,
  Vector3,
} from "three";
import { loadHolo } from "../mounts";
import { cloneRigPiece } from "../rig";
import {
  blendFace,
  type BlendedFace,
  FACE_MESHES,
  FACE_PARTS,
  type FaceLibrary,
  type FaceMeshName,
  type FaceWeights,
  loadFaceLibrary,
} from "./faceLibrary";
import { floatArray } from "../dequantize";
import { bindToFace, faceOffsets, fitToFace } from "./headBinding";
import {
  bakeEyes,
  bakeHead,
  characterMaterial,
  loadTexture,
  ownedTextures,
} from "./materials";
import type { CharacterRig } from "./types";

// A file without a face block is drawn on the archetype head body.glb
// carries, library head 1.
const ARCHETYPE_WEIGHTS: FaceWeights = FACE_PARTS.map((part) => ({
  part,
  heads: [[1, 1]],
}));

export type LoadedCharacter = {
  key: string;
  // What it was built from: its skin, among the rest.
  rig: CharacterRig;
  // Painted: built with its materials, skin and eyes; clay otherwise.
  textured: boolean;
  library: FaceLibrary;
  face: BlendedFace;
  // How far each head point moved from protos.
  offsets: Float32Array;
  // Accessory meshes on the blended face, cloned for each binding to the
  // body's bones.
  accessories: Object3D[];
  // What it made and has to free: moved geometry, built materials.
  owned: { geometries: BufferGeometry[]; materials: Material[] };
  headMap?: Texture;
  headNormal?: Texture;
  headOrm?: Texture;
  eyeMap?: Texture;
};

const canvasTexture = (canvas: HTMLCanvasElement) => {
  const texture = new CanvasTexture(canvas);
  texture.flipY = false;
  texture.colorSpace = SRGBColorSpace;
  return texture;
};

const meshesOf = (root: Object3D) => {
  const meshes: Mesh[] = [];
  root.traverse((node) => {
    if ((node as Mesh).isMesh) meshes.push(node as Mesh);
  });
  return meshes;
};

// Scalp hair cards are not shadowed by the cards above them as they are in
// the game, and come out far too bright: their diffuse and ambient light is
// scaled down. Beards, brows and lashes stay as they are.
const SCALP_HAIR_OCCLUSION = 0.3;

const hairOcclusion = (port: string | undefined, mode: string) =>
  port === "hair_itemport" && mode === "hair_cards" ? SCALP_HAIR_OCCLUSION : 1;

const loadAccessory = async (
  rig: CharacterRig,
  mesh: CharacterRig["meshes"][number],
  offsets: Float32Array,
  textured: boolean,
  owned: LoadedCharacter["owned"],
) => {
  if (!mesh.url) return undefined;

  try {
    const scene = cloneRigPiece(await loadHolo(mesh.url));
    await Promise.all(
      meshesOf(scene).map(async (part) => {
        const index =
          (part.geometry.userData.submaterial as number | undefined) ?? 0;
        const entry = mesh.materials_by_submaterial.find(
          (candidate) => candidate.submaterial === index,
        );

        if (entry && !("material" in entry)) {
          part.removeFromParent();
          return;
        }

        const bound = bindToFace(part.geometry, offsets);
        if (bound !== part.geometry) owned.geometries.push(bound);
        part.geometry = bound;
        part.userData.textured = textured;
        if (textured && entry && "material" in entry) {
          part.material = await characterMaterial(
            entry.material.three,
            entry.material.variation,
            hairOcclusion(mesh.port, entry.material.mode),
          );
          owned.materials.push(part.material);
        }
      }),
    );
    scene.name = `character:${rig.key}:${mesh.url}`;
    return scene;
  } catch (error) {
    console.warn("A character accessory did not load", error);
    return undefined;
  }
};

export const loadCharacter = async (
  rig: CharacterRig,
  textured: boolean,
): Promise<LoadedCharacter> => {
  const library = await loadFaceLibrary(rig.library.id, rig.library.urls);
  const face = blendFace(library, rig.weights ?? ARCHETYPE_WEIGHTS);
  const offsets = faceOffsets(face.head, library.meshes.head.base);
  const head = rig.skin.head;
  const owned: LoadedCharacter["owned"] = { geometries: [], materials: [] };

  const [accessories, headMap, headNormal, headOrm, eyeMap] = await Promise.all(
    [
      rig.hideHead
        ? Promise.resolve([])
        : Promise.all(
            rig.meshes.map((mesh) =>
              loadAccessory(rig, mesh, offsets, textured, owned),
            ),
          ),
      textured && head.base
        ? bakeHead(head)
            .then(canvasTexture)
            .catch(() => undefined)
        : undefined,
      textured && head.normal
        ? loadTexture(head.normal).catch(() => undefined)
        : undefined,
      textured && head.orm
        ? loadTexture(head.orm).catch(() => undefined)
        : undefined,
      textured
        ? bakeEyes(rig.eyes)
            .then((canvas) => canvas && canvasTexture(canvas))
            .catch(() => undefined)
        : undefined,
    ],
  );

  return {
    key: rig.key,
    rig,
    textured,
    library,
    face,
    offsets,
    owned,
    accessories: accessories.filter((scene): scene is Object3D => !!scene),
    headMap,
    headNormal,
    headOrm,
    eyeMap,
  };
};

// The body's head, eyes and teeth, found by the mesh names the library
// gives, and only when their points line up with it.
const faceMeshes = (scene: Object3D, library: FaceLibrary) => {
  const found = new Map<FaceMeshName, Mesh>();
  scene.traverse((node) => {
    const mesh = node as Mesh;
    if (!mesh.isMesh) return;
    FACE_MESHES.forEach((name) => {
      const entry = library.meshes[name];
      if (mesh.name !== entry.gltfMeshName && !mesh.name.endsWith(`_${name}`))
        return;
      if (mesh.geometry.getAttribute("position")?.count !== entry.vertexCount)
        return;
      found.set(name, mesh);
    });
  });
  return found;
};

// The body's own material and geometry as the model brought them, found from
// whatever was made from them. The model is cached across viewers, so a change
// undone too late, or never, must not become what the next character is built
// on: a skin tinted twice goes dark. Kept out of userData, which three copies
// through JSON whenever it clones.
const derived = new WeakMap<object, object>();

const derive = <T extends object>(made: T, from: T) => {
  derived.set(made, derived.get(from) ?? from);
  return made;
};

const originalMaterial = (mesh: Mesh) =>
  (derived.get(mesh.material as Material) ??
    mesh.material) as MeshStandardMaterial;

const originalGeometry = (mesh: Mesh) =>
  (derived.get(mesh.geometry) ?? mesh.geometry) as BufferGeometry;

const withPositions = (
  geometry: BufferGeometry,
  positions: Float32Array,
  normals?: Float32Array,
) => {
  const copy = derive(geometry.clone(), geometry);
  copy.setAttribute("position", new BufferAttribute(positions, 3));
  if (normals) copy.setAttribute("normal", new BufferAttribute(normals, 3));
  copy.computeBoundingBox();
  copy.computeBoundingSphere();
  return copy;
};

// Reshapes the body's head, eyes and teeth, recolours the painted skin and
// eyes, and gives back how to undo all of it.
export const dressHead = (
  scene: Object3D,
  character: LoadedCharacter,
  textured: boolean,
) => {
  const undo: (() => void)[] = [];
  const meshes = faceMeshes(scene, character.library);

  meshes.forEach((mesh, name) => {
    const geometry = originalGeometry(mesh);
    mesh.geometry = withPositions(
      geometry,
      character.face[name],
      name === "head" ? character.face.headNormals : undefined,
    );
    undo.push(() => {
      mesh.geometry.dispose();
      mesh.geometry = geometry;
    });
  });

  if (textured) {
    const [r, g, b] = character.rig.skin.body_baseColorFactor;
    scene.traverse((node) => {
      const mesh = node as Mesh;
      if (!mesh.isMesh || [...meshes.values()].includes(mesh)) return;

      if (!(mesh.material as Material)?.userData?.skinTone) return;
      const bare = originalMaterial(mesh);

      const tinted = derive(bare.clone(), bare);
      tinted.color = new Color(bare.color).multiply(new Color(r, g, b));
      mesh.material = tinted;
      undo.push(() => {
        tinted.dispose();
        mesh.material = bare;
      });
    });

    const replace = (
      name: FaceMeshName,
      change: (material: MeshStandardMaterial) => void,
    ) => {
      const mesh = meshes.get(name);
      if (!mesh) return;
      const bare = originalMaterial(mesh);
      const changed = derive(bare.clone(), bare);
      change(changed);
      changed.needsUpdate = true;
      mesh.material = changed;
      undo.push(() => {
        changed.dispose();
        mesh.material = bare;
      });
    };

    if (character.headMap) {
      replace("head", (material) => {
        material.map = character.headMap ?? null;
        material.color = new Color(1, 1, 1);
        if (character.headNormal) material.normalMap = character.headNormal;
        if (character.headOrm) {
          material.roughnessMap = character.headOrm;
          material.metalnessMap = character.headOrm;
          material.aoMap = character.headOrm;
        }
      });
    }
    if (character.eyeMap) {
      replace("eyes", (material) => {
        material.map = character.eyeMap ?? null;
        material.color = new Color(1, 1, 1);
      });
    }
  }

  return () => undo.reverse().forEach((step) => step());
};

// How far up the head mesh the neck runs, from its lowest point: the face
// library's neck region tops out 6 cm up on both bodies, front and back.
const NECK_HEIGHT = 0.06;
// The highest a helmet's rim may sit over the neck's lowest point: the chin
// starts about 15 cm up. A helmet that reaches no lower in some direction is
// open there, and the face shows rather than the collar.
const RIM_CEILING = 0.15;
// How far the collar runs up inside the helmet, so no skin shows at its rim.
const RIM_OVERLAP = 0.01;
// The sectors around the neck the helmet's rim is measured in: a rim sits
// lower at the chin than at the nape.
const RIM_SECTORS = 32;
// Enough of a helmet's points to find its rim.
const RIM_SAMPLES = 20_000;
const COLLAR = new Color("#1d2126");

// As plain numbers: a cloned scene copies its nodes' userData through JSON.
type Rest = number[];

const restOf = (bone: Object3D): Rest => [
  ...bone.position.toArray(),
  ...bone.quaternion.toArray(),
  ...bone.scale.toArray(),
];

const setPose = (bone: Object3D, pose: Rest) => {
  bone.position.fromArray(pose, 0);
  bone.quaternion.fromArray(pose, 3);
  bone.scale.fromArray(pose, 7);
};

// Remembers each bone's pose as loaded, before any clip moves it, so the
// collar is measured the same way whatever the figure is doing.
export const keepRestPose = (root: Object3D) =>
  root.traverse((node) => {
    if ((node as Bone).isBone && !node.userData.rest) {
      node.userData.rest = restOf(node);
    }
  });

const atRestPose = <T>(root: Object3D, measure: () => T) => {
  const posed: [Object3D, Rest][] = [];
  root.traverse((node) => {
    const rest = node.userData.rest as Rest | undefined;
    if (!(node as Bone).isBone || !rest) return;
    posed.push([node, restOf(node)]);
    setPose(node, rest);
  });
  root.updateMatrixWorld(true);

  try {
    return measure();
  } finally {
    posed.forEach(([node, pose]) => setPose(node, pose));
    root.updateMatrixWorld(true);
  }
};

// Points of a mesh where it is drawn, in the frame of `frame`'s owner, every
// `stride`th. The stored points of a quantized skin mean nothing on their
// own: its inverse bind matrices carry the dequantization.
const drawnPoints = (
  mesh: Mesh,
  frame: Matrix4,
  each: (point: Vector3, index: number) => void,
  stride = 1,
) => {
  const position = mesh.geometry.getAttribute("position");
  const skinned = (mesh as SkinnedMesh).isSkinnedMesh
    ? (mesh as SkinnedMesh)
    : undefined;
  const toFrame = new Matrix4().multiplyMatrices(frame, mesh.matrixWorld);
  const point = new Vector3();
  for (let index = 0; index < position.count; index += stride) {
    point.fromBufferAttribute(position, index);
    skinned?.applyBoneTransform(index, point);
    each(point.applyMatrix4(toFrame), index);
  }
};

const sectorOf = (point: Vector3, axis: Vector3) => {
  const angle = Math.atan2(point.x - axis.x, point.z - axis.z) + Math.PI;
  return Math.min(
    RIM_SECTORS - 1,
    Math.floor((angle / (2 * Math.PI)) * RIM_SECTORS),
  );
};

const hangsFromHead = (bone: Object3D) => {
  for (let node: Object3D | null = bone; node; node = node.parent) {
    if (node.name.toLowerCase() === "head") return true;
  }
  return false;
};

// Which of a mesh's points move with the head. A helmet may bring a cape or
// cowl in the same mesh, which hangs from the spine far below the rim.
const movesWithHead = (mesh: Mesh) => {
  const { skinIndex, skinWeight } = mesh.geometry.attributes;
  if (!(mesh as SkinnedMesh).isSkinnedMesh || !skinIndex || !skinWeight) {
    return () => true;
  }

  const onHead = (mesh as SkinnedMesh).skeleton.bones.map(hangsFromHead);
  return (index: number) => {
    let weight = 0;
    for (let slot = 0; slot < skinIndex.itemSize; slot++) {
      if (onHead[skinIndex.getComponent(index, slot)]) {
        weight += skinWeight.getComponent(index, slot);
      }
    }
    return weight > 0.5;
  };
};

// The lowest point of the helmet's shell in each sector around the neck's
// axis.
const rimHeights = (rims: Mesh[], frame: Matrix4, axis: Vector3) => {
  const heights = new Array<number>(RIM_SECTORS).fill(Infinity);
  rims.forEach((mesh) => {
    const count = mesh.geometry.getAttribute("position")?.count ?? 0;
    const onShell = movesWithHead(mesh);
    drawnPoints(
      mesh,
      frame,
      (point, index) => {
        if (!onShell(index)) return;
        const sector = sectorOf(point, axis);
        heights[sector] = Math.min(heights[sector], point.y);
      },
      Math.max(1, Math.ceil(count / RIM_SAMPLES)),
    );
  });
  return heights;
};

// Under a helmet, the undersuit's collar: the head is drawn dark from the
// neck up to the helmet's rim, so no skin shows between the rim and the core,
// while the face above it stays as it is and shows through a visor or an open
// front. A helmet that hides the head draws all of it as the hood. `rims` are
// the helmet's meshes as drawn on the body; everything is measured in the
// rest pose, in the scene's own frame.
export const dressNeck = (scene: Object3D, hood = false, rims: Mesh[] = []) => {
  const names = hood ? /_(head|eyes|teeth)$/ : /_head$/;
  const meshes: Mesh[] = [];
  scene.traverse((node) => {
    const mesh = node as Mesh;
    if (mesh.isMesh && names.test(mesh.name)) meshes.push(mesh);
  });
  if (!meshes.length) return () => {};

  const depths = hood
    ? meshes.map((mesh) =>
        new Float32Array(mesh.geometry.getAttribute("position").count).fill(-1),
      )
    : atRestPose(scene, () => collarDepths(scene, meshes, rims));

  const undo = meshes.map((mesh, index) => {
    const geometry = mesh.geometry;
    const dressed = derive(geometry.clone(), geometry);
    dressed.setAttribute("collarDepth", new BufferAttribute(depths[index], 1));
    mesh.geometry = dressed;

    const current = mesh.material as MeshStandardMaterial;
    const collared = derive(current.clone(), current);
    collared.onBeforeCompile = (shader) => {
      shader.uniforms.collarColor = { value: COLLAR };
      shader.vertexShader = shader.vertexShader
        .replace(
          "#include <common>",
          "#include <common>\nattribute float collarDepth;\nvarying float vCollarDepth;",
        )
        .replace(
          "#include <begin_vertex>",
          "#include <begin_vertex>\nvCollarDepth = collarDepth;",
        );
      shader.fragmentShader = shader.fragmentShader
        .replace(
          "#include <common>",
          "#include <common>\nvarying float vCollarDepth;\nuniform vec3 collarColor;",
        )
        .replace(
          "#include <map_fragment>",
          "#include <map_fragment>\nif (vCollarDepth < 0.0) diffuseColor.rgb = collarColor;",
        );
    };
    collared.customProgramCacheKey = () => "character-collar";
    mesh.material = collared;

    return () => {
      collared.dispose();
      if (mesh.material === collared) mesh.material = current;
      dressed.dispose();
      if (mesh.geometry === dressed) mesh.geometry = geometry;
    };
  });

  return () => undo.forEach((step) => step());
};

// How far each head point sits above the collar's edge; below it is collar.
const collarDepths = (scene: Object3D, meshes: Mesh[], rims: Mesh[]) => {
  const frame = scene.matrixWorld.clone().invert();
  const drawn = meshes.map((mesh) => {
    const points: number[] = [];
    drawnPoints(mesh, frame, (point) => points.push(point.x, point.y, point.z));
    return points;
  });

  const bounds = new Box3();
  const point = new Vector3();
  drawn.forEach((points) => {
    for (let index = 0; index < points.length; index += 3) {
      bounds.expandByPoint(point.fromArray(points, index));
    }
  });
  const axis = bounds.getCenter(new Vector3());
  const neck = bounds.min.y + NECK_HEIGHT;
  const ceiling = bounds.min.y + RIM_CEILING;
  const heights = rimHeights(rims, frame, axis);
  const rim = heights.map((height, sector) => {
    // A lone high sector is a gap between the rim's points, not an opening.
    const beside = Math.max(
      heights[(sector + RIM_SECTORS - 1) % RIM_SECTORS],
      heights[(sector + 1) % RIM_SECTORS],
    );
    const edge = height <= ceiling ? height : beside;
    return edge <= ceiling ? edge + RIM_OVERLAP : -Infinity;
  });

  return drawn.map((points) => {
    const depth = new Float32Array(points.length / 3);
    for (let index = 0; index < depth.length; index++) {
      point.fromArray(points, index * 3);
      depth[index] = point.y - Math.max(neck, rim[sectorOf(point, axis)]);
    }
    return depth;
  });
};

// A hat, cap, bandana or mask worn as a rig piece, moved onto the blended
// face. Gives back the geometry it made, for the caller to free.
export const fitPieceToFace = (piece: Object3D, character: LoadedCharacter) =>
  meshesOf(piece).flatMap((mesh) => {
    const position = mesh.geometry.getAttribute("position");
    if (!position) return [];
    mesh.geometry = withPositions(
      mesh.geometry,
      fitToFace(
        floatArray(position),
        character.library.meshes.head.base,
        character.offsets,
      ),
    );
    return [mesh.geometry];
  });

export const disposeCharacter = (character: LoadedCharacter) => {
  character.headMap?.dispose();
  character.eyeMap?.dispose();
  character.owned.geometries.forEach((geometry) => geometry.dispose());
  character.owned.materials.forEach((material) => {
    ownedTextures.get(material)?.forEach((texture) => texture.dispose());
    material.dispose();
  });
};
