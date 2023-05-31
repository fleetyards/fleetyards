<template>
  <img
    v-if="src"
    :src="src"
    :style="{
      width: `${width}px`,
      'max-height': height ? `${height}px` : undefined,
    }"
    :alt="label"
    class="fleetchart-item-image"
  />
  <span v-else>
    <i class="fal fa-question-circle" />
    <p>{{ label }}</p>
  </span>
</template>

<script lang="ts" setup>
import { v4 as uuidv4 } from "uuid";

type Props = {
  src: string;
  label: string;
  width: number;
  height?: number;
};

withDefaults(defineProps<Props>(), {
  height: undefined,
});

const uuid = uuidv4();
</script>

<script lang="ts">
export default {
  name: "FleetchartListItemImage",
};
</script>
