<template>
  <div
    class="panel-body"
    :class="{
      'panel-body-no-min-height': noMinHeight,
      'panel-body-no-padding': noPadding,
      'panel-body-no-padding-top': noPaddingTop,
      'panel-body-rounded': rounded === 'all',
      'panel-body-rounded-top': rounded === 'top',
      'panel-body-rounded-right': rounded === 'right',
      'panel-body-rounded-bottom': rounded === 'bottom',
      'panel-body-rounded-left': rounded === 'left',
    }"
  >
    <slot />
  </div>
</template>

<script lang="ts" setup>
type PanelImageRounded = "all" | "top" | "right" | "bottom" | "left";

type Props = {
  noMinHeight?: boolean;
  noPadding?: boolean;
  noPaddingTop?: boolean;
  rounded?: PanelImageRounded;
};

withDefaults(defineProps<Props>(), {
  noMinHeight: false,
  noPadding: false,
  noPaddingTop: false,
  rounded: undefined,
});
</script>

<script lang="ts">
export default {
  name: "PanelBody",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
