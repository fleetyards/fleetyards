import { Texture } from "three";
import { describe, expect, it } from "vitest";

import { buildSky, disposeSky, skyNoiseVoxels } from "./sky";

const SIZE = 64;

const voxel = (voxels: Uint8Array, x: number, y: number, z: number) =>
  voxels[x + y * SIZE + z * SIZE * SIZE];

describe("skyNoiseVoxels", () => {
  it("spreads around the middle of its range", () => {
    const voxels = skyNoiseVoxels();
    const mean = voxels.reduce((sum, value) => sum + value, 0) / voxels.length;

    expect(voxels).toHaveLength(SIZE ** 3);
    expect(mean).toBeGreaterThan(115);
    expect(mean).toBeLessThan(140);
    expect(Math.max(...voxels.subarray(0, 4096))).toBeGreaterThan(160);
    expect(Math.min(...voxels.subarray(0, 4096))).toBeLessThan(95);
  });

  it("tiles without a step at its edges", () => {
    const voxels = skyNoiseVoxels();
    let inner = 0;
    let wrapped = 0;

    for (let z = 0; z < SIZE; z += 1) {
      for (let y = 0; y < SIZE; y += 1) {
        inner += Math.abs(voxel(voxels, 31, y, z) - voxel(voxels, 32, y, z));
        wrapped += Math.abs(
          voxel(voxels, SIZE - 1, y, z) - voxel(voxels, 0, y, z),
        );
      }
    }

    expect(wrapped).toBeLessThan(inner * 1.5);
  });
});

describe("buildSky", () => {
  it("sits behind everything and out of picking", () => {
    const panorama = new Texture();
    const sky = buildSky(panorama);

    expect(sky.material.uniforms.panorama.value).toBe(panorama);
    expect(sky.material.depthTest).toBe(false);
    expect(sky.material.depthWrite).toBe(false);
    expect(sky.material.toneMapped).toBe(false);
    expect(sky.frustumCulled).toBe(false);
    expect(sky.renderOrder).toBeLessThan(0);

    const hits: unknown[] = [];
    sky.raycast({} as never, hits as never);
    expect(hits).toHaveLength(0);

    disposeSky(sky);
  });
});
