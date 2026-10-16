import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import {
  FIELD_ORDER,
  HOLO_FIELDS,
  VIEW_FIELDS,
  fieldFor,
  mapFolderFiles,
} from "./mapping";

// The import from the ship-views bucket maps filenames in Ruby
// (ScData::ShipViewFields), so both suites read the same cases.
const FILENAME_CASES: { name: string; cases: Record<string, string | null> }[] =
  JSON.parse(
    readFileSync(
      resolve(
        __dirname,
        "../../../../../../test/fixtures/files/ship_view_filenames.json",
      ),
      "utf8",
    ),
  );

describe("fieldFor", () => {
  describe.each(FILENAME_CASES)("$name", ({ cases }) => {
    it.each(Object.entries(cases))("%s → %s", (filename, field) => {
      expect(fieldFor(filename) ?? null).toBe(field);
    });
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

describe("the flight family", () => {
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

// The form draws its inputs from the sections, and the API knows the fields
// from these lists: a field missing from either has no input, or no column.
describe("the form's sections", () => {
  it("hold every field once", () => {
    expect([...FIELD_ORDER].sort()).toEqual(
      [...VIEW_FIELDS, ...HOLO_FIELDS].sort(),
    );
  });
});
