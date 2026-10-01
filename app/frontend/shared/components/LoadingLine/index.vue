<script lang="ts">
export default {
  name: "LoadingLine",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";

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

const { t } = useI18n();

// A live region only announces a change to text that was already in the
// document, and many of these mount already loading - an expanded row, a step
// that appears once it starts. So the text always arrives a moment after the
// region does, which screen readers pick up whichever way the line appeared.
const ANNOUNCE_DELAY = 150;

const statusText = ref("");

let announceTimer: ReturnType<typeof setTimeout> | undefined;

const clearAnnounce = () => {
  if (announceTimer) clearTimeout(announceTimer);
  announceTimer = undefined;
};

watch(
  () => [props.loading, props.label] as const,
  ([loading, label]) => {
    clearAnnounce();

    if (!loading) {
      statusText.value = "";
      return;
    }

    announceTimer = setTimeout(() => {
      statusText.value = label || t("labels.loading");
    }, ANNOUNCE_DELAY);
  },
  { immediate: true },
);

onBeforeUnmount(clearAnnounce);
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
