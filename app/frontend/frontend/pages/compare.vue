<script lang="ts">
export default {
  name: "ComparePage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import CompareRow from "@/frontend/components/Compare/Models/Row/index.vue";
import CompareForm from "@/frontend/components/Compare/Models/Form/index.vue";
import CompareHeaderImage from "@/frontend/components/Compare/Models/HeaderImage/index.vue";
import CompareHeaderTitle from "@/frontend/components/Compare/Models/HeaderTitle/index.vue";
import CompareView from "@/frontend/components/Compare/Models/View/index.vue";
import CompareBase from "@/frontend/components/Compare/Models/Base/index.vue";
import CompareCrew from "@/frontend/components/Compare/Models/Crew/index.vue";
import CompareSpeed from "@/frontend/components/Compare/Models/Speed/index.vue";
import CompareHardpoints from "@/frontend/components/Compare/Models/Hardpoints/index.vue";
import CompareHardpointsOld from "@/frontend/components/Compare/Models/HardpointsOld/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useNavStore } from "@/shared/stores/nav";
import { useFeatures } from "@/frontend/composables/useFeatures";
import Empty from "@/shared/components/Empty/index.vue";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import { ModelsParams, useModels as useModelsQuery } from "@/services/fyApi";
import { useCompareModelFilters } from "@/frontend/composables/useCompareModelFilters";

const { t } = useI18n();

const { isFeatureEnabled } = useFeatures();

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

const { data, refetch, ...asyncStatus } = useModelsQuery(params, {
  query: {
    overrideQueryKey: ["compare-models", params],
  },
});

const models = computed(() => {
  return (
    data.value?.items.filter((model) => items.value.includes(model.slug)) || []
  );
});

watch(
  () => filters.value.models,
  () => {
    if (filters.value.models) {
      refetch();
    }
  },
  { deep: true },
);
</script>

<template>
  <Heading hidden>{{ t("headlines.compare.ships") }}</Heading>

  <div class="compare-models row">
    <div class="col-12">
      <CompareRow
        :models="models"
        row-key="image"
        :slim="navStore.slim"
        headline
      >
        <template #label>
          <CompareForm :models="models" />
        </template>
        <template #default="{ model }">
          <CompareHeaderImage :model="model" />
        </template>
      </CompareRow>
      <AsyncData :async-status="asyncStatus">
        <template #resolved>
          <div v-if="!models.length" class="row compare-row">
            <div class="col-12">
              <Empty :variant="EmptyVariantsEnum.BOX" hide-actions>
                <template #title>
                  {{ t("headlines.compare.ships") }}
                </template>
                <template #info>
                  <p class="text-muted">
                    {{ t("texts.compare.ships.info") }}
                  </p>
                </template>
              </Empty>
            </div>
          </div>
          <div v-else class="compare-wrapper">
            <CompareHeaderTitle :models="models" :slim="navStore.slim" />
            <CompareView :models="models" :slim="navStore.slim" />
            <CompareBase :models="models" :slim="navStore.slim" />
            <CompareCrew :models="models" :slim="navStore.slim" />
            <CompareSpeed :models="models" :slim="navStore.slim" />
            <CompareHardpoints
              v-if="isFeatureEnabled('hardpoints-v2')"
              :models="models"
              :slim="navStore.slim"
            />
            <CompareHardpointsOld
              v-else
              :models="models"
              :slim="navStore.slim"
            />
          </div>
        </template>
      </AsyncData>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "compare.scss";
</style>
