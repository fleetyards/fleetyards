<template>
  <div
    class="panel-shadow"
    :class="{
      'panel-shadow-top': alignment === 'top',
      'panel-shadow-bottom': alignment === 'bottom',
      'panel-shadow-left': alignment === 'left',
      'panel-shadow-right': alignment === 'right',
    }"
  />
</template>

<script lang="ts" setup>
type Props = {
  alignment: "top" | "bottom" | "left" | "right";
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
