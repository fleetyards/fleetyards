import { describe, expect, it } from "vitest";
import { type MediaFile } from "@/services/fyApi";
import {
  outfitModel,
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

  it("puts every piece on the body at the origin", () => {
    const model = outfitModel(file("/body.glb", 8), [core, legs]);

    expect(model?.path).toBe("/body.glb");
    expect(model?.frameMounts).toBe(true);
    expect(model?.mounts.map((mount) => mount.path)).toEqual([
      "/core.glb",
      "/legs.glb",
    ]);
    expect(model?.mounts[0]).toMatchObject({
      position: [0, 0, 0],
      rotation: [0, 0, 0, 1],
      textured: true,
    });
  });

  it("roots the figure on its first piece without a body", () => {
    const model = outfitModel(undefined, [core, legs]);

    expect(model).toMatchObject({ path: "/core.glb", textured: true });
    expect(model?.mounts.map((mount) => mount.path)).toEqual(["/legs.glb"]);
  });

  it("has nothing to draw without a body or a piece", () => {
    expect(outfitModel(undefined, [])).toBeUndefined();
  });
});
