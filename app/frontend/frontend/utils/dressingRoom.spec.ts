import { describe, expect, it } from "vitest";
import { type MediaFile } from "@/services/fyApi";
import {
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
});

describe("riggedOutfitModel", () => {
  const body = {
    key: "male",
    holo: file("/body.glb", 8),
    animations: file("/animations.glb", 3),
    weaponInHand: null,
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
    clips: [],
  };

  it("draws the body under armour as a dark undersuit and hides the head under a helmet", () => {
    expect(
      riggedOutfitModel(body, [], undefined, [], ["legs", "helmet"]).rig,
    ).toMatchObject({ hide: ["head"], cover: ["legs"] });
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

describe("clipLabel", () => {
  it("reads a clip name as words", () => {
    expect(clipLabel("shop_med_marine_holdwrist")).toBe(
      "Shop med marine holdwrist",
    );
  });
});
