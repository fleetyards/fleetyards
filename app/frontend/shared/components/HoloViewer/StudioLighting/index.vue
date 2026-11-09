<script lang="ts">
export default {
  name: "HoloViewerStudioLighting",
};
</script>

<script lang="ts" setup>
import { useTres } from "@tresjs/core";
import {
  EquirectangularReflectionMapping,
  PMREMGenerator,
  type Texture,
  type WebGLRenderer,
} from "three";
import { HDRLoader } from "three/examples/jsm/loaders/HDRLoader.js";

type Props = {
  // An equirectangular Radiance HDR in linear light units, laid out so the
  // figure faces into it at a rotation of 0.
  map: string;
  intensity: number;
};

const props = defineProps<Props>();

// The studio a character sheet is rendered in: a grey world with fill and rim
// lights baked into an environment map, the key light coming from the rig.
const { scene, renderer, invalidate } = useTres();

let environment: Texture | undefined;
let request = 0;

const load = async () => {
  const current = ++request;
  try {
    const hdr = await new HDRLoader().loadAsync(props.map);
    hdr.mapping = EquirectangularReflectionMapping;
    const generator = new PMREMGenerator(renderer as WebGLRenderer);
    const next = generator.fromEquirectangular(hdr).texture;
    generator.dispose();
    hdr.dispose();

    if (current !== request) {
      next.dispose();
      return;
    }

    environment?.dispose();
    environment = next;
    scene.value.environment = next;
    scene.value.environmentIntensity = props.intensity;
    invalidate();
  } catch (error) {
    console.warn("The studio environment did not load", error);
  }
};

watch(() => props.map, load, { immediate: true });

watch(
  () => props.intensity,
  (intensity) => {
    scene.value.environmentIntensity = intensity;
    invalidate();
  },
);

onBeforeUnmount(() => {
  request += 1;
  if (scene.value.environment === environment) scene.value.environment = null;
  scene.value.environmentIntensity = 1;
  environment?.dispose();
  invalidate();
});
</script>

<template>
  <slot />
</template>
