<script lang="ts">
export default {
  name: "HangarStatsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Chart from "@/shared/components/Chart/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
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
  () =>
    quickStats.value?.metrics.missingClassifications
      ?.map((c: string) =>
        c.replace(/_/g, " ").replace(/\b\w/g, (l) => l.toUpperCase()),
      )
      .join(", ") || "",
);

const wishlistToHangarRatio = computed(() => {
  if (!totalCount.value) return "";
  return `${wishlistTotal.value} / ${totalCount.value}`;
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
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-dollar-sign fa-4x"
        :value="totalMoney"
        :label="t('labels.hangarMetrics.totalMoney')"
        :prefix="t('number.units.currency')"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-coins fa-4x"
        :value="totalCreditsCompact.value"
        :label="t('labels.hangarMetrics.totalCredits')"
        :suffix="totalCreditsCompact.suffix"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-coins fa-4x"
        :value="totalIngameValueCompact.value"
        :label="t('labels.hangarMetrics.totalIngameValue')"
        :suffix="totalIngameValueCompact.suffix"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-dollar-sign fa-4x"
        :value="averagePledgePrice"
        :label="t('labels.hangarMetrics.averagePledgePrice')"
        :prefix="t('number.units.currency')"
      />
    </div>
  </div>

  <div class="row">
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-industry fa-4x"
        :value="manufacturerCount"
        :label="t('labels.hangarMetrics.manufacturerCount')"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-fingerprint fa-4x"
        :value="uniqueModelsCount"
        :label="t('labels.hangarMetrics.uniqueModels')"
        :suffix="uniqueModelsPercent"
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
        icon="fad fa-ruler fa-4x"
        :value="largestShip"
        :label="t('labels.hangarMetrics.largestShip')"
        :suffix="t('number.units.distance')"
      />
    </div>
  </div>

  <div class="row">
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-ruler fa-4x"
        :value="smallestShip"
        :label="t('labels.hangarMetrics.smallestShip')"
        :suffix="t('number.units.distance')"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-dollar-sign fa-4x"
        :value="wishlistTotalMoney"
        :label="t('labels.hangarMetrics.wishlistTotalMoney')"
        :prefix="t('number.units.currency')"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-coins fa-4x"
        :value="wishlistTotalCreditsCompact.value"
        :label="t('labels.hangarMetrics.wishlistTotalCredits')"
        :suffix="wishlistTotalCreditsCompact.suffix"
      />
    </div>
  </div>

  <div v-if="missingClassifications" class="row">
    <div class="col-12 col-sm-6">
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.hangarMetrics.missingClassifications") }}
        </PanelHeading>
        <PanelBody>
          <p>{{ missingClassifications }}</p>
        </PanelBody>
      </Panel>
    </div>
    <div class="col-12 col-sm-6">
      <StatsPanel
        icon="fad fa-heart fa-4x"
        :value="wishlistTotal"
        :label="t('labels.hangar')"
        :suffix="wishlistToHangarRatio"
        :outer-spacing="false"
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
