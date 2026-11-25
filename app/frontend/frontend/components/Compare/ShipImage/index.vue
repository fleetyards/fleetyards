<script lang="ts">
export default {
  name: "CompareShipImage",
};
</script>

<script lang="ts" setup>
type Props = {
  src: string;
  label: string;
  maxWidth: string;
};

defineProps<Props>();
</script>

<template>
  <img :src="src" :style="{ 'max-width': maxWidth }" :alt="label" />
</template>
