<script lang="ts">
export default {
  name: "HoloViewerSkybox",
};
</script>

<script lang="ts" setup>
import { useTres } from "@tresjs/core";
import {
  EquirectangularReflectionMapping,
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

let texture: Texture | undefined;
let unmounted = false;

const release = () => {
  if (texture && scene.value.background === texture) {
    scene.value.background = null;
  }
  texture?.dispose();
  texture = undefined;
  invalidate();
};

watch(
  () => props.src,
  async (src) => {
    const loaded = await new TextureLoader()
      .loadAsync(src)
      .catch(() => undefined);

    // Switched again, or closed, while this one was still loading.
    if (!loaded || src !== props.src || unmounted) {
      loaded?.dispose();
      return;
    }

    loaded.mapping = EquirectangularReflectionMapping;
    loaded.colorSpace = SRGBColorSpace;

    release();
    texture = loaded;
    scene.value.background = loaded;
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
