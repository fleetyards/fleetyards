import { describe, expect, it } from "vitest";
import { BoxGeometry, Group, Mesh, Quaternion, Vector3 } from "three";
import { bindDoors, buildDoorTargets, type HoloDoor, poseDoor } from "./doors";

// The Prospector's rear hatch: a door part hinged 130 degrees about x at its
// pivot, under a parent node that is itself offset in the hull.
const pivot = new Vector3(0.0125, -1.792, 11.3355);
const turn = new Quaternion(0.906302, 0, 0, 0.42263).normalize();
const shift = pivot.clone().sub(pivot.clone().applyQuaternion(turn));

const hatch: HoloDoor = {
  id: "hardpoint_door_rear",
  durationS: 3,
  bounds: {
    center: [0, -0.77, 10.73],
    axes: [
      [1, 0, 0],
      [0, 1, 0],
      [0, 0, 1],
    ],
    halfSize: [1.9, 1.5, 0.95],
  },
  parts: [
    {
      part: 1,
      object: "AuxBayDropUnitBottomDoor",
      keyframes: [
        { t: 0, translation: [0, 0, 0], rotation: [0, 0, 0, 1] },
        { t: 1, translation: shift.toArray(), rotation: turn.toArray() },
      ],
    },
  ],
};

const hull = () => {
  const scene = new Group();
  const parent = new Group();
  parent.name = "hardpoint_door_rear";
  parent.position.set(0, -4.3794, 0);

  const part = new Group();
  part.name = "door_hardpoint_door_rear_1";
  part.userData = { kind: "door", doorId: "hardpoint_door_rear", part: 1 };
  part.position.set(0.0125, 2.5874, 11.3355);
  part.add(new Mesh(new BoxGeometry(1, 1, 1)));

  parent.add(part);
  scene.add(parent);
  // Centred and scaled for the camera after loading: the doors move in the
  // export's own frame regardless.
  scene.position.set(3, 1, -2);
  scene.scale.setScalar(2);

  return { scene, part };
};

const inExportFrame = (scene: Group, part: Group) => {
  scene.updateMatrixWorld(true);

  return part
    .getWorldPosition(new Vector3())
    .applyMatrix4(scene.matrixWorld.clone().invert());
};

describe("doors", () => {
  it("finds a part by the extras the holo names it with", () => {
    const { scene, part } = hull();

    const [bound] = bindDoors(scene, [hatch]);

    expect(bound.parts[0].node).toBe(part);
  });

  it("falls back to the part's game-file name", () => {
    const { scene, part } = hull();
    part.userData = {};
    part.name = "AuxBayDropUnitBottomDoor";

    expect(bindDoors(scene, [hatch])[0].parts[0].node).toBe(part);
  });

  it("finds a part by its game-file name as the loader sanitises it", () => {
    const { scene, part } = hull();
    part.userData = {};
    part.name = "AuxBayDropUnitBottomDoor001";

    const [bound] = bindDoors(scene, [
      {
        ...hatch,
        parts: [{ ...hatch.parts[0], object: "AuxBayDropUnitBottomDoor.001" }],
      },
    ]);

    expect(bound.parts[0].node).toBe(part);
  });

  it("closes to where the holo had it, bound again while open", () => {
    const { scene, part } = hull();
    const closed = part.position.clone();

    poseDoor(bindDoors(scene, [hatch])[0], 1);
    const rebound = bindDoors(scene, [hatch])[0];
    poseDoor(rebound, 0);

    expect(part.position.distanceTo(closed)).toBeLessThan(1e-6);
  });

  it("shuts a door whose first keyframe is not where the holo has it", () => {
    const { scene, part } = hull();
    const closed = part.position.clone();
    const offset: HoloDoor = {
      ...hatch,
      parts: [
        {
          ...hatch.parts[0],
          keyframes: [
            { t: 0.2, translation: [0, 0.1, 0], rotation: [0, 0, 0, 1] },
            ...hatch.parts[0].keyframes.slice(1),
          ],
        },
      ],
    };

    const [bound] = bindDoors(scene, [offset]);
    poseDoor(bound, 0.6);
    poseDoor(bound, 0);

    expect(part.position.distanceTo(closed)).toBeLessThan(1e-6);
  });

  it("leaves out a door none of whose parts are in the holo", () => {
    const { scene } = hull();

    expect(
      bindDoors(scene, [
        {
          ...hatch,
          id: "missing",
          parts: [{ ...hatch.parts[0], object: "nowhere" }],
        },
      ]),
    ).toEqual([]);
  });

  it("swings a hinged part about its pivot in the export's frame", () => {
    const { scene, part } = hull();
    const [bound] = bindDoors(scene, [hatch]);

    poseDoor(bound, 1);

    // The pivot itself stays put while the part turns about it.
    expect(inExportFrame(scene, part).distanceTo(pivot)).toBeLessThan(1e-3);
    expect(part.quaternion.angleTo(turn)).toBeLessThan(1e-3);

    poseDoor(bound, 0);

    expect(inExportFrame(scene, part).distanceTo(pivot)).toBeLessThan(1e-3);
    expect(part.quaternion.angleTo(new Quaternion())).toBeLessThan(1e-6);
  });

  it("halfway open, is halfway round", () => {
    const { scene, part } = hull();
    const [bound] = bindDoors(scene, [hatch]);

    poseDoor(bound, 0.5);

    expect(part.quaternion.angleTo(new Quaternion())).toBeCloseTo(
      turn.angleTo(new Quaternion()) / 2,
      3,
    );
  });

  it("puts a click target round each closed door", () => {
    const targets = buildDoorTargets([
      hatch,
      { ...hatch, id: "nobox", bounds: null },
    ]);

    expect(targets.children).toHaveLength(1);
    expect(targets.children[0].userData.doorId).toBe("hardpoint_door_rear");
    expect(targets.children[0].position.toArray()).toEqual([0, -0.77, 10.73]);
  });
});
