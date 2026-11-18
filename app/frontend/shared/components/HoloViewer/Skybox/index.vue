<script lang="ts">
export default {
  name: "HoloViewerSkybox",
};
</script>

<script lang="ts" setup>
import { useTres } from "@tresjs/core";
import { extrasLoadingManager } from "../gltfLoader";
import { buildSky, disposeSky } from "../sky";
import {
  RepeatWrapping,
  type ShaderMaterial,
  SRGBColorSpace,
  type Texture,
  TextureLoader,
} from "three";

type Props = {
  // An equirectangular panorama.
  src: string;
  // Below 1 where the sky is drawn over something, such as a star field.
  opacity?: number;
};

const props = withDefaults(defineProps<Props>(), { opacity: 1 });

const { scene, invalidate } = useTres();

let panorama: Texture | undefined;
let sky: ReturnType<typeof buildSky> | undefined;
let unmounted = false;

const release = () => {
  if (sky) {
    scene.value.remove(sky);
    disposeSky(sky);
  }
  panorama?.dispose();
  sky = undefined;
  panorama = undefined;
  invalidate();
};

watch(
  () => props.src,
  async (src) => {
    const loaded = await new TextureLoader(extrasLoadingManager)
      .loadAsync(src)
      .catch(() => undefined);

    // Switched again, or closed, while this one was still loading.
    if (!loaded || src !== props.src || unmounted) {
      loaded?.dispose();
      return;
    }

    loaded.wrapS = RepeatWrapping;
    loaded.colorSpace = SRGBColorSpace;

    release();
    panorama = loaded;
    sky = buildSky(loaded, props.opacity);
    scene.value.add(sky);
    invalidate();
  },
  { immediate: true },
);

// Faded in place: the starmap fades a system's sky out and in with the
// system. Only translucent below 1, since a translucent sky is drawn after the
// scene and would cover it.
watch(
  () => props.opacity,
  (opacity) => {
    if (!sky) return;
    const material = sky.material as ShaderMaterial;
    material.uniforms.opacity.value = opacity;
    if (material.transparent !== opacity < 1) {
      material.transparent = opacity < 1;
      material.needsUpdate = true;
    }
    invalidate();
  },
);

onBeforeUnmount(() => {
  unmounted = true;
  release();
});
</script>

<template>
  <slot />
</template>
