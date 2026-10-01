<script lang="ts">
export default {
  name: "LoadingLine",
};
</script>

<script lang="ts" setup>
import { useLoadingAnnouncement } from "@/shared/composables/useLoadingAnnouncement";

type Props = {
  loading?: boolean;
  // What a screen reader announces while the load runs. The line itself is
  // decoration, so this is the only way the state reaches assistive tech.
  label?: string;
  // The edge of the positioned parent the line runs along.
  edge?: "top" | "bottom";
};

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  label: undefined,
  edge: "top",
});

const statusText = useLoadingAnnouncement(
  () => props.loading,
  () => props.label,
);
</script>

<!-- The motion a still skeleton deliberately lacks, scoped to the one area
     that is waiting rather than the app-wide fetch bar at the window's top.
     A span, so it can sit in a paragraph or a button. -->
<template>
  <span
    class="loading-line"
    :class="[`loading-line--${edge}`, { 'loading-line--active': loading }]"
    data-test="loading-line"
  >
    <span class="sr-only" role="status">{{ statusText }}</span>
  </span>
</template>

<style lang="scss" scoped>
@import "index";
</style>
