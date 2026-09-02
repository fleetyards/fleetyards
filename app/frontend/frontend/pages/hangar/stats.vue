<script lang="ts">
export default {
  name: "HangarStatsPage",
};
</script>

<script lang="ts" setup>
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import Chart from "@/shared/components/Chart/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import StatsPanel from "@/shared/components/StatsPanel/index.vue";
import MissingRolesPanel from "@/shared/components/MissingRolesPanel/index.vue";
import StatsCsvExportBtn from "@/shared/components/StatsCsvExportBtn/index.vue";
import {
  type StatsChart,
  type StatsMetric,
} from "@/shared/composables/useStatsCsv";
import { useI18n } from "@/shared/composables/useI18n";
import { storeToRefs } from "pinia";
import { useSessionStore } from "@/frontend/stores/session";
import {
  useHangarStats as useHangarStatsQuery,
  useHangarModelsByClassification as useHangarModelsByClassificationQuery,
  useHangarModelsBySize as useHangarModelsBySizeQuery,
  useHangarModelsByManufacturer as useHangarModelsByManufacturerQuery,
  useHangarModelsByProductionStatus as useHangarModelsByProductionStatusQuery,
} from "@/services/fyApi";

const { t } = useI18n();

const sessionStore = useSessionStore();

const { currentUser } = storeToRefs(sessionStore);

const shareTitle = computed(() => t("title.hangar.stats"));

const shareUrl = computed(() => {
  if (!currentUser?.value?.publicHangarUrl) {
    return null;
  }

  return `${currentUser.value.publicHangarUrl}/stats`;
});

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
const totalMoney = ref(0);
const totalCredits = ref(0);
const totalIngameValue = ref(0);
const largestShip = ref(0);
const smallestShip = ref(0);
const averagePledgePrice = ref(0);
const flightReadyCount = ref(0);
const uniqueModelsCount = ref(0);
const manufacturerCount = ref(0);
const wishlistTotalMoney = ref(0);
const wishlistTotalCredits = ref(0);
const wishlistTotal = ref(0);

const uniqueModelsPercent = computed(() => {
  if (!totalCount.value || !uniqueModelsCount.value) return "";
  return `(${Math.round((uniqueModelsCount.value / totalCount.value) * 100)}%)`;
});

const flightReadyPercent = computed(() => {
  if (!totalCount.value || !flightReadyCount.value) return "";
  return `(${Math.round((flightReadyCount.value / totalCount.value) * 100)}%)`;
});

const missingClassifications = computed(
  () => quickStats.value?.metrics.missingClassifications || [],
);

const wishlistPercent = computed(() => {
  if (!totalCount.value || !wishlistTotal.value) return "";
  return `(${Math.round((wishlistTotal.value / totalCount.value) * 100)}%)`;
});

// use refs and watch for stats to trigger animation on every page visit
watch(
  () => [
    quickStats.value?.total,
    quickStats.value?.metrics.totalMinCrew,
    quickStats.value?.metrics.totalMaxCrew,
    quickStats.value?.metrics.totalCargo,
    quickStats.value?.metrics.totalMoney,
    quickStats.value?.metrics.totalCredits,
    quickStats.value?.metrics.totalIngameValue,
    quickStats.value?.metrics.largestShip,
    quickStats.value?.metrics.smallestShip,
    quickStats.value?.metrics.averagePledgePrice,
    quickStats.value?.metrics.flightReadyCount,
    quickStats.value?.metrics.uniqueModelsCount,
    quickStats.value?.metrics.manufacturerCount,
    quickStats.value?.metrics.wishlistTotalMoney,
    quickStats.value?.metrics.wishlistTotalCredits,
    quickStats.value?.wishlistTotal,
  ],
  () => {
    setTimeout(() => {
      totalCount.value = quickStats.value?.total || 0;
      minCrew.value = quickStats.value?.metrics.totalMinCrew || 0;
      maxCrew.value = quickStats.value?.metrics.totalMaxCrew || 0;
      totalCargo.value = quickStats.value?.metrics.totalCargo || 0;
      totalMoney.value = quickStats.value?.metrics.totalMoney || 0;
      totalCredits.value = quickStats.value?.metrics.totalCredits || 0;
      totalIngameValue.value = quickStats.value?.metrics.totalIngameValue || 0;
      largestShip.value = quickStats.value?.metrics.largestShip || 0;
      smallestShip.value = quickStats.value?.metrics.smallestShip || 0;
      averagePledgePrice.value =
        quickStats.value?.metrics.averagePledgePrice || 0;
      flightReadyCount.value = quickStats.value?.metrics.flightReadyCount || 0;
      uniqueModelsCount.value =
        quickStats.value?.metrics.uniqueModelsCount || 0;
      manufacturerCount.value =
        quickStats.value?.metrics.manufacturerCount || 0;
      wishlistTotalMoney.value =
        quickStats.value?.metrics.wishlistTotalMoney || 0;
      wishlistTotalCredits.value =
        quickStats.value?.metrics.wishlistTotalCredits || 0;
      wishlistTotal.value = quickStats.value?.wishlistTotal || 0;
    }, 200);
  },
  { immediate: true },
);

