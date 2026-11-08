import { describe, expect, it } from "vitest";
import type { CharacterMesh } from "@/shared/components/HoloViewer/character/types";
import type { CharacterBody, EquipmentHeadWear } from "@/services/fyApi/models";
import {
  characterMeshes,
  characterRig,
  headWearState,
} from "./dressingRoomCharacter";
import cases from "./dressingRoomCharacter.fixtures.json";

// Resolved by the server without anything worn, then worn as the reference
// resolves it with that one item on.
type Case = {
  name: string;
  headWear: EquipmentHeadWear;
  character: {
    hidden_parts: Record<string, string[]>;
    meshes: CharacterMesh[];
  };
  expected: {
    hidden_ports: string[];
    meshes: { port: string; url: string; headwear_variant: string | null }[];
  };
};

describe("headwear", () => {
  for (const testCase of cases as unknown as Case[]) {
    it(`hides and swaps hair as the reference does for ${testCase.name}`, () => {
      const { tags, hidden } = headWearState(
        [testCase.headWear],
        testCase.character.hidden_parts,
      );
      const meshes = characterMeshes(testCase.character.meshes, tags, hidden);

      expect([...hidden].sort()).toEqual(testCase.expected.hidden_ports);
      expect(
        meshes.map(({ port, url, variant }) => ({
          port,
          url,
          headwear_variant: variant,
        })),
      ).toEqual(testCase.expected.meshes);
    });
  }

  it("keeps everything on show with nothing worn", () => {
    const testCase = (cases as unknown as Case[])[0];
    const { tags, hidden } = headWearState([], testCase.character.hidden_parts);

    expect(
      characterMeshes(testCase.character.meshes, tags, hidden).map(
        (mesh) => mesh.port,
      ),
    ).toEqual(testCase.character.meshes.map((mesh) => mesh.port));
  });
});

describe("characterRig", () => {
  const media = (name: string) => ({
    url: `/${name}`,
    name,
    contentType: "application/octet-stream",
    size: 1,
  });
  const body = {
    key: "male",
    faceLibrary: {
      library: "male-6a268db0",
      index: media("index.json"),
      positions: media("library.bin"),
      normals: media("normals.bin"),
    },
  } as unknown as CharacterBody;
  const character = {
    body: "male",
    source: { face_library: "male-6a268db0", library_stamp_ok: true },
    face: { weights: null },
    skin: {
      tone: null,
      body_baseColorFactor: [1, 1, 1],
      head: {
        base: null,
        tone_gain: [1, 1, 1],
        layers: [],
        normal: null,
        orm: null,
      },
    },
    eyes: { iris: null, iris_color: "#272727", sclera: "#d9d0c8" },
    meshes: [],
    hidden_parts: { Head_ItemPort: ["head_itemport", "hair_itemport"] },
  };
  const hat: EquipmentHeadWear = {
    type: "Char_Clothing_Hat",
    fit: "face_wrap",
    hairTag: "hatHair",
    maskFacialHair: false,
    addsTags: [],
    hiddenParts: [],
  };
  const helmet: EquipmentHeadWear = {
    type: "Char_Armor_Helmet",
    fit: "rigid",
    hairTag: "snoopy_cap",
    maskFacialHair: true,
    addsTags: [],
    hiddenParts: ["Head_ItemPort"],
  };

  it("draws the character with the body's face library and fits hats to the face", () => {
    const rig = characterRig(body, character, "token", [
      { path: "/hat.glb", headWear: hat },
    ]);

    expect(rig?.library).toEqual({
      id: "male-6a268db0",
      urls: {
        index: "/index.json",
        positions: "/library.bin",
        normals: "/normals.bin",
      },
    });
    expect(rig?.faceWrap).toEqual(["/hat.glb"]);
    expect(rig?.hideHead).toBe(false);
  });

  it("hides the whole head under a closed helmet", () => {
    expect(
      characterRig(body, character, "token", [
        { path: "/helmet.glb", headWear: helmet },
      ])?.hideHead,
    ).toBe(true);
  });

  it("draws nothing for a character of the other body, or a body without a face library", () => {
    expect(
      characterRig(
        { ...body, key: "female" } as CharacterBody,
        character,
        "token",
      ),
    ).toBeUndefined();
    expect(
      characterRig(
        { ...body, faceLibrary: null } as CharacterBody,
        character,
        "token",
      ),
    ).toBeUndefined();
  });
});
