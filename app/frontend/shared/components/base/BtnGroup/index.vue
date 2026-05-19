<script lang="ts">
export default {
  name: "BaseBtnGroup",
};
</script>

<script lang="ts" setup>
type Props = {
  inline?: boolean;
  flush?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  inline: false,
  flush: false,
});

const cssClasses = computed(() => {
  return {
    "panel-btn-group": true,
    "panel-btn-group-inline": props.inline,
    "panel-btn-group-flush": props.flush,
  };
});
</script>

<template>
  <div :class="cssClasses">
    <slot />
  </div>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