const route = useRoute();

function compactUec(value: number) {
  if (value >= 1_000_000_000) {
    return {
      value: Math.round((value / 1_000_000_000) * 100) / 100,
      suffix: "B aUEC",
    };
  }
  if (value >= 1_000_000) {
    return {
      value: Math.round((value / 1_000_000) * 100) / 100,
      suffix: "M aUEC",
    };
  }
  if (value >= 1_000) {
    return {
      value: Math.round((value / 1_000) * 10) / 10,
      suffix: "K aUEC",
    };
  }
  return { value, suffix: "aUEC" };
}

const totalCreditsCompact = computed(() => compactUec(totalCredits.value));
const totalIngameValueCompact = computed(() =>
  compactUec(totalIngameValue.value),
);
const wishlistTotalCreditsCompact = computed(() =>
  compactUec(wishlistTotalCredits.value),
);

/*
 * Keyed by the same `name` the Chart component gets, so a panel's export button
 * and its chart cannot drift apart and the page-level export is just every
 * value in here.
 */
const csvCharts = computed(() => ({
  "models-by-classification": {
    name: "models-by-classification",
    title: t("labels.stats.modelsByClassification"),
    points: modelsByClassificationOptions.value,
  },
  "models-by-size": {
    name: "models-by-size",
    title: t("labels.stats.modelsBySize"),
    points: modelsBySizeOptions.value,
  },
  "models-by-production-status": {
    name: "models-by-production-status",
    title: t("labels.stats.modelsByProductionStatus"),
    points: modelsByProductionStatusOptions.value,
  },
  "models-by-manufacturer": {
    name: "models-by-manufacturer",
    title: t("labels.stats.modelsByManufacturer"),
    points: modelsByManufacturerOptions.value,
  },
}));

const csvChartList = computed<StatsChart[]>(() =>
  Object.values(csvCharts.value),
);

/*
 * Read off the query, not off the animated refs above - those hold 0 for the
 * first 200ms of every visit, and an export is not an animation. The aUEC
 * figures go out at full precision too; `compactUec` is for a panel that has one
 * line to spend, not for a spreadsheet column.
 */
const csvMetrics = computed<StatsMetric[]>(() => [
  {
    label: t("labels.stats.quickStats.totalShips"),
    value: quickStats.value?.total,
  },
  {
    label: t("labels.hangarMetrics.uniqueModels"),
    value: quickStats.value?.metrics.uniqueModelsCount,
  },
  {
    label: t("labels.hangarMetrics.flightReady"),
    value: quickStats.value?.metrics.flightReadyCount,
  },
  {
    label: t("labels.hangarMetrics.totalCargo"),
    value: quickStats.value?.metrics.totalCargo,
  },
  {
    label: t("labels.hangarMetrics.totalMoney"),
    value: quickStats.value?.metrics.totalMoney,
  },
  {
    label: t("labels.hangarMetrics.totalCredits"),
    value: quickStats.value?.metrics.totalCredits,
  },
  {
    label: t("labels.hangarMetrics.totalIngameValue"),
    value: quickStats.value?.metrics.totalIngameValue,
  },
  {
    label: t("labels.hangarMetrics.averagePledgePrice"),
    value: quickStats.value?.metrics.averagePledgePrice,
  },
  {
    label: t("labels.hangarMetrics.manufacturerCount"),
    value: quickStats.value?.metrics.manufacturerCount,
  },
  {
    label: t("labels.hangarMetrics.largestShip"),
    value: quickStats.value?.metrics.largestShip,
  },
  {
    label: t("labels.hangarMetrics.smallestShip"),
    value: quickStats.value?.metrics.smallestShip,
  },
  {
    label: t("labels.hangarMetrics.wishlistTotalMoney"),
    value: quickStats.value?.metrics.wishlistTotalMoney,
  },
  {
    label: t("labels.hangarMetrics.wishlistTotalCredits"),
    value: quickStats.value?.metrics.wishlistTotalCredits,
  },
  {
    label: t("labels.hangarMetrics.totalMinCrew"),
    value: quickStats.value?.metrics.totalMinCrew,
  },
  {
    label: t("labels.hangarMetrics.totalMaxCrew"),
    value: quickStats.value?.metrics.totalMaxCrew,
  },
  {
    label: t("labels.wishlist"),
    value: quickStats.value?.wishlistTotal,
  },
]);
</script>

