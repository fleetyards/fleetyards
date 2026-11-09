import type {
  CharacterMesh,
  CharacterMeshVariant,
  CharacterRig,
  ResolvedCharacter,
} from "@/shared/components/HoloViewer/character/types";
import type { CharacterBody, EquipmentHeadWear } from "@/services/fyApi/models";

// The game's rule for what worn headwear does to the hair: the tags every worn
// item pushes onto the character pick the hair and beard variants, and the
// parts it hides are taken off. Hiding wins over swapping. The export says in
// which order hair variants are picked; this is its order for a character
// resolved before it said so.
export const HAIR_VARIANT_ORDER = ["snoopy_cap", "hatHair_mask", "hatHair"];
export const FACIAL_HAIR_VARIANT = "maskFacialHair";
const FACIAL_HAIR_PORTS = ["beard_itemport", "stubble_itemport"];

export type WornHeadWear = { path?: string; headWear: EquipmentHeadWear };

export const headWearState = (
  worn: EquipmentHeadWear[],
  hiddenParts: Record<string, string[]>,
) => {
  const parts = Object.fromEntries(
    Object.entries(hiddenParts).map(([part, ports]) => [
      part.toLowerCase(),
      ports,
    ]),
  );
  const tags = new Set<string>();
  const hidden = new Set<string>();

  worn.forEach((item) => {
    if (item.hairTag) tags.add(item.hairTag);
    item.addsTags.forEach((tag) => tags.add(tag));
    if (item.maskFacialHair) tags.add(FACIAL_HAIR_VARIANT);
    item.hiddenParts.forEach((part) =>
      (parts[part.toLowerCase()] ?? []).forEach((port) => hidden.add(port)),
    );
  });

  return { tags, hidden };
};

const variantOrder = (port: string, hairOrder: string[]) => {
  if (port === "hair_itemport") return hairOrder;
  if (FACIAL_HAIR_PORTS.includes(port)) return [FACIAL_HAIR_VARIANT];
  return [];
};

// The mesh each port shows under these tags, and which variant it is.
export const characterMeshes = (
  meshes: CharacterMesh[],
  tags: Set<string>,
  hidden: Set<string>,
  hairOrder: string[] = HAIR_VARIANT_ORDER,
) =>
  meshes
    .filter((mesh) => !hidden.has(mesh.port))
    .map((mesh) => {
      const variant = variantOrder(mesh.port, hairOrder).find(
        (tag) => tags.has(tag) && mesh.headwear?.[tag],
      );
      const chosen: CharacterMeshVariant = variant
        ? mesh.headwear![variant]
        : mesh;

      return {
        port: mesh.port,
        variant: variant ?? null,
        url: chosen.url,
        materials_by_submaterial: chosen.materials_by_submaterial,
      };
    });

export const characterRig = (
  body: CharacterBody,
  character: ResolvedCharacter,
  token: string,
  worn: WornHeadWear[] = [],
): CharacterRig | undefined => {
  if (!body.faceLibrary || character.body !== body.key) return undefined;

  const { tags, hidden } = headWearState(
    worn.map((item) => item.headWear),
    character.hidden_parts,
  );
  const meshes = characterMeshes(
    character.meshes,
    tags,
    hidden,
    character.headwear_order,
  );
  const faceWrap = worn
    .filter((item) => item.path && item.headWear.fit === "face_wrap")
    .map((item) => item.path as string);

  return {
    key: [
      token,
      ...meshes.map((mesh) => `${mesh.port}:${mesh.variant ?? ""}`),
      ...faceWrap,
    ].join("|"),
    library: {
      id: body.faceLibrary.library,
      urls: {
        index: body.faceLibrary.index.url,
        positions: body.faceLibrary.positions.url,
        normals: body.faceLibrary.normals.url,
      },
    },
    weights: character.face.weights,
    meshes: meshes.map(({ port, url, materials_by_submaterial }) => ({
      port,
      url,
      materials_by_submaterial,
    })),
    skin: character.skin,
    eyes: character.eyes,
    hideHead: hidden.has("head_itemport"),
    faceWrap,
  };
};
