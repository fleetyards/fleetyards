<script lang="ts">
export default {
  name: "ImportsProgress",
};
</script>

<script lang="ts" setup>
import { type Import, ImportStatusEnum } from "@/services/fyAdminApi";
import { isNewer, useImportsStore } from "@/admin/stores/imports";
import { useI18n } from "@/shared/composables/useI18n";

interface Props {
  record: Import;
}

const props = defineProps<Props>();

const { t, toNumber } = useI18n();
const importsStore = useImportsStore();

// The record a page fetched stands still while the store follows the
// broadcasts, but a run an admin cleared is only ever refetched.
const current = computed(() => {
  const live = importsStore.imports[props.record.id];

  return live && isNewer(live, props.record) ? live : props.record;
});

// A failed run keeps its progress, which says where it stopped. One that
// finished has nothing left to say.
const progress = computed(() =>
  current.value.status === ImportStatusEnum.STARTED ||
  current.value.status === ImportStatusEnum.FAILED
    ? current.value.progress
    : undefined,
);

const failed = computed(() => current.value.status === ImportStatusEnum.FAILED);

const label = computed(() => {
  if (!progress.value) return "";

  const step = t(`labels.imports.progress.steps.${progress.value.step}`);

  if (progress.value.steps === 1) return step;

  return t("labels.imports.progress.step", {
    step,
    number: progress.value.stepNumber,
    total: progress.value.steps,
  });
});

const percent = computed(() => {
  const { done, total } = progress.value ?? {};

  if (!total) return undefined;

  return Math.min(100, Math.floor(((done ?? 0) / total) * 100));
});
</script>

<template>
  <div
    v-if="progress"
    class="import-progress"
    :class="{ 'import-progress--failed': failed }"
    data-test="import-progress"
  >
    <div class="import-progress__text">
      <span>{{ label }}</span>
      <span v-if="progress.total" data-test="import-progress-count">
        {{ toNumber(progress.done) }} / {{ toNumber(progress.total) }}
      </span>
    </div>
    <div
      class="import-progress__bar"
      role="progressbar"
      :aria-label="label"
      aria-valuemin="0"
      aria-valuemax="100"
      :aria-valuenow="percent"
    >
      <div
        class="import-progress__fill"
        :style="{ width: `${percent ?? 0}%` }"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
.import-progress {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 180px;
  margin-top: 4px;
}

.import-progress__text {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  gap: 0 12px;
  font-size: 0.8125rem;
  font-variant-numeric: tabular-nums;
  color: var(--color-text-dim, #959595);
}

.import-progress__bar {
  height: 4px;
  overflow: hidden;
  border-radius: 2px;
  background-color: var(--color-edge-faint, rgb(122 130 136 / 0.16));
}

.import-progress__fill {
  height: 100%;
  border-radius: 2px;
  background-color: var(--color-primary, #428bca);
  transition: width 300ms ease;
}

.import-progress--failed .import-progress__fill {
  background-color: var(--color-danger, #d9534f);
}

@media (prefers-reduced-motion: reduce) {
  .import-progress__fill {
    transition: none;
  }
}
</style>
