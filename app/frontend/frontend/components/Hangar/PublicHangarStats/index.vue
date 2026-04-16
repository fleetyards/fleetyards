<script lang="ts">
export default {
  name: "PublicHangarStats",
};
</script>

<script lang="ts" setup>
import StatsPanel from "@/shared/components/StatsPanel/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Chart from "@/shared/components/Chart/index.vue";
import {
  usePublicHangarStats as usePublicHangarStatsQuery,
  usePublicHangarModelsByClassification as usePublicHangarModelsByClassificationQuery,
  usePublicHangarModelsBySize as usePublicHangarModelsBySizeQuery,
  usePublicHangarModelsByProductionStatus as usePublicHangarModelsByProductionStatusQuery,
  usePublicHangarModelsByManufacturer as usePublicHangarModelsByManufacturerQuery,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  username: string;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { data: quickStats } = usePublicHangarStatsQuery(props.username);

const { data: modelsByClassificationOptions, ...modelsByClassificationStatus } =
  usePublicHangarModelsByClassificationQuery(props.username);

const { data: modelsBySizeOptions, ...modelsBySizeStatus } =
  usePublicHangarModelsBySizeQuery(props.username);

const { data: modelsByManufacturerOptions, ...modelsByManufacturerStatus } =
  usePublicHangarModelsByManufacturerQuery(props.username);

const {
  data: modelsByProductionStatusOptions,
  ...modelsByProductionStatusStatus
} = usePublicHangarModelsByProductionStatusQuery(props.username);

const totalCount = ref(0);
const minCrew = ref(0);
const maxCrew = ref(0);
const totalCargo = ref(0);
const largestShip = ref(0);
const smallestShip = ref(0);
const flightReadyCount = ref(0);
const uniqueModelsCount = ref(0);
const manufacturerCount = ref(0);

watch(
  () => [
    quickStats.value?.total,
    quickStats.value?.metrics.totalMinCrew,
    quickStats.value?.metrics.totalMaxCrew,
    quickStats.value?.metrics.totalCargo,
    quickStats.value?.metrics.largestShip,
    quickStats.value?.metrics.smallestShip,
    quickStats.value?.metrics.flightReadyCount,
    quickStats.value?.metrics.uniqueModelsCount,
    quickStats.value?.metrics.manufacturerCount,
  ],
  () => {
    setTimeout(() => {
      totalCount.value = quickStats.value?.total || 0;
      minCrew.value = quickStats.value?.metrics.totalMinCrew || 0;
      maxCrew.value = quickStats.value?.metrics.totalMaxCrew || 0;
      totalCargo.value = quickStats.value?.metrics.totalCargo || 0;
      largestShip.value = quickStats.value?.metrics.largestShip || 0;
      smallestShip.value = quickStats.value?.metrics.smallestShip || 0;
      flightReadyCount.value = quickStats.value?.metrics.flightReadyCount || 0;
      uniqueModelsCount.value =
        quickStats.value?.metrics.uniqueModelsCount || 0;
      manufacturerCount.value =
        quickStats.value?.metrics.manufacturerCount || 0;
    }, 200);
  },
  { immediate: true },
);

const uniqueModelsPercent = computed(() => {
  if (!totalCount.value || !uniqueModelsCount.value) return "";
  return `(${Math.round((uniqueModelsCount.value / totalCount.value) * 100)}%)`;
});

const flightReadyPercent = computed(() => {
  if (!totalCount.value || !flightReadyCount.value) return "";
  return `(${Math.round((flightReadyCount.value / totalCount.value) * 100)}%)`;
});
</script>

<template>
  <div class="row">
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-rocket fa-4x"
        :value="totalCount"
        :label="t('labels.stats.quickStats.totalShips')"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-fingerprint fa-4x"
        :value="uniqueModelsCount"
        :label="t('labels.hangarMetrics.uniqueModels')"
        :suffix="uniqueModelsPercent"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-check-circle fa-4x"
        :value="flightReadyCount"
        :label="t('labels.hangarMetrics.flightReady')"
        :suffix="flightReadyPercent"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-box-taped fa-4x"
        :value="totalCargo"
        :label="t('labels.hangarMetrics.totalCargo')"
        :suffix="t('number.units.cargo')"
      />
    </div>
  </div>

  <div class="row">
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-industry fa-4x"
        :value="manufacturerCount"
        :label="t('labels.hangarMetrics.manufacturerCount')"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-ruler fa-4x"
        :value="largestShip"
        :label="t('labels.hangarMetrics.largestShip')"
        :suffix="t('number.units.distance')"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-ruler fa-4x"
        :value="smallestShip"
        :label="t('labels.hangarMetrics.smallestShip')"
        :suffix="t('number.units.distance')"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-user fa-4x"
        :value="minCrew"
        :label="t('labels.hangarMetrics.totalMinCrew')"
        :suffix="t('number.units.people', { count: minCrew })"
      />
    </div>
  </div>

  <div class="row">
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-users fa-4x"
        :value="maxCrew"
        :label="t('labels.hangarMetrics.totalMaxCrew')"
        :suffix="t('number.units.people', { count: maxCrew })"
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
            v-if="modelsByClassificationOptions"
            key="models-by-classification"
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
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.stats.modelsBySize") }}
        </PanelHeading>
        <PanelBody>
          <Chart
            v-if="modelsBySizeOptions"
            key="models-by-size"
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
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.stats.modelsByProductionStatus") }}
        </PanelHeading>
        <PanelBody>
          <Chart
            v-if="modelsByProductionStatusOptions"
            key="models-by-production-status"
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
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.stats.modelsByManufacturer") }}
        </PanelHeading>
        <PanelBody>
          <Chart
            v-if="modelsByManufacturerOptions"
            key="models-by-manufacturer"
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
