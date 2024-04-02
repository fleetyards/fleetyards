<template>
  <div
    class="panel-heading"
    :class="{
      'panel-heading-top': shadow === 'top',
      'panel-heading-bottom': shadow === 'bottom',
      'panel-heading-with-actions': slots.actions,
    }"
  >
    <component
      :is="level"
      class="panel-heading-title"
      :class="{
        'panel-heading-title-singleline': !multiline,
        'panel-heading-title-title-large': size === 'large',
        'panel-heading-title-align-left': titleAlign === 'left',
        'panel-heading-title-align-center': titleAlign === 'center',
        'panel-heading-title-align-right': titleAlign === 'right',
        'panel-heading-title-align-justify': titleAlign === 'justify',
      }"
    >
      <span class="panel-heading-title-main">
        <slot name="default" />
      </span>

      <small class="panel-heading-title-sub">
        <slot name="subtitle" />
      </small>
    </component>
    <div class="panel-heading-actions">
      <slot name="actions" />
    </div>
  </div>
</template>

<script lang="ts" setup>
type Props = {
  level?: "h1" | "h2" | "h3" | "h4" | "h5" | "h6";
  shadow?: "top" | "bottom";
  size?: "default" | "large";
  titleAlign?: "left" | "center" | "right" | "justify";
  multiline?: boolean;
};

withDefaults(defineProps<Props>(), {
  level: "h2",
  shadow: undefined,
  size: "default",
  titleAlign: "left",
  multiline: false,
});

const slots = defineSlots();
</script>

<script lang="ts">
export default {
  name: "PanelHeading",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
