<script lang="ts">
export default {
  name: "PullToRefresh",
};
</script>

<script lang="ts" setup>
import {
  usePullToRefresh,
  PULL_LIMIT_PX,
  PULL_THRESHOLD_PX,
} from "@/shared/composables/usePullToRefresh";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  /*
   * The element the gesture is read on, rather than the document: the modal,
   * the off-canvas panel and the notification stack are all mounted beside it,
   * so a pull inside one of those never reaches this listener at all.
   */
  target?: HTMLElement | null;
  refresh: () => Promise<unknown> | unknown;
  disabled?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  target: null,
  disabled: false,
});

const { t } = useI18n();

const target = computed(() => props.target);

const disabled = computed(() => props.disabled);

const { distance, pulling, refreshing, armed } = usePullToRefresh({
  target,
  refresh: () => props.refresh(),
  disabled,
});

const style = computed(() => ({
  transform: `translate3d(-50%, ${distance.value}px, 0)`,
  opacity: String(Math.min(distance.value / PULL_THRESHOLD_PX, 1)),
}));

// Handed over to the spin animation the moment the pull is done, so the icon
// does not jump back to its resting angle first.
const iconStyle = computed(() => {
  if (refreshing.value) {
    return undefined;
  }

  // Half a turn over the whole pull, not more: the glyph repeats itself every
  // 180deg, so a longer sweep would pass through its own resting shape on the
  // way and read as the pull having snapped back.
  return {
    transform: `rotate(${(distance.value / PULL_LIMIT_PX) * 180}deg)`,
  };
});
</script>

<template>
  <div
    class="pull-to-refresh"
    :class="{
      'pull-to-refresh--pulling': pulling,
      'pull-to-refresh--armed': armed,
      'pull-to-refresh--refreshing': refreshing,
    }"
    :style="style"
    data-test="pull-to-refresh"
  >
    <span class="pull-to-refresh__indicator" aria-hidden="true">
      <i class="fa-duotone fa-rotate" :style="iconStyle" />
    </span>
    <span class="sr-only" role="status">
      {{ refreshing ? t("labels.refreshing") : "" }}
    </span>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
