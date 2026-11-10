<script lang="ts">
export default {
  name: "FleetchartCanvasProgress",
};
</script>

<script lang="ts" setup>
import ProgressBar from "@/shared/components/ProgressBar/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { ImageProgress } from "@/frontend/components/Fleetchart/imageProgress";
import type { ExportProgress } from "@/frontend/components/Fleetchart/exportProgress";

interface Props {
  images: ImageProgress;
  exportProgress: ExportProgress;
}

const props = defineProps<Props>();

const { t, currentLocale } = useI18n();

const formatter = computed(() => new Intl.NumberFormat(currentLocale()));

const percentOf = (done: number, total: number) =>
  total ? Math.floor((done / total) * 100) : 0;

// An export takes over from the picture count, which it would otherwise restart
// as every ship fetches its full-size picture.
const state = computed(() => {
  const stage = props.exportProgress.stage.value;

  if (stage === "pictures") {
    const { done, total } = props.exportProgress;

    return {
      label: t("labels.fleetchartApp.exportPictures", {
        loaded: formatter.value.format(done.value),
        total: formatter.value.format(total.value),
      }),
      percent: percentOf(done.value, total.value),
    };
  }

  if (stage) {
    return {
      label: t(
        stage === "drawing"
          ? "labels.fleetchartApp.exportDrawing"
          : "labels.fleetchartApp.exportSaving",
      ),
      percent: undefined,
    };
  }

  const requested = props.images.requested.value;
  const outstanding = props.images.outstanding.value;

  if (!outstanding) {
    return undefined;
  }

  return {
    label: t("labels.fleetchartApp.loadingPictures", {
      loaded: formatter.value.format(requested - outstanding),
      total: formatter.value.format(requested),
    }),
    percent: percentOf(requested - outstanding, requested),
  };
});
</script>

<template>
  <div
    v-if="state"
    class="fleetchart-canvas-progress"
    :class="{ 'fleetchart-canvas-progress--now': exportProgress.stage.value }"
    role="status"
    :data-test="
      exportProgress.stage.value
        ? 'fleetchart-export-progress'
        : 'fleetchart-image-progress'
    "
  >
    <span class="fleetchart-canvas-progress__label">{{ state.label }}</span>
    <ProgressBar v-if="state.percent !== undefined" :progress="state.percent" />
    <div v-else class="fleetchart-canvas-progress__working" />
  </div>
</template>

<style lang="scss" scoped>
@import "index.scss";
</style>
