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
  useVehiclesByModel as useVehiclesByModelQuery,
  useVehiclesPerMonth as useVehiclesPerMonthQuery,
  useShipsOfTheMonth as useShipsOfTheMonthQuery,
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

const { data: vehiclesByModelOptions, ...vehiclesByModelStatus } =
  useVehiclesByModelQuery();

const { data: vehiclesPerMonthOptions, ...vehiclesPerMonthStatus } =
  useVehiclesPerMonthQuery();

const { data: shipsOfTheMonthOptions, ...shipsOfTheMonthStatus } =
  useShipsOfTheMonthQuery();

const route = useRoute();

const shipsCountYear = ref(0);
const shipsCountTotal = ref(0);
const manufacturerCount = ref(0);
const flightReadyCount = ref(0);
const averagePledgePrice = ref(0);
const largestShip = ref(0);
const smallestShip = ref(0);
const vehiclesCount = ref(0);
const wishlistsCount = ref(0);
const shipOfTheMonthCount = ref(0);

const shipOfTheMonth = computed(() => quickStats.value?.shipOfTheMonth || null);

const shipOfTheMonthLabel = computed(() => {
  if (!shipOfTheMonth.value) return t("labels.stats.quickStats.shipOfTheMonth");
  return `${t("labels.stats.quickStats.shipOfTheMonth")}: ${shipOfTheMonth.value}`;
});

const flightReadyPercent = computed(() => {
  if (!shipsCountTotal.value || !flightReadyCount.value) return "";
  return `(${Math.round((flightReadyCount.value / shipsCountTotal.value) * 100)}%)`;
});

// use refs and watch for stats to trigger animation on every page visit
watch(
  () => [
    quickStats.value?.shipsCountYear,
    quickStats.value?.shipsCountTotal,
    quickStats.value?.manufacturerCount,
    quickStats.value?.flightReadyCount,
    quickStats.value?.averagePledgePrice,
    quickStats.value?.largestShip,
    quickStats.value?.smallestShip,
    quickStats.value?.vehiclesCount,
    quickStats.value?.wishlistsCount,
    quickStats.value?.shipOfTheMonthCount,
  ],
  () => {
    setTimeout(() => {
      shipsCountYear.value = quickStats.value?.shipsCountYear || 0;
      shipsCountTotal.value = quickStats.value?.shipsCountTotal || 0;
      manufacturerCount.value = quickStats.value?.manufacturerCount || 0;
      flightReadyCount.value = quickStats.value?.flightReadyCount || 0;
      averagePledgePrice.value = quickStats.value?.averagePledgePrice || 0;
      largestShip.value = quickStats.value?.largestShip || 0;
      smallestShip.value = quickStats.value?.smallestShip || 0;
      vehiclesCount.value = quickStats.value?.vehiclesCount || 0;
      wishlistsCount.value = quickStats.value?.wishlistsCount || 0;
      shipOfTheMonthCount.value = quickStats.value?.shipOfTheMonthCount || 0;
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
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-check-circle fa-4x"
        :value="flightReadyCount"
        :label="t('labels.hangarMetrics.flightReady')"
        :suffix="flightReadyPercent"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-industry fa-4x"
        :value="manufacturerCount"
        :label="t('labels.hangarMetrics.manufacturerCount')"
      />
    </div>
  </div>

  <div class="row">
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-dollar-sign fa-4x"
        :value="averagePledgePrice"
        :label="t('labels.hangarMetrics.averagePledgePrice')"
        :prefix="t('number.units.currency')"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-ruler fa-4x"
        :value="largestShip"
        :label="t('labels.hangarMetrics.largestShip')"
        :suffix="t('number.units.distance')"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-ruler fa-4x"
        :value="smallestShip"
        :label="t('labels.hangarMetrics.smallestShip')"
        :suffix="t('number.units.distance')"
      />
    </div>
  </div>

  <div class="row">
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-warehouse fa-4x"
        :value="vehiclesCount"
        :label="t('labels.stats.quickStats.vehicles')"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-heart fa-4x"
        :value="wishlistsCount"
        :label="t('labels.stats.quickStats.wishlists')"
      />
    </div>
    <div v-if="shipOfTheMonth" class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-star fa-4x"
        :value="shipOfTheMonthCount"
        :label="shipOfTheMonthLabel"
      />
    </div>
  </div>

  <div class="row">
    <div class="col-12 col-md-6">
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.stats.topVehiclesByModel") }}
        </PanelHeading>
        <PanelBody>
          <Chart
            v-if="vehiclesByModelOptions"
            key="vehicles-by-model"
            name="vehicles-by-model"
            :async-status="vehiclesByModelStatus"
            :options="vehiclesByModelOptions"
            tooltip-type="ship"
            type="bar"
          />
        </PanelBody>
      </Panel>
    </div>
    <div class="col-12 col-md-6">
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.stats.shipsOfTheMonth") }}
        </PanelHeading>
        <PanelBody>
          <Chart
            v-if="shipsOfTheMonthOptions"
            key="ships-of-the-month"
            name="ships-of-the-month"
            :options="shipsOfTheMonthOptions"
            :async-status="shipsOfTheMonthStatus"
            tooltip-type="ship"
            type="bar"
          />
        </PanelBody>
      </Panel>
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
    <div class="col-12 col-md-5">
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
    <div class="col-12 col-md-7">
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.stats.vehiclesPerMonth") }}
        </PanelHeading>
        <PanelBody>
          <Chart
            key="vehicles-per-month"
            name="vehicles-per-month"
            :options="vehiclesPerMonthOptions"
            :async-status="vehiclesPerMonthStatus"
            tooltip-type="ship"
            type="column"
          />
        </PanelBody>
      </Panel>
    </div>
  </div>
</template>
