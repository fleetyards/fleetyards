import { describe, expect, it } from "vitest";
import { BoxGeometry, Group, Mesh } from "three";
import { markBuiltIns, paintBuiltIns, unmarkBuiltIns } from "./builtIns";

const hull = () => {
  const scene = new Group();

  const laser = new Group();
  laser.name = "hardpoint_mining_laser";
  laser.userData = { kind: "item", port: "hardpoint_mining_laser" };
  laser.add(new Mesh(new BoxGeometry(1, 1, 1)));

  // The loader makes a repeated node name unique.
  const relays = ["hardpoint_relay_cockpit", "hardpoint_relay_cockpit_1"].map(
    (name) => {
      const relay = new Group();
      relay.name = name;
      relay.userData = { kind: "item", port: "hardpoint_relay_cockpit" };
      relay.add(new Mesh(new BoxGeometry(1, 1, 1)));
      return relay;
    },
  );

  scene.add(laser, ...relays);

  return scene;
};

describe("built-in items", () => {
  it("marks the meshes of the items asked for alone", () => {
    const marks = markBuiltIns(hull(), [
      { id: "hardpoint_mining_laser", node: "hardpoint_mining_laser" },
    ]);

    expect(marks.map((mark) => mark.userData.builtInId)).toEqual([
      "hardpoint_mining_laser",
    ]);
  });

  it("marks every node of a repeated name", () => {
    const marks = markBuiltIns(hull(), [
      { id: "hardpoint_relay_cockpit", node: "hardpoint_relay_cockpit" },
    ]);

    expect(marks).toHaveLength(2);
  });

  it("fades the marks in, brighter where pointed at", () => {
    const marks = markBuiltIns(hull(), [
      { id: "hardpoint_mining_laser", node: "hardpoint_mining_laser" },
      { id: "hardpoint_relay_cockpit", node: "hardpoint_relay_cockpit" },
    ]);

    paintBuiltIns(marks, 0);
    expect(marks.every((mark) => !mark.visible)).toBe(true);

    paintBuiltIns(marks, 1, "hardpoint_mining_laser");
    const [laser, relay] = marks;
    expect(laser.material.opacity).toBeGreaterThan(relay.material.opacity);

    unmarkBuiltIns(marks);
    expect(marks.every((mark) => !mark.parent)).toBe(true);
  });
});
