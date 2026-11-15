import { describe, expect, it } from "vitest";
import { type Material, type Mesh } from "three";
import { buildCargo, disposeCargo, revealCargo } from "./cargo";

const grid = {
  id: "hardpoint_cargogrid_module_04",
  position: [1, 2, 3],
  rotation: [0, 0, 0, 1],
  // 4 cells across, 4 up, 6 deep.
  size: [5, 5, 7.5],
};

const containers = (root: ReturnType<typeof buildCargo>) =>
  root.children[0].children.filter((child) => child.userData.containerSize);

describe("buildCargo", () => {
  it("fills each grid with containers in its own frame", () => {
    const root = buildCargo([grid]);

    expect(root.children[0].position.toArray()).toEqual([1, 2, 3]);
    expect(
      containers(root).reduce(
        (sum, container) => sum + container.userData.containerSize,
        0,
      ),
    ).toBe(96);
  });

  it("keeps every container inside its grid", () => {
    const root = buildCargo([grid]);

    for (const container of containers(root)) {
      const { x, y, z } = container.position;
      expect(Math.abs(x)).toBeLessThan(2.5);
      expect(Math.abs(y)).toBeLessThan(2.5);
      expect(Math.abs(z)).toBeLessThan(3.75);
    }
  });

  it("stands containers up the grid's own up axis", () => {
    // Two cells high: no 32 SCU crate lies on its side to fit.
    const root = buildCargo([{ ...grid, size: [10, 2.5, 2.5] }]);

    expect(containers(root).map((each) => each.userData.containerSize)).toEqual(
      [32],
    );
  });

  it("fades and grows in from nothing", () => {
    const root = buildCargo([grid]);
    const material = (containers(root)[0] as Mesh).material as Material;

    revealCargo(root, 0);
    expect(root.visible).toBe(false);
    expect(material.opacity).toBe(0);

    revealCargo(root, 1);
    expect(root.visible).toBe(true);
    expect(material.opacity).toBeCloseTo(0.32);
    expect(root.children[0].scale.x).toBe(1);

    disposeCargo(root);
  });
});
