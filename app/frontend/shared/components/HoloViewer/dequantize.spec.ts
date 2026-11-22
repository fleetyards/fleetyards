import { type Mesh, type SkinnedMesh, Vector3 } from "three";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { describe, expect, it } from "vitest";
import { floatArray } from "./dequantize";
import { prepareGltfLoader } from "./gltfLoader";

// A triangle authored at (0,0,0), (4,0,0) and (0,2,0), quantized the way
// glTF-Transform does: stored in a [-1, 1] box around (2,1,0) at scale 2, with
// that scale and offset carried by the skin's inverse bind matrices or, for a
// rigid mesh, by its node.
const AUTHORED = [0, 0, 0, 4, 0, 0, 0, 2, 0];
const QUANTIZED = [-32767, -16384, 0, 32767, -16384, 0, -32767, 16384, 0];
const DEQUANTIZE = [2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 2, 1, 0, 1];
// The joint stands at (0,1,0), so its inverse bind matrix moves by (0,-1,0).
const IBM = [2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 2, 0, 0, 1];

const glb = (skinned: boolean) => {
  const positions = new Int16Array(10);
  positions.set(QUANTIZED);
  const joints = new Uint8Array(12);
  const weights = new Float32Array([1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0]);
  const ibm = new Float32Array(IBM);
  // Quantized normals, facing +z.
  const normals = Int8Array.from([0, 0, 127, 0, 0, 0, 127, 0, 0, 0, 127, 0]);
  const chunks = [positions, joints, weights, ibm, normals].map(
    (array) => new Uint8Array(array.buffer),
  );
  const offsets: number[] = [];
  let binLength = 0;
  chunks.forEach((chunk) => {
    offsets.push(binLength);
    binLength += chunk.byteLength;
  });

  const view = (index: number) => ({
    buffer: 0,
    byteOffset: offsets[index],
    byteLength: chunks[index].byteLength,
  });

  const json = {
    asset: { version: "2.0" },
    extensionsUsed: ["KHR_mesh_quantization"],
    extensionsRequired: ["KHR_mesh_quantization"],
    scene: 0,
    scenes: [{ nodes: skinned ? [0, 1] : [0] }],
    nodes: skinned
      ? [
          { name: "body", mesh: 0, skin: 0 },
          { name: "spine", translation: [0, 1, 0] },
        ]
      : [{ name: "hull", mesh: 0, matrix: DEQUANTIZE }],
    meshes: [
      {
        primitives: [
          {
            attributes: skinned
              ? { POSITION: 0, NORMAL: 4, JOINTS_0: 1, WEIGHTS_0: 2 }
              : { POSITION: 0 },
          },
        ],
      },
    ],
    skins: skinned ? [{ joints: [1], inverseBindMatrices: 3 }] : undefined,
    buffers: [{ byteLength: binLength }],
    bufferViews: [
      view(0),
      view(1),
      view(2),
      view(3),
      { ...view(4), byteStride: 4 },
    ],
    accessors: [
      {
        bufferView: 0,
        componentType: 5122,
        normalized: true,
        count: 3,
        type: "VEC3",
        min: [-32767, -16384, 0],
        max: [32767, 16384, 0],
      },
      { bufferView: 1, componentType: 5121, count: 3, type: "VEC4" },
      { bufferView: 2, componentType: 5126, count: 3, type: "VEC4" },
      { bufferView: 3, componentType: 5126, count: 1, type: "MAT4" },
      {
        bufferView: 4,
        componentType: 5120,
        normalized: true,
        count: 3,
        type: "VEC3",
      },
    ],
  };

  const text = new TextEncoder().encode(JSON.stringify(json));
  const jsonLength = Math.ceil(text.byteLength / 4) * 4;
  const out = new Uint8Array(12 + 8 + jsonLength + 8 + binLength);
  const data = new DataView(out.buffer);
  data.setUint32(0, 0x46546c67, true);
  data.setUint32(4, 2, true);
  data.setUint32(8, out.byteLength, true);
  data.setUint32(12, jsonLength, true);
  data.setUint32(16, 0x4e4f534a, true);
  out.fill(0x20, 20, 20 + jsonLength);
  out.set(text, 20);
  data.setUint32(20 + jsonLength, binLength, true);
  data.setUint32(24 + jsonLength, 0x004e4942, true);
  chunks.forEach((chunk, index) =>
    out.set(chunk, 28 + jsonLength + offsets[index]),
  );

  return out.buffer;
};

const load = (skinned: boolean) =>
  prepareGltfLoader(new GLTFLoader()).parseAsync(glb(skinned), "");

const meshOf = (scene: { traverse: Mesh["traverse"] }) => {
  let found: Mesh | undefined;
  scene.traverse((node) => {
    if ((node as Mesh).isMesh) found = node as Mesh;
  });
  return found!;
};

const expectPoints = (actual: ArrayLike<number>, expected: number[]) =>
  expected.forEach((value, index) =>
    expect(actual[index]).toBeCloseTo(value, 3),
  );

describe("dequantizeSkins", () => {
  it("stores a quantized skin's points where they were authored", async () => {
    const { scene } = await load(true);
    const mesh = meshOf(scene) as SkinnedMesh;

    expectPoints(floatArray(mesh.geometry.getAttribute("position")), AUTHORED);
    expect(mesh.geometry.boundingBox?.max.x).toBeCloseTo(4, 3);
    expectPoints(
      floatArray(mesh.geometry.getAttribute("normal")),
      [0, 0, 1, 0, 0, 1, 0, 0, 1],
    );
  });

  it("draws the skin where it drew before", async () => {
    const { scene } = await load(true);
    const mesh = meshOf(scene) as SkinnedMesh;
    scene.updateMatrixWorld(true);
    mesh.skeleton.update();

    const point = new Vector3();
    const drawn = [0, 1, 2].flatMap((index) =>
      mesh.getVertexPosition(index, point).toArray(),
    );

    expectPoints(drawn, AUTHORED);
  });

  // A hull is only measured through its node, and four bytes a point is what
  // the largest ships cannot spare.
  it("leaves a rigid mesh quantized", async () => {
    const { scene } = await load(false);
    const position = meshOf(scene).geometry.getAttribute("position");

    expect(position.array).toBeInstanceOf(Int16Array);
  });
});

describe("floatArray", () => {
  it("reads normalized integers as the floats they stand for", async () => {
    const { scene } = await load(false);

    expectPoints(
      floatArray(meshOf(scene).geometry.getAttribute("position")),
      [-1, -0.5, 0, 1, -0.5, 0, -1, 0.5, 0],
    );
  });
});
