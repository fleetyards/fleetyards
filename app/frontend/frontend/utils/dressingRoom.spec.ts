import { describe, expect, it } from "vitest";
import { type MediaFile } from "@/services/fyApi";
import { OutfitBodyEnum, OutfitSlotEnum } from "@/services/fyApi";
import {
  OUTFIT_SLOTS,
  RIG_ORDER,
  clipLabel,
  outfitModel,
  riggedOutfitModel,
  riggedPieceHolo,
  outfitQuery,
  parseOutfitQuery,
  pieceHolo,
  sameOutfit,
} from "./dressingRoom";

const file = (url: string, size = 10): MediaFile => ({
  url,
  size,
  name: url.slice(1),
  contentType: "model/gltf-binary",
});

describe("parseOutfitQuery", () => {
  it("reads one slug per slot and ignores everything else", () => {
    expect(
      parseOutfitQuery({
        helmet: "adp-mk4-helmet",
        torso: ["adp-core", "antium-core"],
        legs: "",
        textured: "true",
      }),
    ).toEqual({ helmet: "adp-mk4-helmet", torso: "adp-core" });
  });

  it("round-trips through the query it writes", () => {
    const selection = { arms: "adp-arms", undersuit: "tcs-4-undersuit" };

    expect(parseOutfitQuery(outfitQuery(selection) as never)).toEqual(
      selection,
    );
  });
});

describe("sameOutfit", () => {
  it("compares slot by slot, whatever the key order", () => {
    expect(sameOutfit({ arms: "a", legs: "b" }, { legs: "b", arms: "a" })).toBe(
      true,
    );
    expect(sameOutfit({ arms: "a" }, { arms: "a", legs: "b" })).toBe(false);
  });
});

describe("pieceHolo", () => {
  it("takes the painted holo and keeps the plain one to fall back to", () => {
    expect(
      pieceHolo({
        holo: file("/clay.glb"),
        holoTextured: file("/paint.glb", 30),
      }),
    ).toEqual({
      path: "/paint.glb",
      size: 30,
      textured: true,
      fallbackPath: "/clay.glb",
    });
  });

  it("falls back to the clay holo when there is no painted one", () => {
    expect(pieceHolo({ holo: file("/clay.glb") })).toEqual({
      path: "/clay.glb",
      size: 10,
      textured: false,
    });
  });

  it("skips a painted holo that already failed", () => {
    expect(
      pieceHolo({ holo: file("/clay.glb"), holoTextured: file("/paint.glb") }, [
        "/paint.glb",
      ])?.path,
    ).toBe("/clay.glb");
  });

  it("has nothing for an item without a holo", () => {
    expect(pieceHolo({})).toBeUndefined();
    expect(pieceHolo(undefined)).toBeUndefined();
  });
});

describe("outfitModel", () => {
  const core = { path: "/core.glb", size: 5, textured: true };
  const legs = { path: "/legs.glb", size: 4, textured: false };

  it("roots the static figure on its first piece and mounts the rest at the origin", () => {
    const model = outfitModel([core, legs]);

    expect(model).toMatchObject({
      path: "/core.glb",
      textured: true,
      frameMounts: true,
    });
    expect(model?.mounts?.map((mount) => mount.path)).toEqual(["/legs.glb"]);
    expect(model?.mounts?.[0]).toMatchObject({
      position: [0, 0, 0],
      rotation: [0, 0, 0, 1],
    });
  });

  it("has nothing to draw without a piece", () => {
    expect(outfitModel([])).toBeUndefined();
  });
});

describe("riggedPieceHolo", () => {
  it("takes the piece's rig for the body and nothing else", () => {
    expect(
      riggedPieceHolo({
        holo: file("/clay.glb"),
        holoRiggedMale: file("/rigged.glb", 7),
      }),
    ).toEqual({ path: "/rigged.glb", size: 7, textured: false });
    expect(riggedPieceHolo({ holo: file("/clay.glb") })).toBeUndefined();
  });

  it("prefers the painted rig, with the plain rig behind it", () => {
    const media = {
      holoTextured: file("/painted.glb"),
      holoRiggedMale: file("/rigged_male.glb", 7),
      holoRiggedTexturedMale: file("/rigged_textured_male.glb", 9),
      holoRiggedFemale: file("/rigged_female.glb", 6),
    };

    expect(riggedPieceHolo(media)).toEqual({
      path: "/rigged_textured_male.glb",
      size: 9,
      textured: true,
      fallbackPath: "/rigged_male.glb",
    });
    expect(
      riggedPieceHolo(media, OutfitBodyEnum.MALE, [
        "/rigged_textured_male.glb",
      ]),
    ).toEqual({ path: "/rigged_male.glb", size: 7, textured: false });
    expect(riggedPieceHolo(media, OutfitBodyEnum.FEMALE)).toEqual({
      path: "/rigged_female.glb",
      size: 6,
      textured: false,
    });
  });
});

