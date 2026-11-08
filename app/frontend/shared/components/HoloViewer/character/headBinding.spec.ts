import { describe, expect, it } from "vitest";
import { faceOffsets, fitToFace, followFace } from "./headBinding";

describe("followFace", () => {
  it("moves each point by the weighted offsets of the head points it is bound to", () => {
    const offsets = Float32Array.from([0, 0, 0, 1, 0, 0, 0, 2, 0]);
    const moved = followFace(
      Float32Array.from([10, 10, 10]),
      [1, 2, 0, 0],
      [0.5, 0.25, 0.25, 0],
      offsets,
    );

    expect(Array.from(moved)).toEqual([10.5, 10.5, 10]);
  });
});

describe("faceOffsets", () => {
  it("is how far each head point moved from protos", () => {
    expect(
      Array.from(
        faceOffsets(Float32Array.from([1, 2, 3]), Float32Array.from([1, 1, 1])),
      ),
    ).toEqual([0, 1, 2]);
  });
});

describe("fitToFace", () => {
  // A brute-force bind of every point to its four nearest head points.
  const reference = (
    positions: Float32Array,
    protos: Float32Array,
    offsets: Float32Array,
  ) => {
    const out = new Float32Array(positions);
    for (let v = 0; v < positions.length / 3; v++) {
      const near = Array.from({ length: protos.length / 3 }, (_, i) => [
        Math.hypot(
          protos[i * 3] - positions[v * 3],
          protos[i * 3 + 1] - positions[v * 3 + 1],
          protos[i * 3 + 2] - positions[v * 3 + 2],
        ),
        i,
      ])
        .sort((a, b) => a[0] - b[0])
        .slice(0, 4);
      const weights = near.map(([d]) => 1 / Math.max(d, 0.0005) ** 2);
      const total = weights.reduce((sum, w) => sum + w, 0);
      near.forEach(([, i], k) => {
        for (let a = 0; a < 3; a++)
          out[v * 3 + a] += (weights[k] / total) * offsets[i * 3 + a];
      });
    }
    return out;
  };

  it("binds every point to its four nearest head points as a full search does", () => {
    let seed = 7;
    const random = () =>
      ((seed = (seed * 16807) % 2147483647) / 2147483647) * 0.3 - 0.15;
    const protos = Float32Array.from({ length: 300 * 3 }, random);
    const offsets = Float32Array.from(
      { length: 300 * 3 },
      () => random() * 0.01,
    );
    const positions = Float32Array.from(
      { length: 50 * 3 },
      () => random() * 1.5,
    );

    const fitted = fitToFace(positions, protos, offsets);
    const expected = reference(positions, protos, offsets);

    fitted.forEach((value, i) => expect(value).toBeCloseTo(expected[i], 7));
  });
});
