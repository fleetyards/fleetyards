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
import StatsCsvExportBtn from "@/shared/components/StatsCsvExportBtn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  type StatsChart,
  type StatsMetric,
} from "@/shared/composables/useStatsCsv";
import { useI18n } from "@/shared/composables/useI18n";
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
  useTrendingShips as useTrendingShipsQuery,
  useMostWishlisted as useMostWishlistedQuery,
  usePriceMovers as usePriceMoversQuery,
} from "@/services/fyApi";

const { t } = useI18n();

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

const { data: trendingShipsOptions, ...trendingShipsStatus } =
  useTrendingShipsQuery();

const { data: mostWishlistedOptions, ...mostWishlistedStatus } =
  useMostWishlistedQuery();
const { data: priceMoversOptions, ...priceMoversStatus } =
  usePriceMoversQuery();

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

/*
 * Keyed by the same `name` the Chart component gets, so a panel's export button
 * and its chart cannot drift apart and the page-level export is just every
 * value in here.
 */
const csvCharts = computed(() => ({
  "trending-ships": {
    name: "trending-ships",
    title: t("labels.stats.trendingShips"),
    points: trendingShipsOptions.value,
  },
  "most-wishlisted": {
    name: "most-wishlisted",
    title: t("labels.stats.mostWishlisted"),
    points: mostWishlistedOptions.value,
  },
  "price-movers": {
    name: "price-movers",
    title: t("labels.stats.priceMovers"),
    points: priceMoversOptions.value,
  },
  "vehicles-by-model": {
    name: "vehicles-by-model",
    title: t("labels.stats.topVehiclesByModel"),
    points: vehiclesByModelOptions.value,
  },
  "ships-of-the-month": {
    name: "ships-of-the-month",
    title: t("labels.stats.shipsOfTheMonth"),
    points: shipsOfTheMonthOptions.value,
  },
  "models-by-classification": {
    name: "models-by-classification",
    title: t("labels.stats.modelsByClassification"),
    points: modelsByClassification.value,
  },
  "models-by-size": {
    name: "models-by-size",
    title: t("labels.stats.modelsBySize"),
    points: modelsBySize.value,
  },
  "models-by-production-status": {
    name: "models-by-production-status",
    title: t("labels.stats.modelsByProductionStatus"),
    points: modelsByProductionStatus.value,
  },
  "models-per-month": {
    name: "models-per-month",
    title: t("labels.stats.modelsPerMonth"),
    points: modelsPerMonth.value,
  },
  "models-by-manufacturer": {
    name: "models-by-manufacturer",
    title: t("labels.stats.modelsByManufacturer"),
    points: modelsByManufacturer.value,
  },
  "vehicles-per-month": {
    name: "vehicles-per-month",
    title: t("labels.stats.vehiclesPerMonth"),
    points: vehiclesPerMonthOptions.value,
  },
}));

const csvChartList = computed<StatsChart[]>(() =>
  Object.values(csvCharts.value),
);

// Read off the query, not off the animated refs above - those hold 0 for the
// first 200ms of every visit, and an export is not an animation.
const csvMetrics = computed<StatsMetric[]>(() => [
  {
    label: t("labels.stats.quickStats.newShips", {
      year: String(new Date().getFullYear()),
    }),
    value: quickStats.value?.shipsCountYear,
  },
  {
    label: t("labels.stats.quickStats.totalShips"),
    value: quickStats.value?.shipsCountTotal,
  },
  {
    label: t("labels.hangarMetrics.flightReady"),
    value: quickStats.value?.flightReadyCount,
  },
  {
    label: t("labels.hangarMetrics.manufacturerCount"),
    value: quickStats.value?.manufacturerCount,
  },
  {
    label: t("labels.hangarMetrics.averagePledgePrice"),
    value: quickStats.value?.averagePledgePrice,
  },
  {
    label: t("labels.hangarMetrics.largestShip"),
    value: quickStats.value?.largestShip,
  },
  {
    label: t("labels.hangarMetrics.smallestShip"),
    value: quickStats.value?.smallestShip,
  },
  {
    label: t("labels.stats.quickStats.vehicles"),
    value: quickStats.value?.vehiclesCount,
  },
  {
    label: t("labels.stats.quickStats.wishlists"),
    value: quickStats.value?.wishlistsCount,
  },
  {
    label: shipOfTheMonthLabel.value,
    value: quickStats.value?.shipOfTheMonthCount,
  },
]);
</script>

