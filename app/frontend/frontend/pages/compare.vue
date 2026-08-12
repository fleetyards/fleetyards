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
import { useNavStore } from "@/shared/stores/nav";
import Empty from "@/shared/components/Empty/index.vue";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import {
  type ModelsParams,
  useModels as useModelsQuery,
} from "@/services/fyApi";
import { useCompareModelFilters } from "@/frontend/composables/useCompareModelFilters";
import { useCompareHardpoints } from "@/frontend/composables/useCompareHardpoints";

const { t } = useI18n();

const navStore = useNavStore();

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

// Every row — header, stat rows, hardpoint lists — shares this one template, which
// is what keeps the columns aligned across separate section cards. The tracks are a
// fixed width rather than `1fr`: a flexible track sizes against its content, and the
// store images' intrinsic width would stretch a two-ship comparison to a thousand
// pixels per column. The trailing `1fr` soaks up any leftover width.
//
// The frozen label column has to clear the fixed navigation rail, whose width the
// page scrolls underneath — sticking it at 0 would park it behind the nav.
const gridStyle = computed(() => ({
  "--compare-cols": `var(--compare-label) repeat(${models.value.length}, var(--compare-col)) 1fr`,
  "--compare-count": String(models.value.length),
  "--compare-sticky-left": navStore.slim ? "80px" : "300px",
}));

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
          <div v-else class="compare-matrix-stack" :style="gridStyle">
            <CompareHeader :models="models" />
            <CompareView :models="models" />
            <CompareBase :models="models" />
            <CompareCrew :models="models" />
            <CompareSpeed :models="models" />
            <CompareCombat :models="models" :hardpoints-for="hardpointsFor" />
            <CompareDefense :models="models" :hardpoints-for="hardpointsFor" />
            <CompareHull :models="models" />
            <CompareCargo :models="models" />
            <CompareFuel :models="models" :hardpoints-for="hardpointsFor" />
            <CompareHardpoints
              :models="models"
              :hardpoints-for="hardpointsFor"
            />
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
