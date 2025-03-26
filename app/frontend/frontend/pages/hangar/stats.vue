<script lang="ts">
export default {
  name: "HangarStatsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Chart from "@/shared/components/Chart/index.vue";
import Panel from "@/shared/components/Panel/index.vue";
import PanelHeading from "@/shared/components/Panel/Heading/index.vue";
import { PanelHeadingLevelEnum } from "@/shared/components/Panel/Heading/types";
import PanelBody from "@/shared/components/Panel/Body/index.vue";
import StatsPanel from "@/shared/components/StatsPanel/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useHangarStats as useHangarStatsQuery,
  useHangarModelsByClassification as useHangarModelsByClassificationQuery,
  useHangarModelsBySize as useHangarModelsBySizeQuery,
  useHangarModelsByManufacturer as useHangarModelsByManufacturerQuery,
  useHangarModelsByProductionStatus as useHangarModelsByProductionStatusQuery,
} from "@/services/fyApi";

const { t } = useI18n();

const { data: quickStats } = useHangarStatsQuery();

const { data: modelsByClassificationOptions, ...modelsByClassificationStatus } =
  useHangarModelsByClassificationQuery();

const { data: modelsBySizeOptions, ...modelsBySizeStatus } =
  useHangarModelsBySizeQuery();

const { data: modelsByManufacturerOptions, ...modelsByManufacturerStatus } =
  useHangarModelsByManufacturerQuery();

const {
  data: modelsByProductionStatusOptions,
  ...modelsByProductionStatusStatus
} = useHangarModelsByProductionStatusQuery();

const totalCount = ref(0);
const minCrew = ref(0);
const maxCrew = ref(0);
const totalCargo = ref(0);

// use refs and watch for stats to trigger animation on every page visit
watch(
  () => [
    quickStats.value?.total,
    quickStats.value?.metrics.totalMinCrew,
    quickStats.value?.metrics.totalMaxCrew,
    quickStats.value?.metrics.totalCargo,
  ],
  () => {
    setTimeout(() => {
      totalCount.value = quickStats.value?.total || 0;
      minCrew.value = quickStats.value?.metrics.totalMinCrew || 0;
      maxCrew.value = quickStats.value?.metrics.totalMaxCrew || 0;
      totalCargo.value = quickStats.value?.metrics.totalCargo || 0;
    }, 200);
  },
  { immediate: true },
);

const route = useRoute();
</script>

<template>
  <BreadCrumbs :crumbs="[{ to: { name: 'hangar' }, label: t('nav.hangar') }]" />
  <Heading>{{ t(`headlines.${route.meta.title}`) }}</Heading>
  <div class="row">
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-rocket fa-4x"
        :value="totalCount"
        :label="t('labels.stats.quickStats.totalShips')"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-user fa-4x"
        :value="minCrew"
        :label="t('labels.hangarMetrics.totalMinCrew')"
        :suffix="t('number.units.people', { count: minCrew })"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-user fa-4x"
        :value="maxCrew"
        :label="t('labels.hangarMetrics.totalMaxCrew')"
        :suffix="t('number.units.people', { count: maxCrew })"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-box-taped fa-4x"
        :value="totalCargo"
        :label="t('labels.hangarMetrics.totalCargo')"
        :suffix="t('number.units.cargo')"
      />
    </div>
  </div>
  <div class="row">
    <div class="col-12 col-md-6">
      <Panel>
        <PanelHeading :level="PanelHeadingLevelEnum.H2">
          {{ t("labels.stats.modelsByClassification") }}
        </PanelHeading>
        <PanelBody>
          <Chart
            name="models-by-classification"
            :async-status="modelsByClassificationStatus"
            :options="modelsByClassificationOptions"
            tooltip-type="ship-pie"
            type="pie"
          />
        </PanelBody>
      </Panel>
    </div>
    <div class="col-12 col-md-6">
      <Panel>
        <PanelHeading :level="PanelHeadingLevelEnum.H2">
          {{ t("labels.stats.modelsBySize") }}
        </PanelHeading>
        <PanelBody>
          <Chart
            name="models-by-size"
            :async-status="modelsBySizeStatus"
            :options="modelsBySizeOptions"
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
        <PanelHeading :level="PanelHeadingLevelEnum.H2">
          {{ t("labels.stats.modelsByProductionStatus") }}
        </PanelHeading>
        <PanelBody>
          <Chart
            name="models-by-production-status"
            :async-status="modelsByProductionStatusStatus"
            :options="modelsByProductionStatusOptions"
            tooltip-type="ship-pie"
            type="pie"
          />
        </PanelBody>
      </Panel>
    </div>
    <div class="col-12 col-md-7">
      <Panel>
        <PanelHeading :level="PanelHeadingLevelEnum.H2">
          {{ t("labels.stats.modelsByManufacturer") }}
        </PanelHeading>
        <PanelBody>
          <Chart
            name="models-by-manufacturer"
            :async-status="modelsByManufacturerStatus"
            :options="modelsByManufacturerOptions"
            tooltip-type="ship-pie"
            type="pie"
          />
        </PanelBody>
      </Panel>
    </div>
  </div>
</template>
