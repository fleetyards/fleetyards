<template>
  <div
    :class="{
      'panel-outer-spacing': outerSpacing,
      'panel-highlight': highlight,
    }"
    class="panel-wrapper"
  >
    <div
      :class="{
        [variantClass]: true,
        [transparencyClass]: true,
      }"
      class="panel"
    >
      <div
        :class="{
          'panel-inner-text': inset,
          'panel-inner-left': align === 'left',
          'panel-inner-right': align === 'right',
        }"
        class="panel-inner"
      >
        <slot />
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
type Props = {
  outerSpacing?: boolean;
  transparency?: "default" | "more" | "complete";
  highlight?: boolean;
  variant?: "default" | "primary" | "success";
  align?: "left" | "right";
  inset?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  outerSpacing: true,
  transparency: "default",
  highlight: false,
  inset: false,
  align: undefined,
  variant: "default",
});

const variantClass = computed(() => `panel-${props.variant}`);

const transparencyClass = computed(
  () => `panel-transparency-${props.transparency}`,
);
</script>

<script lang="ts">
export default {
  name: "BasePanel",
};
</script>

<style lang="scss" scoped>
@import "./index.scss";
</style>
