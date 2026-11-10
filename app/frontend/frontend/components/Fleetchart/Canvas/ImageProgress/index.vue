<script lang="ts">
export default {
  name: "FleetchartCanvasImageProgress",
};
</script>

<script lang="ts" setup>
import ProgressBar from "@/shared/components/ProgressBar/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { ImageProgress } from "@/frontend/components/Fleetchart/imageProgress";

interface Props {
  progress: ImageProgress;
}

const props = defineProps<Props>();

const { t, currentLocale } = useI18n();

const formatter = computed(() => new Intl.NumberFormat(currentLocale()));

const requested = computed(() => props.progress.requested.value);

const loaded = computed(
  () => requested.value - props.progress.outstanding.value,
);

const percent = computed(() =>
  requested.value ? Math.floor((loaded.value / requested.value) * 100) : 0,
);
</script>

<template>
  <div
    v-if="progress.outstanding.value"
    class="fleetchart-canvas-image-progress"
    role="status"
    data-test="fleetchart-image-progress"
  >
    <span class="fleetchart-canvas-image-progress__label">
      {{
        t("labels.fleetchartApp.loadingPictures", {
          loaded: formatter.format(loaded),
          total: formatter.format(requested),
        })
      }}
    </span>
    <ProgressBar :progress="percent" />
  </div>
</template>

<style lang="scss" scoped>
@import "index.scss";
</style>
