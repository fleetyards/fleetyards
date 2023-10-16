<template>
  <div
    class="panel-shadow"
    :class="{
      'panel-shadow-left': alignment === 'left',
      'panel-shadow-right': alignment === 'right',
    }"
  />
</template>

<script lang="ts" setup>
type Props = {
  alignment: "left" | "right";
};

defineProps<Props>();
</script>

<script lang="ts">
export default {
  name: "PanelShadow",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