describe("riggedOutfitModel", () => {
  const body = {
    key: "male",
    holo: file("/body.glb", 8),
    animations: file("/animations.glb", 3),
    weaponInHand: null,
    lighting: [],
    clips: [
      { name: "idle_stand", static: false, looping: true },
      { name: "shop_pose_01", static: true, looping: false },
      { name: "shop_pose_02", static: true, looping: false },
    ],
  };
  const core = { path: "/core_rigged.glb", size: 5, textured: false };

  it("dresses the body in the rigged pieces, standing idle", () => {
    expect(riggedOutfitModel(body, [core])).toEqual({
      path: "/body.glb",
      size: 8,
      textured: false,
      rig: {
        pieces: [{ path: "/core_rigged.glb", size: 5 }],
        animations: "/animations.glb",
        clip: "idle_stand",
        pedestal: true,
      },
    });
  });

  it("passes a painted rig and its plain fallback to the viewer", () => {
    const painted = {
      path: "/core_rigged_textured.glb",
      size: 9,
      textured: true,
      fallbackPath: "/core_rigged.glb",
    };

    expect(riggedOutfitModel(body, [painted]).rig?.pieces).toEqual([painted]);
  });

  it("keeps a pose the body has, and drops one it does not", () => {
    expect(riggedOutfitModel(body, [], "shop_pose_02").rig?.clip).toBe(
      "shop_pose_02",
    );
    expect(riggedOutfitModel(body, [], "moonwalk").rig?.clip).toBe(
      "idle_stand",
    );
  });

  it("falls back to the first shop pose for a body without an idle stand", () => {
    const shopOnly = {
      ...body,
      clips: body.clips.filter((clip) => clip.name !== "idle_stand"),
    };

    expect(riggedOutfitModel(shopOnly, []).rig?.clip).toBe("shop_pose_01");
  });
});

describe("riggedOutfitModel body cover", () => {
  const body = {
    key: "male",
    holo: file("/body.glb"),
    animations: null,
    weaponInHand: null,
    lighting: [],
    clips: [],
  };

  it("draws the body under armour and a helmet as a dark undersuit", () => {
    const rig = riggedOutfitModel(
      body,
      [],
      undefined,
      [],
      ["legs", "helmet"],
    ).rig;

    expect(rig?.hide).toBeUndefined();
    expect(rig?.cover).toEqual(["legs", "head"]);
  });

  it("keeps the neck under a helmet over an undersuit", () => {
    const rig = riggedOutfitModel(
      body,
      [],
      undefined,
      [],
      ["undersuit", "helmet"],
    ).rig;

    expect(rig?.hide).toEqual(["torso", "arms", "legs"]);
    expect(rig?.cover).toEqual(["head"]);
  });

  it("hides the whole body under an undersuit", () => {
    const rig = riggedOutfitModel(
      body,
      [],
      undefined,
      [],
      ["undersuit", "torso"],
    ).rig;

    expect(rig?.hide).toEqual(["torso", "arms", "legs"]);
    expect(rig?.cover).toBeUndefined();
  });
});

describe("RIG_ORDER", () => {
  it("binds every armour slot, the core before the backpack", () => {
    expect([...RIG_ORDER].sort()).toEqual([...OUTFIT_SLOTS].sort());
    expect(RIG_ORDER.indexOf(OutfitSlotEnum.TORSO)).toBeLessThan(
      RIG_ORDER.indexOf(OutfitSlotEnum.BACKPACK),
    );
  });
});

describe("clipLabel", () => {
  it("reads a clip name as words", () => {
    expect(clipLabel("shop_med_marine_holdwrist")).toBe(
      "Shop med marine holdwrist",
    );
  });
});
