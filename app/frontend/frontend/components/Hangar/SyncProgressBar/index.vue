<script lang="ts">
export default {
  name: "HangarSyncProgressBar",
};
</script>

<script lang="ts" setup>
import type { SyncProgress } from "./types";

type Props = {
  // Without a value the bar only shows that something is working.
  progress?: SyncProgress;
  label: string;
  valueText?: string;
  slim?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  progress: undefined,
  valueText: undefined,
  slim: false,
});

const percent = (part: number, whole: number) =>
  `${Math.min(100, (part / whole) * 100)}%`;

// Against a reference the scale is whichever is larger, the value or the
// reference, so an excess still fits.
const scale = computed(() => {
  if (!props.progress) return 0;

  const { value, max, reference } = props.progress;

  return reference === undefined ? max : Math.max(value, reference);
});

const segments = computed(() => {
  if (!props.progress || !scale.value) return { fill: "0%" };

  const { value, reference, final } = props.progress;
  if (reference === undefined) return { fill: percent(value, scale.value) };

  return {
    fill: percent(Math.min(value, reference), scale.value),
    excess:
      value > reference ? percent(value - reference, scale.value) : undefined,
    gap:
      final && value < reference
        ? percent(reference - value, scale.value)
        : undefined,
    mark: value > reference ? percent(reference, scale.value) : undefined,
  };
});
</script>

<template>
  <div
    class="sync-progress-bar"
    :class="{
      'sync-progress-bar--indeterminate': !progress,
      'sync-progress-bar--slim': slim,
    }"
    role="progressbar"
    :aria-label="label"
    :aria-valuemin="progress ? 0 : undefined"
    :aria-valuemax="progress ? scale : undefined"
    :aria-valuenow="progress?.value"
    :aria-valuetext="valueText"
  >
    <span class="sync-progress-bar__fill" :style="{ width: segments.fill }" />
    <span
      v-if="segments.excess"
      class="sync-progress-bar__excess"
      :style="{ left: segments.fill, width: segments.excess }"
    />
    <span
      v-if="segments.gap"
      class="sync-progress-bar__gap"
      :style="{ left: segments.fill, width: segments.gap }"
    />
    <span
      v-if="segments.mark"
      class="sync-progress-bar__mark"
      :style="{ left: segments.mark }"
    />
  </div>
</template>

<style lang="scss" scoped>
.sync-progress-bar {
  position: relative;
  height: 6px;
  overflow: hidden;
  background-color: rgb(122 130 136 / 0.2);
  border-radius: 999px;
}

.sync-progress-bar--slim {
  height: 3px;
}

.sync-progress-bar__fill {
  position: absolute;
  top: 0;
  bottom: 0;
  left: 0;
  background-color: var(--color-primary, #428bca);
  border-radius: 999px;
  transition: width 300ms ease;
}

// What was read beyond the reference, past a mark where the reference ends.
.sync-progress-bar__excess {
  position: absolute;
  top: 0;
  bottom: 0;
  background-color: var(--color-success, #5cb85c);
  transition:
    left 300ms ease,
    width 300ms ease;
}

// What a finished run fell short of the reference by.
.sync-progress-bar__gap {
  position: absolute;
  top: 0;
  bottom: 0;
  background: repeating-linear-gradient(
    -45deg,
    rgb(250 104 0 / 0.55) 0 4px,
    transparent 4px 8px
  );
}

.sync-progress-bar__mark {
  position: absolute;
  top: 0;
  bottom: 0;
  width: 2px;
  margin-left: -1px;
  background-color: var(--color-lifted, #eee);
}

// Without a total there is no fraction to show, only that it is working.
.sync-progress-bar--indeterminate .sync-progress-bar__fill {
  width: 28%;
  background: linear-gradient(
    to right,
    transparent,
    var(--color-primary, #428bca) 30%,
    var(--color-primary, #428bca) 70%,
    transparent
  );
  animation: sync-progress-bar-slide 1.6s ease-in-out infinite;
}

@keyframes sync-progress-bar-slide {
  from {
    left: -28%;
  }

  to {
    left: 100%;
  }
}

@media (prefers-reduced-motion: reduce) {
  .sync-progress-bar--indeterminate .sync-progress-bar__fill {
    left: 36%;
    animation: none;
  }

  .sync-progress-bar__fill,
  .sync-progress-bar__excess {
    transition: none;
  }
}
</style>