<template>
  <Teleport to="#header-left">
    <Heading hidden>{{ t(`headlines.${route.meta.title}`) }}</Heading>
  </Teleport>

  <Teleport to="#header-right">
    <StatsCsvExportBtn
      scope="stats"
      :charts="csvChartList"
      :metrics="csvMetrics"
      :size="BtnSizesEnum.MD"
    />
  </Teleport>

  <div class="row" data-test="stats">
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-rocket-launch fa-4x"
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
        icon="fa-duotone fa-rocket fa-4x"
        :value="shipsCountTotal"
        :label="t('labels.stats.quickStats.totalShips')"
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
        icon="fa-duotone fa-industry fa-4x"
        :value="manufacturerCount"
        :label="t('labels.hangarMetrics.manufacturerCount')"
      />
    </div>
  </div>

  <div class="row">
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-dollar-sign fa-4x"
        :value="averagePledgePrice"
        :label="t('labels.hangarMetrics.averagePledgePrice')"
        :prefix="t('number.units.currency')"
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
  </div>

  <div class="row">
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-warehouse fa-4x"
        :value="vehiclesCount"
        :label="t('labels.stats.quickStats.vehicles')"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-heart fa-4x"
        :value="wishlistsCount"
        :label="t('labels.stats.quickStats.wishlists')"
      />
    </div>
    <div v-if="shipOfTheMonth" class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-star fa-4x"
        :value="shipOfTheMonthCount"
        :label="shipOfTheMonthLabel"
      />
    </div>
  </div>

  <div class="row">
    <div class="col-12">
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.stats.trendingShips") }}
          <template #actions>
            <StatsCsvExportBtn
              scope="stats"
              :chart="csvCharts['trending-ships']"
            />
          </template>
        </PanelHeading>
        <PanelBody>
          <Chart
            v-if="trendingShipsOptions"
            key="trending-ships"
            name="trending-ships"
            :async-status="trendingShipsStatus"
            :options="trendingShipsOptions"
            tooltip-type="ship"
            type="bar"
          />
        </PanelBody>
      </Panel>
    </div>
  </div>

  <div class="row">
    <div class="col-12">
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.stats.priceMovers") }}
          <template #actions>
            <StatsCsvExportBtn
              scope="stats"
              :chart="csvCharts['price-movers']"
            />
          </template>
        </PanelHeading>
        <PanelBody>
          <Chart
            v-if="priceMoversOptions"
            key="price-movers"
            name="price-movers"
            :async-status="priceMoversStatus"
            :options="priceMoversOptions"
            type="bar"
          />
        </PanelBody>
      </Panel>
    </div>
  </div>

  <div class="row">
    <div class="col-12">
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.stats.mostWishlisted") }}
          <template #actions>
            <StatsCsvExportBtn
              scope="stats"
              :chart="csvCharts['most-wishlisted']"
            />
          </template>
        </PanelHeading>
        <PanelBody>
          <Chart
            v-if="mostWishlistedOptions"
            key="most-wishlisted"
            name="most-wishlisted"
            :async-status="mostWishlistedStatus"
            :options="mostWishlistedOptions"
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
          {{ t("labels.stats.topVehiclesByModel") }}
          <template #actions>
            <StatsCsvExportBtn
              scope="stats"
              :chart="csvCharts['vehicles-by-model']"
            />
          </template>
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
          <template #actions>
            <StatsCsvExportBtn
              scope="stats"
              :chart="csvCharts['ships-of-the-month']"
            />
          </template>
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
          <template #actions>
            <StatsCsvExportBtn
              scope="stats"
              :chart="csvCharts['models-by-classification']"
            />
          </template>
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
          <template #actions>
            <StatsCsvExportBtn
              scope="stats"
              :chart="csvCharts['models-by-size']"
            />
          </template>
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
          <template #actions>
            <StatsCsvExportBtn
              scope="stats"
              :chart="csvCharts['models-by-production-status']"
            />
          </template>
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
          <template #actions>
            <StatsCsvExportBtn
              scope="stats"
              :chart="csvCharts['models-per-month']"
            />
          </template>
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
          <template #actions>
            <StatsCsvExportBtn
              scope="stats"
              :chart="csvCharts['models-by-manufacturer']"
            />
          </template>
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
          <template #actions>
            <StatsCsvExportBtn
              scope="stats"
              :chart="csvCharts['vehicles-per-month']"
            />
          </template>
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
