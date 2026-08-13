<script lang="ts">
export default {
  name: "ComparePage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import Loader from "@/shared/components/Loader/index.vue";
import CompareForm from "@/frontend/components/Compare/Models/Form/index.vue";
import CompareHeader from "@/frontend/components/Compare/Models/Header/index.vue";
import CompareView from "@/frontend/components/Compare/Models/View/index.vue";
import CompareBase from "@/frontend/components/Compare/Models/Base/index.vue";
import CompareCrew from "@/frontend/components/Compare/Models/Crew/index.vue";
import CompareSpeed from "@/frontend/components/Compare/Models/Speed/index.vue";
import CompareCombat from "@/frontend/components/Compare/Models/Combat/index.vue";
import CompareDefense from "@/frontend/components/Compare/Models/Defense/index.vue";
import CompareHull from "@/frontend/components/Compare/Models/Hull/index.vue";
import CompareCargo from "@/frontend/components/Compare/Models/Cargo/index.vue";
import CompareFuel from "@/frontend/components/Compare/Models/Fuel/index.vue";
import CompareHardpoints from "@/frontend/components/Compare/Models/Hardpoints/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import Empty from "@/shared/components/Empty/index.vue";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import {
  type ModelsParams,
  useModels as useModelsQuery,
} from "@/services/fyApi";
import { useCompareModelFilters } from "@/frontend/composables/useCompareModelFilters";
import { useCompareHardpoints } from "@/frontend/composables/useCompareHardpoints";

const { t } = useI18n();

const { filters } = useCompareModelFilters();

const items = computed(() => {
  return filters.value.models || [];
});

const params = computed<ModelsParams>(() => {
  return {
    q: {
      slugIn: filters.value.models || ["-1"],
    },
  };
});

const { data, refetch, ...asyncStatus } = useModelsQuery(params);

const models = computed(() => {
  return (
    data.value?.items.filter((model) => items.value.includes(model.slug)) || []
  );
});

const { hardpointsFor, loading: hardpointsLoading } = useCompareHardpoints(
  () => models.value,
);

// Rows size themselves in CSS; the count only feeds the stack's minimum width, which
// keeps the section cards' frames spanning the full matrix once it outgrows the pane.
// Deriving that from `max-content` instead would let the store images' intrinsic width
// blow every column out to a thousand pixels.
const gridStyle = computed(() => ({
  "--compare-count": String(models.value.length),
}));

const pane = ref<HTMLElement>();

// The matrix scrolls inside its own pane rather than the document: that keeps the page
// from scrolling sideways (which left the footer and the rest of the chrome cut off at
// viewport width) and gives both sticky axes a scrollport of their own to anchor to.
// Its height is measured rather than guessed because the toolbar above it wraps.
const paneOffset = ref(220);

const PANE_BOTTOM_GAP = 30;

const measurePane = () => {
  if (!pane.value) {
    return;
  }

  paneOffset.value = Math.round(
    pane.value.getBoundingClientRect().top + window.scrollY + PANE_BOTTOM_GAP,
  );
};

const paneStyle = computed(() => ({
  "--compare-pane-offset": `${paneOffset.value}px`,
}));

onMounted(() => {
  measurePane();
  window.addEventListener("resize", measurePane);
});

onBeforeUnmount(() => {
  window.removeEventListener("resize", measurePane);
});

// The toolbar reflows as ships come and go, which moves the pane's top edge.
watch(
  () => models.value.length,
  async () => {
    await nextTick();
    measurePane();
  },
);

watch(
  () => filters.value.models,
  async () => {
    if (filters.value.models) {
      await refetch();
    }
  },
  { deep: true },
);
</script>

<template>
  <Heading hidden>{{ t("headlines.compare.ships") }}</Heading>

  <div class="row compare-models">
    <div class="col-12">
      <CompareForm :models="models" />

      <AsyncData :async-status="asyncStatus">
        <template #resolved>
          <Empty
            v-if="!models.length"
            :variant="EmptyVariantsEnum.BOX"
            hide-actions
          >
            <template #title>
              {{ t("headlines.compare.ships") }}
            </template>
            <template #info>
              <p class="text-muted">
                {{ t("texts.compare.ships.info") }}
              </p>
            </template>
          </Empty>
          <div v-else ref="pane" class="compare-pane" :style="paneStyle">
            <div class="compare-matrix-stack" :style="gridStyle">
              <CompareHeader :models="models" />
              <CompareView :models="models" />
              <CompareBase :models="models" />
              <CompareCrew :models="models" />
              <CompareSpeed :models="models" />
              <CompareCombat :models="models" :hardpoints-for="hardpointsFor" />
              <CompareDefense
                :models="models"
                :hardpoints-for="hardpointsFor"
              />
              <CompareHull :models="models" />
              <CompareCargo :models="models" />
              <CompareFuel :models="models" :hardpoints-for="hardpointsFor" />
              <CompareHardpoints
                :models="models"
                :hardpoints-for="hardpointsFor"
              />
            </div>
          </div>
        </template>
      </AsyncData>

      <Loader :loading="hardpointsLoading" fixed />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "compare.scss";
</style>
