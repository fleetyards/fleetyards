import { describe, expect, it } from "vitest";
import { fieldFor, mapFolderFiles } from "./mapping";

describe("fieldFor", () => {
  it("maps the four viewpoints", () => {
    expect(fieldFor("top.png")).toBe("topView");
    expect(fieldFor("side.png")).toBe("sideView");
    expect(fieldFor("front.png")).toBe("frontView");
    expect(fieldFor("angled.png")).toBe("angledView");
  });

  it("maps the colored variants", () => {
    expect(fieldFor("angled_colored.png")).toBe("angledViewColored");
    expect(fieldFor("top-colored.webp")).toBe("topViewColored");
  });

  it("maps the extended variants", () => {
    expect(fieldFor("extended_front.png")).toBe("extendedFrontView");
    expect(fieldFor("extended_angled_colored.png")).toBe(
      "extendedAngledViewColored",
    );
  });

  it("maps the holo models", () => {
    expect(fieldFor("holo.gltf")).toBe("holo");
    expect(fieldFor("holo.glb")).toBe("holo");
    expect(fieldFor("extended_holo.gltf")).toBe("extendedHolo");
  });

  // A Blender export drops these beside the glTF, and every one of them answers
  // to "holo".
  it("leaves the rest of a 3D export alone", () => {
    expect(fieldFor("holo.blend")).toBeUndefined();
    expect(fieldFor("holo.blend1")).toBeUndefined();
    expect(fieldFor("holo.obj")).toBeUndefined();
    expect(fieldFor("holo.mtl")).toBeUndefined();
    expect(fieldFor("holo.png")).toBeUndefined();
  });

  it("takes a spelled-out view and any case", () => {
    expect(fieldFor("top_view.png")).toBe("topView");
    expect(fieldFor("Extended_Side_View_Colored.PNG")).toBe(
      "extendedSideViewColored",
    );
  });

  it("reads through the folder a file was picked from", () => {
    expect(fieldFor("Carrack/angled.png")).toBe("angledView");
  });

  it("wants a picture where it expects one", () => {
    expect(fieldFor("top.gltf")).toBeUndefined();
    expect(fieldFor("angled")).toBeUndefined();
  });

  it("leaves anything else alone", () => {
    expect(fieldFor(".DS_Store")).toBeUndefined();
    expect(fieldFor("hero.png")).toBeUndefined();
    expect(fieldFor("export.obj")).toBeUndefined();
    expect(fieldFor("top_left.png")).toBeUndefined();
  });
});

describe("mapFolderFiles", () => {
  const map = (filenames: string[]) =>
    mapFolderFiles(filenames, (filename) => filename);

  it("reports what it could not place", () => {
    const { matched, ignored } = map(["top.png", "notes.txt"]);

    expect(matched.map((entry) => entry.field)).toEqual(["topView"]);
    expect(ignored).toEqual(["notes.txt"]);
  });

  it("keeps the first of two files claiming one field", () => {
    const { matched, ignored } = map(["top.png", "top_view.png"]);

    expect(matched.map((entry) => entry.filename)).toEqual(["top.png"]);
    expect(ignored).toEqual(["top_view.png"]);
  });

  // However the folder was read: base set, colored set, extended set, holos.
  it("lists the fields in a fixed order", () => {
    const { matched } = map([
      "Carrack/front-colored.png",
      "Carrack/holo.gltf",
      "Carrack/angled.png",
      "Carrack/extended_top.png",
      "Carrack/top.png",
      "Carrack/top-colored.png",
    ]);

    expect(matched.map((entry) => entry.field)).toEqual([
      "topView",
      "angledView",
      "topViewColored",
      "frontViewColored",
      "extendedTopView",
      "holo",
    ]);
  });

  it("places a whole folder", () => {
    const { matched, ignored } = map([
      "Carrack/top.png",
      "Carrack/side.png",
      "Carrack/front.png",
      "Carrack/angled.png",
      "Carrack/angled_colored.png",
      "Carrack/holo.gltf",
      "Carrack/holo.blend",
    ]);

    expect(matched.map((entry) => entry.field)).toEqual([
      "topView",
      "sideView",
      "frontView",
      "angledView",
      "angledViewColored",
      "holo",
    ]);
    expect(ignored).toEqual(["holo.blend"]);
  });
});
