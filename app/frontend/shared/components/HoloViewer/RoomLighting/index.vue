<script lang="ts">
export default {
  name: "HoloViewerRoomLighting",
};
</script>

<script lang="ts" setup>
import { useTres } from "@tresjs/core";
import { PMREMGenerator, type WebGLRenderer } from "three";
import { RoomEnvironment } from "three/examples/jsm/environments/RoomEnvironment.js";

// Light from every side for a textured holo: a lone lamp and a flat ambient
// sink a dark paint to black, where the game shows its colour.
const { scene, renderer, invalidate } = useTres();

const room = new RoomEnvironment();
const generator = new PMREMGenerator(renderer as WebGLRenderer);
const environment = generator.fromScene(room, 0.04).texture;
generator.dispose();
room.dispose();

scene.value.environment = environment;
invalidate();

onBeforeUnmount(() => {
  if (scene.value.environment === environment) scene.value.environment = null;
  environment.dispose();
  invalidate();
});
</script>

<template>
  <slot />
</template>
