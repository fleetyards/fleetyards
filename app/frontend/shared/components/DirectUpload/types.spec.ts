import { describe, expect, it } from "vitest";
import { fileTypeOf } from "./types";

describe("fileTypeOf", () => {
  it("keeps the type the browser reported", () => {
    expect(fileTypeOf({ name: "top.png", type: "image/png" })).toBe(
      "image/png",
    );
  });

  it("types a model by its extension over what the browser reported", () => {
    expect(
      fileTypeOf({ name: "flight_holo.usdz", type: "application/zip" }),
    ).toBe("model/vnd.usdz+zip");
    expect(
      fileTypeOf({ name: "holo.glb", type: "application/octet-stream" }),
    ).toBe("model/gltf-binary");
  });

  it("types an untyped glTF by its extension", () => {
    expect(fileTypeOf({ name: "holo.glb", type: "" })).toBe(
      "model/gltf-binary",
    );
    expect(fileTypeOf({ name: "Holo.GLTF", type: "" })).toBe("model/gltf+json");
  });

  it("types an untyped USDZ by its extension", () => {
    expect(fileTypeOf({ name: "flight_holo.usdz", type: "" })).toBe(
      "model/vnd.usdz+zip",
    );
  });

  it("leaves any other untyped file untyped", () => {
    expect(fileTypeOf({ name: "holo.blend", type: "" })).toBe("");
    expect(fileTypeOf({ name: "glb", type: "" })).toBe("");
  });
});
