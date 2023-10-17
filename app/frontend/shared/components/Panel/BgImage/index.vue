<template>
  <div
    :key="image"
    v-lazy:background-image="image"
    class="panel-bg lazy"
    :class="{
      'panel-bg-rounded': rounded === 'all',
      'panel-bg-rounded-left': rounded === 'left',
      'panel-bg-rounded-right': rounded === 'right',
      'panel-bg-rounded-top': rounded === 'top',
      'panel-bg-rounded-bottom': rounded === 'bottom',
      'panel-bg-align-left': alignment === 'left',
      'panel-bg-align-right': alignment === 'right',
    }"
  />
</template>

<script lang="ts" setup>
type Props = {
  image: string;
  alignment?: "left" | "right";
  rounded?: "all" | "left" | "right" | "top" | "bottom";
};

withDefaults(defineProps<Props>(), {
  alignment: undefined,
  rounded: "all",
});
</script>

<script lang="ts">
export default {
  name: "PanelBgImage",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
