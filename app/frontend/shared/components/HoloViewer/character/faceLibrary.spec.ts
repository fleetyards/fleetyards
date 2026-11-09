import { describe, expect, it } from "vitest";
import {
  blendFace,
  decodeFaceLibrary,
  FACE_PARTS,
  type FaceLibraryIndex,
  type FaceWeights,
  PROTOS_WEIGHTS,
  undelta,
} from "./faceLibrary";
import fixtures from "./faceLibrary.fixtures.json";

// Sampled from the published libraries and their test vectors: every 89th
// head vertex, re-encoded as a small library of its own, with what the
// reference blend gives for each.
type Fixture = {
  index: FaceLibraryIndex;
  library: string;
  normals: string;
  expected: Record<
    string,
    {
      weights: Record<string, [number, number][]>;
      head: number[];
      eyes: number[];
      teeth: number[];
      headNormals: number[];
    }
  >;
};

const buffer = (base64: string) => {
  const bytes = Uint8Array.from(atob(base64), (c) => c.charCodeAt(0));
  return bytes.buffer;
};

const library = (fixture: Fixture) =>
  decodeFaceLibrary(
    fixture.index,
    buffer(fixture.library),
    buffer(fixture.normals),
  );

const maxDifference = (got: ArrayLike<number>, expected: number[]) => {
  expect(got.length).toBe(expected.length);
  return expected.reduce(
    (max, value, i) => Math.max(max, Math.abs(got[i] - value)),
    0,
  );
};

describe("blendFace", () => {
  for (const [body, fixture] of Object.entries(
    fixtures as unknown as Record<string, Fixture>,
  )) {
    const decoded = library(fixture);

    for (const [name, expected] of Object.entries(fixture.expected)) {
      it(`blends ${body} ${name} as the reference does, eyes, teeth and normals included`, () => {
        const weights: FaceWeights = FACE_PARTS.map((part) => ({
          part,
          heads: expected.weights[part],
        }));
        const face = blendFace(decoded, weights);

        expect(maxDifference(face.head, expected.head)).toBeLessThan(1e-5);
        expect(maxDifference(face.eyes, expected.eyes)).toBeLessThan(1e-5);
        expect(maxDifference(face.teeth, expected.teeth)).toBeLessThan(1e-5);
        expect(
          maxDifference(face.headNormals!, expected.headNormals),
        ).toBeLessThan(1e-4);
      });
    }
  }

  it("leaves every vertex on the protos head when every part is the protos head", () => {
    const decoded = library(
      (fixtures as unknown as Record<string, Fixture>).male,
    );

    expect(Array.from(blendFace(decoded, PROTOS_WEIGHTS).head)).toEqual(
      Array.from(decoded.meshes.head.base),
    );
  });
});

describe("undelta", () => {
  it("adds each row up with int8 wrap-around, row by row", () => {
    expect(
      Array.from(undelta(Int8Array.from([100, 100, -50, 1, 1, 1]), 3)),
    ).toEqual([100, -56, -106, 1, 2, 3]);
  });
});
