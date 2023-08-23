<template>
  <div
    class="panel-image"
    :class="{
      'panel-image-details': details,
    }"
  >
    <slot />
  </div>
</template>

<script lang="ts" setup>
type Props = {
  details?: boolean;
};

withDefaults(defineProps<Props>(), {
  details: false,
});
</script>

<script lang="ts">
export default {
  name: "BasePanel",
};
</script>

<style lang="scss" scoped>
@import "./index.scss";
</style>
