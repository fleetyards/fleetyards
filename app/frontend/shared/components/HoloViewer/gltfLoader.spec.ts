import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { MeshoptDecoder } from "three/examples/jsm/libs/meshopt_decoder.module.js";
import { describe, expect, it } from "vitest";
import { sharedDracoLoader } from "./dracoLoader";
import { prepareGltfLoader } from "./gltfLoader";

describe("prepareGltfLoader", () => {
  it("decodes both Draco and meshopt holos", () => {
    const loader = prepareGltfLoader(new GLTFLoader());

    expect(loader.dracoLoader).toBe(sharedDracoLoader());
    expect(loader.meshoptDecoder).toBe(MeshoptDecoder);
  });
});
