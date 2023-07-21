<template>
  <component
    :is="as"
    ref="element"
    class="collapsed"
    :style="{ height: visible ? `${height}px` : undefined }"
  >
    <slot />
  </component>
</template>

<script lang="ts" setup>
type Props = {
  visible?: boolean;
  as?: string;
};

withDefaults(defineProps<Props>(), {
  visible: false,
  as: "div",
});

const element = ref<HTMLElement | null>(null);

const height = computed(() => element.value?.scrollHeight);
</script>

<script lang="ts">
export default {
  name: "CollapsedComponent",
};
</script>

<style lang="scss" scoped>
.collapsed {
  overflow: hidden;
  transition: height $transition-base-speed ease;
  height: 0;
}
</style>
