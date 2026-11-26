import {
  Bone,
  BufferAttribute,
  BufferGeometry,
  Group,
  Mesh,
  MeshStandardMaterial,
  Skeleton,
  SkinnedMesh,
} from "three";
import { describe, expect, it } from "vitest";
import { dressNeck, keepRestPose } from "./applyCharacter";

const geometryOf = (points: number[][]) => {
  const geometry = new BufferGeometry();
  geometry.setAttribute(
    "position",
    new BufferAttribute(new Float32Array(points.flat()), 3),
  );
  return geometry;
};

const meshOf = (name: string, points: number[][]) => {
  const mesh = new Mesh(geometryOf(points), new MeshStandardMaterial());
  mesh.name = name;
  return mesh;
};

// A head from the bottom of the neck at 1.50 to the crown at 1.80, a point
// in front and one behind at 1.50, 1.54, 1.60, 1.63, 1.70 and 1.80.
const head = () =>
  meshOf(
    "male_head",
    [1.5, 1.54, 1.6, 1.63, 1.7, 1.8].flatMap((y) => [
      [0, y, 0.1],
      [0, y, -0.1],
    ]),
  );

// Whether each height is drawn as the collar, in front and behind.
const collared = (mesh: Mesh) => {
  const dark = Array.from(
    mesh.geometry.getAttribute("collarDepth").array as Float32Array,
  ).map((depth) => depth < 0);
  return dark.flatMap((front, index) =>
    index % 2 ? [] : [[front, dark[index + 1]]],
  );
};

// The rim at 1.64 under the chin and 1.58 at the nape.
const RIM = [
  [0, 1.64, 0.15],
  [0, 1.9, 0.15],
  [0, 1.58, -0.15],
  [0, 1.9, -0.15],
];

const UP_TO_RIM = [
  [true, true],
  [true, true],
  [true, false],
  [true, false],
  [false, false],
  [false, false],
];

const NECK_BAND = [
  [true, true],
  [true, true],
  [false, false],
  [false, false],
  [false, false],
  [false, false],
];

describe("dressNeck", () => {
  it("draws the neck dark up to the helmet's rim, higher under the chin than at the nape", () => {
    const scene = new Group();
    const face = head();
    const helmet = meshOf("helmet", RIM);
    scene.add(face, helmet);

    dressNeck(scene, false, [helmet]);

    expect(collared(face)).toEqual(UP_TO_RIM);
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

    expect(collared(face)).toEqual(NECK_BAND);
  });

  it("leaves the face of a helmet open at the front", () => {
    const scene = new Group();
    const face = head();
    // Nothing in front below the brow at 1.75.
    const helmet = meshOf("helmet", [
      [0, 1.75, 0.15],
      [0, 1.9, 0.15],
      [0, 1.64, -0.15],
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

  it("measures a scaled figure in its own lengths", () => {
    const scene = new Group();
    scene.scale.setScalar(0.5);
    const face = head();
    const helmet = meshOf("helmet", RIM);
    scene.add(face, helmet);
    scene.updateMatrixWorld(true);

    dressNeck(scene, false, [helmet]);

    expect(collared(face)).toEqual(UP_TO_RIM);
  });

  it("measures a skinned helmet in its rest pose, however the clip holds it", () => {
    const scene = new Group();
    const face = head();
    const bone = new Bone();
    bone.name = "head";
    scene.add(bone);

    const geometry = geometryOf(RIM);
    geometry.setAttribute(
      "skinIndex",
      new BufferAttribute(new Uint16Array(RIM.length * 4), 4),
    );
    geometry.setAttribute(
      "skinWeight",
      new BufferAttribute(new Float32Array(RIM.flatMap(() => [1, 0, 0, 0])), 4),
    );
    const helmet = new SkinnedMesh(geometry, new MeshStandardMaterial());
    scene.add(face, helmet);
    scene.updateMatrixWorld(true);
    helmet.bind(new Skeleton([bone]));

    keepRestPose(scene);
    bone.position.y = 0.3;
    scene.updateMatrixWorld(true);

    dressNeck(scene, false, [helmet]);

    expect(collared(face)).toEqual(UP_TO_RIM);
    expect(bone.position.y).toBe(0.3);
  });

  it("leaves out a cape the helmet's mesh hangs from the spine", () => {
    const scene = new Group();
    const face = head();
    const spine = new Bone();
    spine.name = "Spine3";
    const headBone = new Bone();
    headBone.name = "Head";
    const mount = new Bone();
    mount.name = "HelmetMount1";
    const cape = new Bone();
    cape.name = "Cape";
    spine.add(headBone, cape);
    headBone.add(mount);
    scene.add(spine);

    const points = [...RIM, [0, 0.5, 0.2], [0, 0.5, -0.2]];
    const geometry = geometryOf(points);
    geometry.setAttribute(
      "skinIndex",
      new BufferAttribute(
        new Uint16Array(
          points.flatMap((_, index) => [index < RIM.length ? 0 : 1, 0, 0, 0]),
        ),
        4,
      ),
    );
    geometry.setAttribute(
      "skinWeight",
      new BufferAttribute(
        new Float32Array(points.flatMap(() => [1, 0, 0, 0])),
        4,
      ),
    );
    const helmet = new SkinnedMesh(geometry, new MeshStandardMaterial());
    scene.add(face, helmet);
    scene.updateMatrixWorld(true);
    helmet.bind(new Skeleton([mount, cape]));

    dressNeck(scene, false, [helmet]);

    expect(collared(face)).toEqual(UP_TO_RIM);
  });

  it("draws the whole head as the hood", () => {
    const scene = new Group();
    const face = head();
    scene.add(face);

    dressNeck(scene, true);

    expect(collared(face).flat().every(Boolean)).toBe(true);
  });

  it("dresses a copy of the head and gives the original back", () => {
    const scene = new Group();
    const face = head();
    const { geometry, material } = face;
    scene.add(face);

    const undress = dressNeck(scene, false);

    expect(face.geometry).not.toBe(geometry);
    expect(geometry.getAttribute("collarDepth")).toBeUndefined();

    undress();

    expect(face.geometry).toBe(geometry);
    expect(face.material).toBe(material);
  });
});
