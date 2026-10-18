<script lang="ts">
export default {
  name: "HangarSyncSteps",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import SyncProgressBar from "@/frontend/components/Hangar/SyncProgressBar/index.vue";
import SyncNumberText from "@/frontend/components/Hangar/SyncNumberText/index.vue";
import Collapsed from "@/shared/components/Collapsed.vue";
import { useReducedMotion } from "@/shared/composables/useReducedMotion";
import type { SyncStep } from "./types";

type Props = {
  steps: SyncStep[];
};

const props = defineProps<Props>();

const slots = useSlots();

const { t } = useI18n();

const { prefersReducedMotion } = useReducedMotion();

const collapseDuration = computed(() => (prefersReducedMotion.value ? 1 : 200));

const bodyId = useId();

const hasBody = (step: SyncStep) =>
  !!step.progress || !!step.caption || !!slots[`step-${step.key}`];

// A step the run has moved on from folds away under its heading, so the step
// now running is the one in view; its heading opens it again. The last step
// stays open: it ends the run, and what it says is the run's news.
const collapsible = (step: SyncStep, index: number) =>
  (step.status === "done" || step.status === "warning") &&
  index < props.steps.length - 1 &&
  hasBody(step);

const toggled = ref<Record<string, boolean>>({});

const isOpen = (step: SyncStep, index: number) =>
  !collapsible(step, index) || (toggled.value[step.key] ?? false);

const toggle = (step: SyncStep, index: number) => {
  toggled.value = { ...toggled.value, [step.key]: !isOpen(step, index) };
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
      :aria-current="step.status === 'active' ? 'step' : undefined"
    >
      <div class="sync-steps__rail" aria-hidden="true">
        <span class="sync-steps__marker">
          <i v-if="step.status === 'done'" class="fa-solid fa-check" />
          <i
            v-else-if="step.status === 'warning'"
            class="fa-solid fa-exclamation"
          />
          <i v-else-if="step.status === 'failed'" class="fa-solid fa-xmark" />
          <template v-else>{{ index + 1 }}</template>
        </span>
        <span v-if="index < steps.length - 1" class="sync-steps__line" />
      </div>
      <div class="sync-steps__content">
        <component
          :is="collapsible(step, index) ? 'button' : 'div'"
          class="sync-steps__heading"
          :class="{ 'sync-steps__heading--toggle': collapsible(step, index) }"
          v-bind="
            collapsible(step, index)
              ? {
                  type: 'button',
                  'aria-expanded': isOpen(step, index),
                  'aria-controls': `${bodyId}-${step.key}`,
                }
              : {}
          "
          :data-test="`sync-step-${step.key}-heading`"
          @click="collapsible(step, index) && toggle(step, index)"
        >
          <span class="sync-steps__label">{{ step.label }}</span>
          <span class="sr-only">
            {{ t(`labels.syncExtension.stepStatus.${step.status}`) }}
          </span>
          <span v-if="step.detail" class="sync-steps__detail">
            <template v-if="typeof step.detail === 'string'">
              {{ step.detail }}
            </template>
            <SyncNumberText v-else :text="step.detail" />
          </span>
          <i
            v-if="collapsible(step, index)"
            class="fa-light fa-chevron-down sync-steps__chevron"
            aria-hidden="true"
          />
        </component>
        <Collapsed
          v-if="hasBody(step)"
          :id="`${bodyId}-${step.key}`"
          :visible="isOpen(step, index)"
          :duration="collapseDuration"
        >
          <div class="sync-steps__body">
            <SyncProgressBar
              v-if="step.progress"
              :progress="
                step.progress === 'indeterminate' ? undefined : step.progress
              "
              :label="step.label"
            />
            <p
              v-if="step.caption"
              class="sync-steps__caption"
              :data-test="`sync-step-${step.key}-caption`"
            >
              <template v-if="typeof step.caption === 'string'">
                {{ step.caption }}
              </template>
              <SyncNumberText v-else :text="step.caption" />
            </p>
            <slot :name="`step-${step.key}`" />
          </div>
        </Collapsed>
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

.sync-steps__heading--toggle {
  width: 100%;
  padding: 0;
  color: inherit;
  font: inherit;
  text-align: left;
  background: transparent;
  border: 0;
  cursor: pointer;

  &:hover .sync-steps__label {
    color: var(--color-lifted, #eee);
  }

  &:focus-visible {
    outline: 2px solid var(--color-primary, #428bca);
    outline-offset: 2px;
    border-radius: 4px;
  }
}

.sync-steps__chevron {
  margin-left: auto;
  align-self: center;
  color: var(--color-muted, #7a8288);
  transition: transform 150ms ease;
}

.sync-steps__heading[aria-expanded="true"] .sync-steps__chevron {
  transform: rotate(180deg);
}

// Spaced inside the element Collapsed animates, not on it, so nothing jumps
// at the end of the animation.
.sync-steps__body {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding-top: 8px;
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
.sync-steps__step--warning,
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

.sync-steps__step--warning .sync-steps__marker {
  color: var(--color-warning, #fa6800);
  border-color: var(--color-warning, #fa6800);
}

.sync-steps__step--failed .sync-steps__marker {
  color: #f2b8be;
  border-color: var(--color-danger, #dc3545);
}

.sync-steps__caption {
  margin: 0;
  color: var(--color-text-dim, #959595);
  font-size: 13px;
  font-variant-numeric: tabular-nums;
}
</style>
