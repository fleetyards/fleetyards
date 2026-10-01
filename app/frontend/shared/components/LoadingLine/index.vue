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

const statusText = computed(() =>
  props.loading ? props.label || t("labels.loading") : "",
);
</script>

<!-- The motion a still skeleton deliberately lacks, scoped to the one area
     that is waiting rather than the app-wide fetch bar at the window's top.
     It stays mounted while idle: a live region only announces a change to
     text that was already in the document. -->
<template>
  <div
    class="loading-line"
    :class="[`loading-line--${edge}`, { 'loading-line--active': loading }]"
    data-test="loading-line"
  >
    <span class="sr-only" role="status">{{ statusText }}</span>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
