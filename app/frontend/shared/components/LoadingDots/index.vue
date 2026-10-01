<script lang="ts">
export default {
  name: "LoadingDots",
};
</script>

<script lang="ts" setup>
import { useLoadingAnnouncement } from "@/shared/composables/useLoadingAnnouncement";

type Props = {
  loading?: boolean;
  // What a screen reader announces while it runs; the dots are decoration.
  label?: string;
};

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  label: undefined,
});

const statusText = useLoadingAnnouncement(
  () => props.loading,
  () => props.label,
);
</script>

<!-- Three dots after a line of text that is still in progress, for a step
     or a status rather than an area: an area waiting on content takes a
     skeleton and the loading line. -->
<template>
  <span class="loading-dots" data-test="loading-dots">
    <span v-if="loading" class="loading-dots__dots" aria-hidden="true">
      <span class="loading-dots__dot" />
      <span class="loading-dots__dot" />
      <span class="loading-dots__dot" />
    </span>
    <span class="sr-only" role="status">{{ statusText }}</span>
  </span>
</template>

<style lang="scss" scoped>
@import "index";
</style>
