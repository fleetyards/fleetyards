<script lang="ts">
export default {
  name: "HardpointSize",
};
</script>

<script lang="ts" setup>
type Props = {
  size?: number;
};

withDefaults(defineProps<Props>(), {
  size: undefined,
});
</script>

<template>
  <div v-if="size" class="hardpoint-item__size">S{{ size }}</div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
