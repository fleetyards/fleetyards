<script lang="ts">
export default {
  name: "FleetStatsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import StatsPanel from "@/shared/components/StatsPanel/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Chart from "@/shared/components/Chart/index.vue";
import {
  useFleetVehiclesStats as useFleetVehiclesStatsQuery,
  useFleetMembersStats as useFleetMembersStatsQuery,
  useFleetModelsByClassification as useFleetModelsByClassificationQuery,
  useFleetModelsBySize as useFleetModelsBySizeQuery,
  useFleetModelsByProductionStatus as useFleetModelsByProductionStatusQuery,
  useFleetModelsByManufacturer as useFleetModelsByManufacturerQuery,
  useFleetVehiclesByModel as useFleetVehiclesByModelQuery,
  type Fleet,
  type FleetMember,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();

const route = useRoute();

const vehiclesByModelLimit = ref(10);

const { data: vehicleStats } = useFleetVehiclesStatsQuery(props.fleet.slug);

const { data: memberStats } = useFleetMembersStatsQuery(props.fleet.slug);

const { data: modelsByClassificationOptions, ...modelsByClassificationStatus } =
  useFleetModelsByClassificationQuery(props.fleet.slug);

const { data: modelsBySizeOptions, ...modelsBySizeStatus } =
  useFleetModelsBySizeQuery(props.fleet.slug);

const {
  data: modelsByProductionStatusOptions,
  ...modelsByProductionStatusStatus
} = useFleetModelsByProductionStatusQuery(props.fleet.slug);

const { data: modelsByManufacturerOptions, ...modelsByManufacturerStatus } =
  useFleetModelsByManufacturerQuery(props.fleet.slug);

const { data: vehiclesByModelOptions, ...vehiclesByModelStatus } =
  useFleetVehiclesByModelQuery(props.fleet.slug);

const totalMemberCount = ref(0);
const totalShipCount = ref(0);
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

const missingClassifications = computed(
  () =>
    vehicleStats.value?.metrics.missingClassifications
      ?.map((c: string) =>
        c.replace(/_/g, " ").replace(/\b\w/g, (l) => l.toUpperCase()),
      )
      .join(", ") || "",
);

// use refs and watch for stats to trigger animation on every page visit
watch(
  () => [
    memberStats.value?.total,
    vehicleStats.value?.total,
    vehicleStats.value?.metrics.totalMinCrew,
    vehicleStats.value?.metrics.totalMaxCrew,
    vehicleStats.value?.metrics.totalCargo,
    vehicleStats.value?.metrics.totalMoney,
    vehicleStats.value?.metrics.totalCredits,
    vehicleStats.value?.metrics.totalIngameValue,
    vehicleStats.value?.metrics.largestShip,
    vehicleStats.value?.metrics.smallestShip,
    vehicleStats.value?.metrics.averagePledgePrice,
    vehicleStats.value?.metrics.flightReadyCount,
    vehicleStats.value?.metrics.uniqueModelsCount,
    vehicleStats.value?.metrics.manufacturerCount,
  ],
  () => {
    setTimeout(() => {
      totalMemberCount.value = memberStats.value?.total || 0;
      totalShipCount.value = vehicleStats.value?.total || 0;
      minCrew.value = vehicleStats.value?.metrics.totalMinCrew || 0;
      maxCrew.value = vehicleStats.value?.metrics.totalMaxCrew || 0;
      totalCargo.value = vehicleStats.value?.metrics.totalCargo || 0;
      totalMoney.value = vehicleStats.value?.metrics.totalMoney || 0;
      totalCredits.value = vehicleStats.value?.metrics.totalCredits || 0;
      totalIngameValue.value =
        vehicleStats.value?.metrics.totalIngameValue || 0;
      largestShip.value = vehicleStats.value?.metrics.largestShip || 0;
      smallestShip.value = vehicleStats.value?.metrics.smallestShip || 0;
      averagePledgePrice.value =
        vehicleStats.value?.metrics.averagePledgePrice || 0;
      flightReadyCount.value =
        vehicleStats.value?.metrics.flightReadyCount || 0;
      uniqueModelsCount.value =
        vehicleStats.value?.metrics.uniqueModelsCount || 0;
      manufacturerCount.value =
        vehicleStats.value?.metrics.manufacturerCount || 0;
    }, 200);
  },
  { immediate: true },
);

const uniqueModelsPercent = computed(() => {
  if (!totalShipCount.value || !uniqueModelsCount.value) return "";
  return `(${Math.round((uniqueModelsCount.value / totalShipCount.value) * 100)}%)`;
});

const flightReadyPercent = computed(() => {
  if (!totalShipCount.value || !flightReadyCount.value) return "";
  return `(${Math.round((flightReadyCount.value / totalShipCount.value) * 100)}%)`;
});

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

const crumbs = computed(() => {
  if (!props.fleet) {
    return [];
  }

  return [
    {
      to: {
        name: "fleet",
        params: {
          slug: props.fleet.slug,
        },
      },
      label: props.fleet.name,
    },
  ];
});
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />
  <Heading>{{ t(`headlines.${route.meta.title}`) }}</Heading>
  <div class="row">
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-users-viewfinder fa-4x"
        :value="totalMemberCount"
        :label="t('labels.stats.quickStats.totalMembers')"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fad fa-rocket fa-4x"
        :value="totalShipCount"
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
        icon="fad fa-users fa-4x"
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
  <div class="row">
    <div class="col-12 col-md-6">
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{
            t("labels.stats.vehiclesByModel", {
              limit: vehiclesByModelLimit,
            })
          }}
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
  </div>
</template>
