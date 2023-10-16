<template>
  <div
    class="panel-heading"
    :class="{
      'panel-heading-top': shadow === 'top',
      'panel-heading-bottom': shadow === 'bottom',
    }"
  >
    <component
      :is="level"
      class="panel-heading-title"
      :class="{
        'panel-heading-title-large': size === 'large',
      }"
    >
      <span class="panel-heading-title-main">
        <slot name="default" />
      </span>

      <small class="panel-heading-title-sub">
        <slot name="subtitle" />
      </small>
    </component>
    <slot name="actions" />
  </div>
</template>

<script lang="ts" setup>
type Props = {
  level?: "h1" | "h2" | "h3" | "h4" | "h5" | "h6";
  shadow?: "top" | "bottom";
  size?: "default" | "large";
};

withDefaults(defineProps<Props>(), {
  level: "h2",
  shadow: undefined,
  size: "default",
});
</script>

<script lang="ts">
export default {
  name: "PanelHeading",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
