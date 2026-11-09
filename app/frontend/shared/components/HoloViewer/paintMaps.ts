import {
  type ColorSpace,
  type Group,
  type Mesh,
  type MeshStandardMaterial,
  SRGBColorSpace,
  type Texture,
} from "three";

export const BODY_SUFFIX = "_body";
const STENCIL_SUFFIX = "_stencil";

// A part with several materials loads as a group of meshes under its node, so
// the name marks the node and its meshes are looked for below it.
export const partMaterials = (scene: Group, suffix: string) => {
  const materials = new Set<MeshStandardMaterial>();

  scene.traverse((node) => {
    if (!node.name.endsWith(suffix)) return;

    node.traverse((child) => {
      const mesh = child as Mesh;
      if (mesh.isMesh) materials.add(mesh.material as MeshStandardMaterial);
    });
  });

  return [...materials];
};

// Written like the export's own maps, which are in glTF's orientation.
export const preparePaintMap = (
  map: Texture,
  like: Texture | null,
  colorSpace: ColorSpace,
) => {
  map.colorSpace = colorSpace;
  map.flipY = false;
  if (!like) return;

  map.wrapS = like.wrapS;
  map.wrapT = like.wrapT;
  map.anisotropy = like.anisotropy;
};

// A paint with artwork of its own draws it on the stencil mesh, whose faces
// cover the hull. Without a sheet the export's own stays: the maker's lettering.
// Out of userData, which three copies through JSON when it clones a material.
const ownStencils = new WeakMap<object, Texture | null>();

export const applyStencilMap = (scene: Group, map?: Texture) => {
  partMaterials(scene, STENCIL_SUFFIX).forEach((material) => {
    // Asked for by presence: an own map of null has to stay remembered as null.
    if (!ownStencils.has(material)) ownStencils.set(material, material.map);
    const own = ownStencils.get(material) ?? null;

    if (map) preparePaintMap(map, own, SRGBColorSpace);

    material.map = map ?? own;
    material.needsUpdate = true;
  });
};
