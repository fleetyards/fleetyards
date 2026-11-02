import { describe, expect, it } from "vitest";
import {
  Bone,
  BufferGeometry,
  Group,
  MeshBasicMaterial,
  Skeleton,
  SkinnedMesh,
} from "three";
import { bindToBones } from "./rig";

const BACKPACK_BONE = "backpack_attach_1_override";

const bone = (name: string, z = 0) => {
  const node = new Bone();
  node.name = name;
  node.position.z = z;
  return node;
};

// A worn piece skinned to its own copy of the spine, with a backpack bone
// standing out from it by `backpackAt`.
const piece = (name: string, backpackAt: number) => {
  const spine = bone("Spine3");
  const backpack = bone(BACKPACK_BONE, backpackAt);
  spine.add(backpack);

  const mesh = new SkinnedMesh(new BufferGeometry(), new MeshBasicMaterial());
  mesh.bind(new Skeleton([spine, backpack]));

  const root = new Group();
  root.name = name;
  root.add(spine, mesh);
  return root;
};

const body = () => {
  const spine = bone("Spine3");
  return new Map([[spine.name, spine]]);
};

const backpackBone = (mesh: SkinnedMesh) =>
  mesh.skeleton.bones.find((candidate) => candidate.name === BACKPACK_BONE);

describe("bindToBones", () => {
  it("hangs a backpack from the core over the undersuit", () => {
    const bones = body();
    bindToBones(piece("undersuit", 0.1), bones);
    bindToBones(piece("core", 0.2), bones);

    const { meshes } = bindToBones(piece("backpack", 0), bones, {
      hangs: true,
    });

    expect(backpackBone(meshes[0])?.position.z).toBe(0.2);
  });

  it("leaves a backpack off a core whose rig lacks the mount", () => {
    const bones = body();
    bindToBones(piece("undersuit", 0.1), bones, { source: "undersuit" });
    const core = piece("core", 0);
    core.traverse((node) => {
      if (node.name === BACKPACK_BONE) node.removeFromParent();
    });
    bindToBones(core, bones, { source: "core" });

    const { meshes } = bindToBones(piece("backpack", 0), bones, {
      hangs: true,
      from: "core",
    });

    expect(meshes).toHaveLength(0);
  });

  it("hangs a backpack from the core it names", () => {
    const bones = body();
    bindToBones(piece("undersuit", 0.1), bones, { source: "undersuit" });
    bindToBones(piece("core", 0.2), bones, { source: "core" });

    const { meshes } = bindToBones(piece("backpack", 0), bones, {
      hangs: true,
      from: "core",
    });

    expect(backpackBone(meshes[0])?.position.z).toBe(0.2);
  });

  it("gives a piece that does not hang its own copy of a mount", () => {
    const bones = body();
    bindToBones(piece("undersuit", 0.1), bones);

    const { meshes } = bindToBones(piece("core", 0.2), bones);

    expect(backpackBone(meshes[0])?.position.z).toBe(0.2);
    expect(bones.get(BACKPACK_BONE)?.position.z).toBe(0.2);
  });
});
