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
  SRGBColorSpace,
  type Texture,
  TextureLoader,
} from "three";

type Props = {
  // An equirectangular panorama.
  src: string;
};

const props = defineProps<Props>();

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
    sky = buildSky(loaded);
    scene.value.add(sky);
    invalidate();
  },
  { immediate: true },
);

onBeforeUnmount(() => {
  unmounted = true;
  release();
});
</script>

<template>
  <slot />
</template>
