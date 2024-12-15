<script lang="ts">
export default {
  name: "HardpointQuantity",
};
</script>

<script lang="ts" setup>
type Props = {
  quantity: number | string;
  tag?: "span" | "div";
};

withDefaults(defineProps<Props>(), {
  tag: "div",
});
</script>

<template>
  <component :is="tag" class="hardpoint-quantity"> {{ quantity }}x </component>
</template>

<style lang="scss" scoped>
@import "index";
</style>
