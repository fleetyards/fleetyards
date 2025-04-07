<script lang="ts">
export default {
  name: "BasePanelBody",
};
</script>

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

<template>
  <div
    class="panel-body"
    :class="{
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

<style lang="scss" scoped>
@import "index";
</style>
