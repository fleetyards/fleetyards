import type { FaceLibraryUrls, FaceWeights } from "./faceLibrary";

// A three.js MeshStandardMaterial parameter set as the character export writes
// it: colours linear, maps by URL.
export type CharacterThreeMaterial = {
  type?: string;
  color?: number[];
  map?: string | null;
  alphaMap?: string | null;
  alphaTest?: number;
  transparent?: boolean;
  depthWrite?: boolean;
  opacity?: number;
  side?: "DoubleSide" | "FrontSide";
  roughness?: number;
  metalness?: number;
  polygonOffset?: boolean;
  polygonOffsetFactor?: number;
  texCoord?: number;
  alphaToCoverage?: boolean;
  // How much a strand card's opacity is raised per mip level.
  alphaMipScale?: number;
  specularIntensity?: number;
  specularColor?: number[];
};

export type CharacterSubmaterial =
  | { submaterial: number; visible: false }
  | {
      submaterial: number;
      material: {
        name: string;
        mode: string;
        three: CharacterThreeMaterial;
        // Per-strand variation: color *= 1 + amount * (id - 0.5).
        variation?: { map: string | null; amount: number };
      };
    };

export type CharacterMeshVariant = {
  // On a rig: the port it is worn on.
  port?: string;
  url: string | null;
  materials_by_submaterial: CharacterSubmaterial[];
};

export type CharacterMesh = CharacterMeshVariant & {
  port: string;
  item: string;
  record: string;
  kind: string;
  headwear_variant: string | null;
  // Hair, beard and stubble: the geometry worn headwear swaps to, by tag.
  headwear?: Record<string, CharacterMeshVariant>;
};

export type HeadLayer =
  | {
      type: "blemish";
      mask: string | null;
      id: string | null;
      freckles: BlemishChannel;
      sunspots: BlemishChannel;
    }
  | {
      type: "makeup";
      slot: number;
      texture: string | null;
      channels: { color: string; opacity: number }[];
    }
  | {
      type: "tattoo";
      texture: string | null;
      blend: "alpha" | "multiply";
      age: number;
      hue: number;
    };

export type BlemishChannel = {
  amount: number;
  opacity: number;
  channel: number;
  darken: number;
};

export type HeadRecipe = {
  base: string | null;
  tone_gain: number[];
  layers: HeadLayer[];
  normal: string | null;
  orm: string | null;
};

export type EyeRecipe = {
  iris: string | null;
  iris_color: string;
  sclera: string;
};

// What the server resolves a character file into, every asset path replaced
// by its URL.
export type ResolvedCharacter = {
  body: string;
  source: { face_library: string; library_stamp_ok: boolean | null };
  face: { weights: FaceWeights | null };
  skin: {
    tone: string | null;
    body_baseColorFactor: number[];
    head: HeadRecipe;
  };
  eyes: EyeRecipe;
  meshes: CharacterMesh[];
  hidden_parts: Record<string, string[]>;
  // Which hair variant worn headwear picks first.
  headwear_order?: string[];
};

// The character as the viewer draws it on a rigged body.
export type CharacterRig = {
  // Which character and which choices: a change of either rebuilds it.
  key: string;
  library: { id: string; urls: FaceLibraryUrls };
  weights: FaceWeights | null;
  meshes: CharacterMeshVariant[];
  // Skin, eyes and accessory materials apply on the painted body only; a clay
  // body keeps everything clay.
  skin: ResolvedCharacter["skin"];
  eyes: EyeRecipe;
  // The whole head is hidden under a closed helmet.
  hideHead: boolean;
  // Worn pieces, by path, that follow the face like the hair does.
  faceWrap: string[];
};
