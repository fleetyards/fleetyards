import { describe, expect, it } from "vitest";
import { fileTypeOf } from "./types";

describe("fileTypeOf", () => {
  it("keeps the type the browser reported", () => {
    expect(
      fileTypeOf({ name: "holo.glb", type: "application/octet-stream" }),
    ).toBe("application/octet-stream");
  });

  it("types an untyped glTF by its extension", () => {
    expect(fileTypeOf({ name: "holo.glb", type: "" })).toBe(
      "model/gltf-binary",
    );
    expect(fileTypeOf({ name: "Holo.GLTF", type: "" })).toBe("model/gltf+json");
  });

  it("leaves any other untyped file untyped", () => {
    expect(fileTypeOf({ name: "holo.blend", type: "" })).toBe("");
    expect(fileTypeOf({ name: "glb", type: "" })).toBe("");
  });
});
