import { describe, expect, it } from "vitest";
import {
  Bone,
  BoxGeometry,
  Group,
  Mesh,
  MeshBasicMaterial,
  Vector3,
} from "three";
import { portraitCamera, portraitFocus } from "./portrait";

describe("portraitFocus", () => {
  it("looks at the head bone of a rigged figure", () => {
    const root = new Group();
    const spine = new Bone();
    spine.name = "Spine";
    spine.position.set(0, 1.2, 0);
    const head = new Bone();
    head.name = "Head";
    head.position.set(0, 0.45, 0.02);
    spine.add(head);
    root.add(spine);

    const focus = portraitFocus(root);

    expect(focus.y).toBeCloseTo(1.65);
    expect(focus.z).toBeCloseTo(0.02);
  });

  it("falls back to just under the top of what is drawn", () => {
    const root = new Group();
    const figure = new Mesh(
      new BoxGeometry(0.5, 2, 0.3),
      new MeshBasicMaterial(),
    );
    figure.position.set(0, 1, 0);
    root.add(figure);

    const focus = portraitFocus(root);

    expect(focus.y).toBeCloseTo(2 - 2 * 0.07);
    expect(focus.x).toBeCloseTo(0);
  });
});

describe("portraitCamera", () => {
  const head = new Vector3(0, 1.65, 0);

  it("stands in front of the figure from the given side, level with the shoulders", () => {
    const camera = portraitCamera(head, 1, 180, 0);

    expect(camera.position.z).toBeLessThan(0);
    expect(camera.position.x).toBeCloseTo(0);
    expect(camera.position.y).toBeLessThan(head.y);
  });

  it("widens its view on a tall canvas, so the square cut from it still holds the portrait", () => {
    const square = portraitCamera(head, 1);
    const tall = portraitCamera(head, 0.5);
    const wide = portraitCamera(head, 2);

    expect(tall.fov).toBeGreaterThan(square.fov);
    expect(wide.fov).toBeCloseTo(square.fov);
  });
});
