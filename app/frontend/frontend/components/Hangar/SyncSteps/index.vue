<script lang="ts">
export default {
  name: "HangarSyncSteps",
};
</script>

<script lang="ts" setup>
import type { SyncStep } from "./types";

type Props = {
  steps: SyncStep[];
};

defineProps<Props>();

const progressAttrs = (step: SyncStep) => {
  if (!step.progress || step.progress === "indeterminate") return {};

  return {
    "aria-valuemin": 0,
    "aria-valuemax": step.progress.max,
    "aria-valuenow": step.progress.value,
  };
};

const progressWidth = (step: SyncStep) => {
  if (!step.progress || step.progress === "indeterminate") return undefined;
  if (!step.progress.max) return "0%";

  return `${Math.min(100, (step.progress.value / step.progress.max) * 100)}%`;
};
</script>

<template>
  <ol class="sync-steps">
    <li
      v-for="(step, index) in steps"
      :key="step.key"
      class="sync-steps__step"
      :class="`sync-steps__step--${step.status}`"
      :data-test="`sync-step-${step.key}`"
      :data-status="step.status"
    >
      <div class="sync-steps__rail" aria-hidden="true">
        <span class="sync-steps__marker">
          <i v-if="step.status === 'done'" class="fa-solid fa-check" />
          <i v-else-if="step.status === 'failed'" class="fa-solid fa-xmark" />
          <template v-else>{{ index + 1 }}</template>
        </span>
        <span v-if="index < steps.length - 1" class="sync-steps__line" />
      </div>
      <div class="sync-steps__content">
        <div class="sync-steps__heading">
          <span class="sync-steps__label">{{ step.label }}</span>
          <span v-if="step.detail" class="sync-steps__detail">
            {{ step.detail }}
          </span>
        </div>
        <div
          v-if="step.progress"
          class="sync-steps__bar"
          :class="{
            'sync-steps__bar--indeterminate': step.progress === 'indeterminate',
          }"
          role="progressbar"
          :aria-label="step.label"
          v-bind="progressAttrs(step)"
        >
          <span
            class="sync-steps__fill"
            :style="{ width: progressWidth(step) }"
          />
        </div>
        <slot :name="`step-${step.key}`" />
      </div>
    </li>
  </ol>
</template>

<style lang="scss" scoped>
.sync-steps {
  display: flex;
  flex-direction: column;
  margin: 0;
  padding: 0;
  list-style: none;
}

.sync-steps__step {
  display: flex;
  gap: 14px;
}

.sync-steps__rail {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.sync-steps__marker {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  width: 28px;
  height: 28px;
  color: var(--color-text-dim, #959595);
  font-size: 13px;
  border: 1px solid var(--color-edge, rgb(122 130 136 / 0.5));
  border-radius: 999px;
}

.sync-steps__line {
  flex: 1 1 auto;
  width: 1px;
  min-height: 14px;
  margin: 4px 0;
  background-color: var(--color-edge-soft, rgb(122 130 136 / 0.28));
}

.sync-steps__content {
  display: flex;
  flex: 1 1 auto;
  flex-direction: column;
  gap: 8px;
  min-width: 0;
  padding: 3px 0 16px;
}

.sync-steps__step:last-child .sync-steps__content {
  padding-bottom: 0;
}

.sync-steps__heading {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  column-gap: 10px;
}

.sync-steps__label {
  color: var(--color-text-dim, #959595);
  font-size: 15px;
}

.sync-steps__detail {
  color: var(--color-text-dim, #959595);
  font-size: 13px;
  font-variant-numeric: tabular-nums;
}

.sync-steps__step--active,
.sync-steps__step--done,
.sync-steps__step--failed {
  .sync-steps__label {
    color: var(--color-lifted, #eee);
  }
}

.sync-steps__step--active .sync-steps__marker {
  color: var(--color-lifted, #eee);
  border-color: var(--color-primary, #428bca);
}

.sync-steps__step--done .sync-steps__marker {
  color: #8fd18f;
  border-color: var(--color-success, #5cb85c);
}

.sync-steps__step--failed .sync-steps__marker {
  color: #f2b8be;
  border-color: var(--color-danger, #dc3545);
}

.sync-steps__bar {
  position: relative;
  height: 6px;
  overflow: hidden;
  background-color: rgb(122 130 136 / 0.2);
  border-radius: 999px;
}

.sync-steps__fill {
  position: absolute;
  top: 0;
  bottom: 0;
  left: 0;
  background-color: var(--color-primary, #428bca);
  border-radius: 999px;
  transition: width 300ms ease;
}

// Without a total there is no fraction to show, only that it is working.
.sync-steps__bar--indeterminate .sync-steps__fill {
  width: 28%;
  background: linear-gradient(
    to right,
    transparent,
    var(--color-primary, #428bca) 30%,
    var(--color-primary, #428bca) 70%,
    transparent
  );
  animation: sync-steps-slide 1.6s ease-in-out infinite;
}

@keyframes sync-steps-slide {
  from {
    left: -28%;
  }

  to {
    left: 100%;
  }
}

@media (prefers-reduced-motion: reduce) {
  .sync-steps__bar--indeterminate .sync-steps__fill {
    left: 36%;
    animation: none;
  }
}
</style>
