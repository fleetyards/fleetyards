import { describe, expect, it } from "vitest";
import { fieldFor, mapFolderFiles } from "./mapping";

describe("fieldFor", () => {
  it("maps the four viewpoints", () => {
    expect(fieldFor("top.png")).toBe("topView");
    expect(fieldFor("side.png")).toBe("portView");
    expect(fieldFor("front.png")).toBe("frontView");
    expect(fieldFor("angled.png")).toBe("angledView");
  });

  it("maps a port view, which older exports name side", () => {
    expect(fieldFor("port.png")).toBe("portView");
    expect(fieldFor("landed_port_colored.png")).toBe("landedPortViewColored");
    expect(fieldFor("extended-side.png")).toBe("extendedPortView");
    expect(fieldFor("sideView.png")).toBe("portView");
    expect(fieldFor("portViewColored.png")).toBe("portViewColored");
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

  it("maps the views from behind and below", () => {
    expect(fieldFor("flight_angled_rear.png")).toBe("angledRearView");
    expect(fieldFor("angled-rear-colored.png")).toBe("angledRearViewColored");
    expect(fieldFor("bottom.png")).toBe("bottomView");
    expect(fieldFor("extended_rear_view.png")).toBe("extendedRearView");
    expect(fieldFor("landed_starboard_colored.png")).toBe(
      "landedStarboardViewColored",
    );
    expect(fieldFor("Landed_AngledRear.PNG")).toBe("landedAngledRearView");
  });

  it("maps the lite holos of every state", () => {
    expect(fieldFor("flight_holo_lite.glb")).toBe("holoLite");
    expect(fieldFor("holo-lite.gltf")).toBe("holoLite");
    expect(fieldFor("extended_holo_lite.glb")).toBe("extendedHoloLite");
    expect(fieldFor("landed_holo_lite.glb")).toBe("landedHoloLite");
  });

  // Only the flying pose is exported painted, so a prefixed one has nowhere to go.
  it("maps the textured holo of the flight state alone", () => {
    expect(fieldFor("flight_holo_textured.glb")).toBe("holoTextured");
    expect(fieldFor("holo_textured.glb")).toBe("holoTextured");
    expect(fieldFor("landed_holo_textured.glb")).toBeUndefined();
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

  // Every join in a name takes either separator, or none: the prefix to the
  // viewpoint, the viewpoint to "view", and "view" to "colored".
  it("takes a dash or an underscore at every join", () => {
    expect(fieldFor("landed-top-view-colored.png")).toBe(
      "landedTopViewColored",
    );
    expect(fieldFor("landed_top_view_colored.png")).toBe(
      "landedTopViewColored",
    );
    expect(fieldFor("flight-angled_view-colored.png")).toBe(
      "angledViewColored",
    );
    expect(fieldFor("extended-holo.glb")).toBe("extendedHolo");
    expect(fieldFor("extended_holo.glb")).toBe("extendedHolo");
  });

  it("takes a spelled-out view and any case", () => {
    expect(fieldFor("top_view.png")).toBe("topView");
    expect(fieldFor("Extended_Side_View_Colored.PNG")).toBe(
      "extendedPortViewColored",
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

  // However the folder was read: state by state, holos before views, in the
  // form's order.
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
      "holo",
      "angledView",
      "topView",
      "topViewColored",
      "frontViewColored",
      "extendedTopView",
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
      "holo",
      "angledView",
      "topView",
      "frontView",
      "portView",
      "angledViewColored",
    ]);
    expect(ignored).toEqual(["holo.blend"]);
  });
});

describe("the landed family", () => {
  it("maps a landed holo", () => {
    expect(fieldFor("landed-holo.glb")).toBe("landedHolo");
    expect(fieldFor("landed_holo.gltf")).toBe("landedHolo");
    expect(fieldFor("LandedHolo.glb")).toBe("landedHolo");
  });

  it("maps landed views, coloured and not", () => {
    expect(fieldFor("landed-side.png")).toBe("landedPortView");
    expect(fieldFor("landed_top_view.png")).toBe("landedTopView");
    expect(fieldFor("landed angled colored.png")).toBe(
      "landedAngledViewColored",
    );
  });

  // The two prefixes share a regex, so the one that matched has to decide.
  it("keeps the two states apart", () => {
    expect(fieldFor("extended-side.png")).toBe("extendedPortView");
    expect(fieldFor("landed-side.png")).toBe("landedPortView");
    expect(fieldFor("side.png")).toBe("portView");
  });
});

describe("the flight family", () => {
  it("maps a flight holo to the default field", () => {
    expect(fieldFor("flight-holo.glb")).toBe("holo");
    expect(fieldFor("flight_holo.gltf")).toBe("holo");
    expect(fieldFor("FlightHolo.glb")).toBe("holo");
  });

  it("maps flight views to the default fields, coloured and not", () => {
    expect(fieldFor("flight-side.png")).toBe("portView");
    expect(fieldFor("flight_top_view.png")).toBe("topView");
    expect(fieldFor("flight angled colored.png")).toBe("angledViewColored");
    expect(fieldFor("Flight_Front_View_Colored.PNG")).toBe("frontViewColored");
  });

  // A folder that spells the default state out and one that leaves it off name
  // the same field, so the second file is the duplicate it looks like.
  it("collides with the unprefixed set", () => {
    const { matched, ignored } = mapFolderFiles(
      ["flight-top.png", "top.png"],
      (filename) => filename,
    );

    expect(matched.map((entry) => entry.field)).toEqual(["topView"]);
    expect(ignored).toEqual(["top.png"]);
  });
});
