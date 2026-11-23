import {
  BufferAttribute,
  BufferGeometry,
  Group,
  Mesh,
  MeshStandardMaterial,
} from "three";
import { describe, expect, it } from "vitest";
import { dressNeck } from "./applyCharacter";

const meshOf = (name: string, points: number[][]) => {
  const geometry = new BufferGeometry();
  geometry.setAttribute(
    "position",
    new BufferAttribute(new Float32Array(points.flat()), 3),
  );
  const mesh = new Mesh(geometry, new MeshStandardMaterial());
  mesh.name = name;
  return mesh;
};

// A head from the bottom of the neck at 1.50 to the crown at 1.80, a point
// in front and one behind at 1.50, 1.54, 1.60, 1.65, 1.70 and 1.80.
const head = () =>
  meshOf(
    "male_head",
    [1.5, 1.54, 1.6, 1.65, 1.7, 1.8].flatMap((y) => [
      [0, y, 0.1],
      [0, y, -0.1],
    ]),
  );

const depths = (mesh: Mesh) =>
  Array.from(mesh.geometry.getAttribute("collarDepth").array as Float32Array);

// Whether each height is drawn as the collar, in front and behind.
const collared = (mesh: Mesh) => {
  const dark = depths(mesh).map((depth) => depth < 0);
  return dark.flatMap((front, index) =>
    index % 2 ? [] : [[front, dark[index + 1]]],
  );
};

describe("dressNeck", () => {
  it("draws the neck dark up to the helmet's rim, lower at the chin than at the nape", () => {
    const scene = new Group();
    const face = head();
    // The rim at 1.58 in front and 1.68 behind.
    const helmet = meshOf("helmet", [
      [0, 1.58, 0.15],
      [0, 1.9, 0.15],
      [0, 1.68, -0.15],
      [0, 1.9, -0.15],
    ]);
    scene.add(face, helmet);

    dressNeck(scene, false, [helmet]);

    expect(collared(face)).toEqual([
      [true, true],
      [true, true],
      [false, true],
      [false, true],
      [false, false],
      [false, false],
    ]);
  });

  it("keeps the neck band where the helmet sits lower than it", () => {
    const scene = new Group();
    const face = head();
    const helmet = meshOf("helmet", [
      [0, 1.4, 0.15],
      [0, 1.4, -0.15],
    ]);
    scene.add(face, helmet);

    dressNeck(scene, false, [helmet]);

    expect(collared(face)).toEqual([
      [true, true],
      [true, true],
      [false, false],
      [false, false],
      [false, false],
      [false, false],
    ]);
  });

  it("draws the whole head as the hood", () => {
    const scene = new Group();
    const face = head();
    scene.add(face);

    dressNeck(scene, true);

    expect(collared(face).flat().every(Boolean)).toBe(true);
  });

  it("gives the head back as it was", () => {
    const scene = new Group();
    const face = head();
    const material = face.material;
    scene.add(face);

    dressNeck(scene, false)();

    expect(face.material).toBe(material);
    expect(face.geometry.getAttribute("collarDepth")).toBeUndefined();
  });
});
