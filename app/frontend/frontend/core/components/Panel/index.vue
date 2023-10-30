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
          'panel-inner-text': forText,
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
  forText?: boolean;
  variant?: "default" | "primary" | "success";
};

const props = withDefaults(defineProps<Props>(), {
  outerSpacing: true,
  transparency: "default",
  highlight: false,
  forText: false,
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
