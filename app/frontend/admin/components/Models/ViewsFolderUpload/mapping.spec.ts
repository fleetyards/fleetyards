import { describe, expect, it } from "vitest";
import { mapViewFiles, viewFieldFor } from "./mapping";

describe("viewFieldFor", () => {
  it("maps the four viewpoints", () => {
    expect(viewFieldFor("top.png")).toBe("topView");
    expect(viewFieldFor("side.png")).toBe("sideView");
    expect(viewFieldFor("front.png")).toBe("frontView");
    expect(viewFieldFor("angled.png")).toBe("angledView");
  });

  it("maps the colored variants", () => {
    expect(viewFieldFor("angled_colored.png")).toBe("angledViewColored");
    expect(viewFieldFor("top-colored.webp")).toBe("topViewColored");
  });

  it("maps the extended variants", () => {
    expect(viewFieldFor("extended_front.png")).toBe("extendedFrontView");
    expect(viewFieldFor("extended_angled_colored.png")).toBe(
      "extendedAngledViewColored",
    );
  });

  it("takes a spelled-out view and any case", () => {
    expect(viewFieldFor("top_view.png")).toBe("topView");
    expect(viewFieldFor("Extended_Side_View_Colored.PNG")).toBe(
      "extendedSideViewColored",
    );
  });

  it("reads through the folder a file was picked from", () => {
    expect(viewFieldFor("Carrack/angled.png")).toBe("angledView");
  });

  it("leaves anything else alone", () => {
    expect(viewFieldFor(".DS_Store")).toBeUndefined();
    expect(viewFieldFor("hero.png")).toBeUndefined();
    expect(viewFieldFor("holo.png")).toBeUndefined();
    expect(viewFieldFor("top_left.png")).toBeUndefined();
  });
});

describe("mapViewFiles", () => {
  const map = (filenames: string[]) =>
    mapViewFiles(filenames, (filename) => filename);

  it("reports what it could not place", () => {
    const { matched, ignored } = map(["top.png", "notes.txt"]);

    expect(matched.map((view) => view.field)).toEqual(["topView"]);
    expect(ignored).toEqual(["notes.txt"]);
  });

  it("keeps the first of two files claiming one view", () => {
    const { matched, ignored } = map(["top.png", "top_view.png"]);

    expect(matched.map((view) => view.filename)).toEqual(["top.png"]);
    expect(ignored).toEqual(["top_view.png"]);
  });

  it("places a whole folder", () => {
    const { matched, ignored } = map([
      "Carrack/top.png",
      "Carrack/side.png",
      "Carrack/front.png",
      "Carrack/angled.png",
      "Carrack/angled_colored.png",
      "Carrack/extended_top.png",
    ]);

    expect(matched.map((view) => view.field)).toEqual([
      "topView",
      "sideView",
      "frontView",
      "angledView",
      "angledViewColored",
      "extendedTopView",
    ]);
    expect(ignored).toEqual([]);
  });
});
