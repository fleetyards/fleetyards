import { describe, expect, it } from "vitest";
import { type HoloMount, mountsSize, mountsTextured } from "./mounts";

const part = (overrides: Partial<HoloMount> = {}): HoloMount => ({
  position: [0, 0, 0],
  rotation: [0, 0, 0, 1],
  mounts: [],
  ...overrides,
});

describe("mountsTextured", () => {
  it("finds a painted part however deep it is mounted", () => {
    expect(mountsTextured([part({ mounts: [part({ textured: true })] })])).toBe(
      true,
    );
  });

  it("is false for clay parts and for none", () => {
    expect(mountsTextured([part(), part()])).toBe(false);
    expect(mountsTextured()).toBe(false);
  });
});

describe("mountsSize", () => {
  it("adds up every part's known size, nested ones included", () => {
    expect(
      mountsSize([
        part({ size: 3, mounts: [part({ size: 2 }), part()] }),
        part({ size: 5 }),
      ]),
    ).toBe(10);
  });
});
