import { describe, expect, it } from "vitest";
import type { Mesh, MeshBasicMaterial } from "three";
import { applyBoxHighlights, buildBoxes, type HoloBox } from "./boxes";

const box = (overrides: Partial<HoloBox> = {}): HoloBox => ({
  id: "bay",
  position: [1, 2, 3],
  rotation: [0, 0, 0, 1],
  size: [12, 12, 14],
  ...overrides,
});

const opacity = (node: unknown) =>
  ((node as Mesh).material as MeshBasicMaterial).opacity;

describe("buildBoxes", () => {
  it("places each box at its centre with its size, drawn through the hull", () => {
    const root = buildBoxes([box()]);
    const fill = root.children[0] as Mesh;

    expect(fill.position.toArray()).toEqual([1, 2, 3]);
    expect(
      (fill.geometry as unknown as { parameters: object }).parameters,
    ).toMatchObject({ width: 12, height: 12, depth: 14 });
    expect((fill.material as MeshBasicMaterial).depthTest).toBe(false);
  });

  it("brightens the highlighted box and dims it again", () => {
    const root = buildBoxes([box(), box({ id: "deck" })]);
    const plain = opacity(root.children[0]);

    applyBoxHighlights(root, [box({ highlighted: true }), box({ id: "deck" })]);

    expect(opacity(root.children[0])).toBeGreaterThan(plain);
    expect(opacity(root.children[1])).toBe(plain);

    applyBoxHighlights(root, [box(), box({ id: "deck" })]);

    expect(opacity(root.children[0])).toBe(plain);
  });
});
