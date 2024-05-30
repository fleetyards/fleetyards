<template>
  <img
    v-if="src"
    :src="src"
    :style="{
      height: `${length * lengthMultiplicator}px`,
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
type Props = {
  src: string;
  label: string;
  length: number;
  scale: number;
};

const props = defineProps<Props>();

const lengthMultiplicator = computed(() => (props.scale / 100) * 4);
</script>

<script lang="ts">
export default {
  name: "FleetchartListItemImage",
};
</script>
