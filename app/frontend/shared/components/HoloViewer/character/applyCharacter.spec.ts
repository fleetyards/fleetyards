import { BufferAttribute, BufferGeometry } from "three";
import { describe, expect, it } from "vitest";
import { strandChannel } from "./applyCharacter";

const geometry = (second?: number[]) => {
  const result = new BufferGeometry();
  result.setAttribute(
    "uv",
    new BufferAttribute(Float32Array.from([0, 0, 1, 1]), 2),
  );
  if (second)
    result.setAttribute(
      "uv1",
      new BufferAttribute(Float32Array.from(second), 2),
    );
  return result;
};

describe("strandChannel", () => {
  it("reads strand cards on the second UV set, where their atlas is", () => {
    expect(strandChannel(geometry([0.1, 0.2, 0.7, 0.6]))).toBe(1);
  });

  it("reads lashes and shaved or shadow layers on the first, their second set being a single point", () => {
    expect(strandChannel(geometry([0.99, 0.99, 0.99, 0.99]))).toBe(0);
    expect(strandChannel(geometry())).toBe(0);
  });
});
