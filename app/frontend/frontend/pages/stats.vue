<script lang="ts">
export default {
  name: "StatsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import Chart from "@/shared/components/Chart/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import StatsPanel from "@/shared/components/StatsPanel/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import {
  useStats as useStatsQuery,
  useModelsByClassification as useModelsByClassificationQuery,
  useModelsBySize as useModelsBySizeQuery,
  useModelsByProductionStatus as useModelsByProductionStatusQuery,
  useModelsPerMonth as useModelsPerMonthQuery,
  useModelsByManufacturer as useModelsByManufacturerQuery,
} from "@/services/fyApi";

const { t } = useI18n();

useMetaInfo();

const { data: quickStats } = useStatsQuery();

const { data: modelsByClassification, ...modelsByClassificationStatus } =
  useModelsByClassificationQuery();

const { data: modelsBySize, ...modelsBySizeStatus } = useModelsBySizeQuery();

const { data: modelsByProductionStatus, ...modelsByProductionStatusStatus } =
  useModelsByProductionStatusQuery();

const { data: modelsPerMonth, ...modelsPerMonthStatus } =
  useModelsPerMonthQuery();

const { data: modelsByManufacturer, ...modelsByManufacturerStatus } =
  useModelsByManufacturerQuery();

const route = useRoute();

const shipsCountYear = ref(0);
const shipsCountTotal = ref(0);

// use refs and watch for stats to trigger animation on every page visit
watch(
  () => [quickStats.value?.shipsCountYear, quickStats.value?.shipsCountTotal],
  () => {
    setTimeout(() => {
      shipsCountYear.value = quickStats.value?.shipsCountYear || 0;
      shipsCountTotal.value = quickStats.value?.shipsCountTotal || 0;
    }, 200);
  },
  { immediate: true },
);
</script>

<template>
  <Teleport to="#header-left">
    <Heading hidden>{{ t(`headlines.${route.meta.title}`) }}</Heading>
  </Teleport>
  <div class="row">
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-rocket-launch fa-4x"
        :value="shipsCountYear"
        :label="
          t('labels.stats.quickStats.newShips', {
            year: String(new Date().getFullYear()),
          })
        "
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-rocket fa-4x"
        :value="shipsCountTotal"
        :label="t('labels.stats.quickStats.totalShips')"
      />
    </div>
  </div>
  <div class="row">
    <div class="col-12 col-md-6">
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.stats.modelsByClassification") }}
        </PanelHeading>
        <PanelBody>
          <Chart
            v-if="modelsByClassification"
            key="models-by-classification"
            name="models-by-classification"
            :options="modelsByClassification"
            :async-status="modelsByClassificationStatus"
            tooltip-type="ship-pie"
            type="pie"
          />
        </PanelBody>
      </Panel>
    </div>
    <div class="col-12 col-md-6">
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.stats.modelsBySize") }}
        </PanelHeading>
        <PanelBody>
          <Chart
            key="models-by-size"
            name="models-by-size"
            :options="modelsBySize"
            :async-status="modelsBySizeStatus"
            tooltip-type="ship-pie"
            type="pie"
          />
        </PanelBody>
      </Panel>
    </div>
  </div>
  <div class="row">
    <div class="col-12 col-md-5">
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.stats.modelsByProductionStatus") }}
        </PanelHeading>
        <PanelBody>
          <Chart
            key="models-by-production-status"
            name="models-by-production-status"
            :options="modelsByProductionStatus"
            :async-status="modelsByProductionStatusStatus"
            tooltip-type="ship-pie"
            type="pie"
          />
        </PanelBody>
      </Panel>
    </div>
    <div class="col-12 col-md-7">
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.stats.modelsPerMonth") }}
        </PanelHeading>
        <PanelBody>
          <Chart
            key="models-per-month"
            name="models-per-month"
            :options="modelsPerMonth"
            :async-status="modelsPerMonthStatus"
            tooltip-type="ship"
            type="column"
          />
        </PanelBody>
      </Panel>
    </div>
  </div>
  <div class="row">
    <div class="col-12 col-lg-6">
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.stats.modelsByManufacturer") }}
        </PanelHeading>
        <PanelBody>
          <Chart
            key="models-by-manufacturer"
            name="models-by-manufacturer"
            :options="modelsByManufacturer"
            :async-status="modelsByManufacturerStatus"
            tooltip-type="ship-pie"
            type="pie"
          />
        </PanelBody>
      </Panel>
    </div>
  </div>
</template>
