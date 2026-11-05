import {
  Group,
  Mesh,
  MeshStandardMaterial,
  NoColorSpace,
  RepeatWrapping,
  SRGBColorSpace,
  Texture,
} from "three";
import { describe, expect, it } from "vitest";
import { applyStencilMap, BODY_SUFFIX, partMaterials } from "./paintMaps";

const part = (name: string, material: MeshStandardMaterial) => {
  const mesh = new Mesh(undefined, material);
  mesh.name = name;
  return mesh;
};

const holo = (stencilMap: Texture | null = new Texture()) => {
  const scene = new Group();
  const body = new MeshStandardMaterial({ map: new Texture() });
  const stencil = new MeshStandardMaterial({ map: stencilMap });
  scene.add(part("DRAK_Corsair_body", body));
  scene.add(part("DRAK_Corsair_stencil", stencil));
  return { scene, body, stencil, own: stencilMap };
};

describe("partMaterials", () => {
  it("finds the meshes a part with several materials loads as", () => {
    const scene = new Group();
    const node = new Group();
    node.name = "DRAK_Corsair_body";
    const first = new MeshStandardMaterial();
    const second = new MeshStandardMaterial();
    node.add(part("DRAK_Corsair_body001", first));
    node.add(part("DRAK_Corsair_body001_1", second));
    scene.add(node);

    expect(partMaterials(scene, BODY_SUFFIX)).toEqual([first, second]);
  });
});

describe("applyStencilMap", () => {
  it("draws a paint's sheet on the stencil and leaves the body alone", () => {
    const { scene, body, stencil } = holo();
    const bodyMap = body.map;
    const sheet = new Texture();

    applyStencilMap(scene, sheet);

    expect(stencil.map).toBe(sheet);
    expect(body.map).toBe(bodyMap);
  });

  it("writes the sheet like the export's own map", () => {
    const own = new Texture();
    own.wrapS = RepeatWrapping;
    own.wrapT = RepeatWrapping;
    own.anisotropy = 8;
    const { scene } = holo(own);
    const sheet = new Texture();
    sheet.colorSpace = NoColorSpace;

    applyStencilMap(scene, sheet);

    expect(sheet.colorSpace).toBe(SRGBColorSpace);
    expect(sheet.flipY).toBe(false);
    expect(sheet.wrapS).toBe(RepeatWrapping);
    expect(sheet.wrapT).toBe(RepeatWrapping);
    expect(sheet.anisotropy).toBe(8);
  });

  it("goes back to the export's own sheet after switching between paints", () => {
    const { scene, stencil, own } = holo();

    applyStencilMap(scene, new Texture());
    applyStencilMap(scene, new Texture());
    applyStencilMap(scene);

    expect(stencil.map).toBe(own);
  });

  it("keeps the export's own sheet for a paint without one", () => {
    const { scene, stencil, own } = holo();

    applyStencilMap(scene);

    expect(stencil.map).toBe(own);
  });

  it("does nothing to an export without a stencil", () => {
    const scene = new Group();
    const body = new MeshStandardMaterial({ map: new Texture() });
    const bodyMap = body.map;
    scene.add(part("DRAK_Golem_body", body));

    expect(() => applyStencilMap(scene, new Texture())).not.toThrow();
    expect(body.map).toBe(bodyMap);
  });
});
