import {
  BufferAttribute,
  type BufferGeometry,
  CanvasTexture,
  Color,
  type Material,
  type Mesh,
  type MeshStandardMaterial,
  type Object3D,
  SRGBColorSpace,
  type Texture,
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
// the game, and come out about three times too bright under the studio's
// environment light: their diffuse and ambient light is scaled down. Beards,
// brows and lashes, and every layer without the studio, stay as they are.
const SCALP_HAIR_OCCLUSION = 0.3;

const hairOcclusion = (
  port: string | undefined,
  mode: string,
  studio: boolean,
) =>
  studio && port === "hair_itemport" && mode === "hair_cards"
    ? SCALP_HAIR_OCCLUSION
    : 1;

const loadAccessory = async (
  rig: CharacterRig,
  mesh: CharacterRig["meshes"][number],
  offsets: Float32Array,
  textured: boolean,
  owned: LoadedCharacter["owned"],
  studio: boolean,
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
            hairOcclusion(mesh.port, entry.material.mode, studio),
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
  studio = false,
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
              loadAccessory(rig, mesh, offsets, textured, owned, studio),
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
  rig: CharacterRig,
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
    const [r, g, b] = rig.skin.body_baseColorFactor;
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
const COLLAR = new Color("#1d2126");

// Under a helmet, the undersuit's collar: the gap between the helmet's rim and
// the core shows the neck, which is drawn dark, while the face stays as it is
// and shows through a visor.
export const dressNeck = (scene: Object3D, hood = false) => {
  const names = hood ? /_(head|eyes|teeth)$/ : /_head$/;
  const meshes: Mesh[] = [];
  scene.traverse((node) => {
    const mesh = node as Mesh;
    if (mesh.isMesh && names.test(mesh.name)) meshes.push(mesh);
  });

  const undo = meshes.map((mesh) => {
    const current = mesh.material as MeshStandardMaterial;
    mesh.geometry.computeBoundingBox();
    const cut = hood
      ? Number.POSITIVE_INFINITY
      : (mesh.geometry.boundingBox?.min.z ?? 0) + NECK_HEIGHT;
    const collared = derive(current.clone(), current);
    collared.onBeforeCompile = (shader) => {
      shader.uniforms.collarCut = { value: cut };
      shader.uniforms.collarColor = { value: COLLAR };
      shader.vertexShader = shader.vertexShader
        .replace(
          "#include <common>",
          "#include <common>\nvarying float vBindZ;",
        )
        .replace(
          "#include <begin_vertex>",
          "#include <begin_vertex>\nvBindZ = position.z;",
        );
      shader.fragmentShader = shader.fragmentShader
        .replace(
          "#include <common>",
          "#include <common>\nvarying float vBindZ;\nuniform float collarCut;\nuniform vec3 collarColor;",
        )
        .replace(
          "#include <map_fragment>",
          "#include <map_fragment>\nif (vBindZ < collarCut) diffuseColor.rgb = collarColor;",
        );
    };
    collared.customProgramCacheKey = () => "character-collar";
    mesh.material = collared;

    return () => {
      collared.dispose();
      if (mesh.material === collared) mesh.material = current;
    };
  });

  return () => undo.forEach((step) => step());
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
        position.array as Float32Array,
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
