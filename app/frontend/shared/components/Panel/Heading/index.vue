<template>
  <div class="panel-heading">
    <component :is="level" class="panel-title">
      <slot />
    </component>
  </div>
</template>

<script lang="ts" setup>
type Props = {
  level?: "h1" | "h2" | "h3" | "h4" | "h5" | "h6";
};

withDefaults(defineProps<Props>(), {
  level: "h2",
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
