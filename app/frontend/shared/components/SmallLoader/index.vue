<template>
  <transition name="fade">
    <span v-if="loading" class="small-loader" :class="alignment">
      <div class="rhombus" />
      <div class="rhombus" />
      <div class="rhombus" />
    </span>
  </transition>
</template>

<script lang="ts" setup>
export type SpinnerAlignment = "center" | "left" | "right";

type Props = {
  loading?: boolean;
  alignment?: SpinnerAlignment;
};

withDefaults(defineProps<Props>(), {
  loading: false,
  alignment: "center",
});
</script>

<script lang="ts">
export default {
  name: "SmallLoader",
};
</script>

<style lang="scss" scoped>
@import "./index.scss";
</style>
