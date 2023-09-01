<template>
  <div :class="cssClasses">
    <slot />
  </div>
</template>

<script lang="ts" setup>
type Props = {
  inline?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  inline: false,
});

const cssClasses = computed(() => {
  return {
    "panel-btn-group": true,
    "panel-btn-group-inline": props.inline,
  };
});
</script>

<script lang="ts">
export default {
  name: "BaseBtnGroup",
};
</script>

<style lang="scss" scoped>
@import "./index.scss";
</style>