<template>
  <BreadCrumbs
    :crumbs="[{ to: { name: 'hangar' }, label: t('nav.hangar.index') }]"
  />
  <Heading size="hero" hero>{{ t(`headlines.${route.meta.title}`) }}</Heading>

  <Teleport to="#header-right">
    <ShareBtn
      :size="BtnSizesEnum.MD"
      v-if="currentUser && currentUser.publicHangarStats && shareUrl"
      :url="shareUrl"
      :title="shareTitle"
      no-label
    />
    <StatsCsvExportBtn
      scope="hangar"
      :charts="csvChartList"
      :metrics="csvMetrics"
      :size="BtnSizesEnum.MD"
    />
  </Teleport>

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
        icon="fa-duotone fa-dollar-sign fa-4x"
        :value="totalMoney"
        :label="t('labels.hangarMetrics.totalMoney')"
        :prefix="t('number.units.currency')"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-coins fa-4x"
        :value="totalCreditsCompact.value"
        :label="t('labels.hangarMetrics.totalCredits')"
        :suffix="totalCreditsCompact.suffix"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-coins fa-4x"
        :value="totalIngameValueCompact.value"
        :label="t('labels.hangarMetrics.totalIngameValue')"
        :suffix="totalIngameValueCompact.suffix"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-dollar-sign fa-4x"
        :value="averagePledgePrice"
        :label="t('labels.hangarMetrics.averagePledgePrice')"
        :prefix="t('number.units.currency')"
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
  </div>

  <div class="row">
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-dollar-sign fa-4x"
        :value="wishlistTotalMoney"
        :label="t('labels.hangarMetrics.wishlistTotalMoney')"
        :prefix="t('number.units.currency')"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-coins fa-4x"
        :value="wishlistTotalCreditsCompact.value"
        :label="t('labels.hangarMetrics.wishlistTotalCredits')"
        :suffix="wishlistTotalCreditsCompact.suffix"
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
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-user fa-4x"
        :value="maxCrew"
        :label="t('labels.hangarMetrics.totalMaxCrew')"
        :suffix="t('number.units.people', { count: maxCrew })"
      />
    </div>
  </div>

  <div class="row">
    <div v-if="missingClassifications.length" class="col-12 col-sm-6 col-lg-3">
      <MissingRolesPanel :roles="missingClassifications" />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-heart fa-4x"
        :value="wishlistTotal"
        :label="t('labels.wishlist')"
        :suffix="wishlistPercent"
      />
    </div>
  </div>

  <div class="row">
    <div class="col-12 col-md-6">
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.stats.modelsByClassification") }}
          <template #actions>
            <StatsCsvExportBtn
              scope="hangar"
              :chart="csvCharts['models-by-classification']"
            />
          </template>
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
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.stats.modelsBySize") }}
          <template #actions>
            <StatsCsvExportBtn
              scope="hangar"
              :chart="csvCharts['models-by-size']"
            />
          </template>
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
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.stats.modelsByProductionStatus") }}
          <template #actions>
            <StatsCsvExportBtn
              scope="hangar"
              :chart="csvCharts['models-by-production-status']"
            />
          </template>
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
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.stats.modelsByManufacturer") }}
          <template #actions>
            <StatsCsvExportBtn
              scope="hangar"
              :chart="csvCharts['models-by-manufacturer']"
            />
          </template>
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
