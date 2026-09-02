<script lang="ts">
export default {
  name: "FleetStats",
};
</script>

<script lang="ts" setup>
import StatsPanel from "@/shared/components/StatsPanel/index.vue";
import MissingRolesPanel from "@/shared/components/MissingRolesPanel/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Chart from "@/shared/components/Chart/index.vue";
import StatsCsvExportBtn from "@/shared/components/StatsCsvExportBtn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  type StatsChart,
  type StatsMetric,
} from "@/shared/composables/useStatsCsv";
import {
  useFleetVehiclesStats as useFleetVehiclesStatsQuery,
  useFleetMembersStats as useFleetMembersStatsQuery,
  useFleetModelsByClassification as useFleetModelsByClassificationQuery,
  useFleetModelsBySize as useFleetModelsBySizeQuery,
  useFleetModelsByProductionStatus as useFleetModelsByProductionStatusQuery,
  useFleetModelsByManufacturer as useFleetModelsByManufacturerQuery,
  useFleetVehiclesByModel as useFleetVehiclesByModelQuery,
  type Fleet,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t } = useI18n();

const vehiclesByModelLimit = ref(10);

const { data: vehicleStats } = useFleetVehiclesStatsQuery(props.fleet.slug);

const { data: memberStats, ...memberStatsStatus } = useFleetMembersStatsQuery(
  props.fleet.slug,
);

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
  () => vehicleStats.value?.metrics.missingClassifications || [],
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

const crewDeficit = computed(() => {
  if (!minCrew.value || !totalMemberCount.value) return 0;
  return Math.abs(minCrew.value - totalMemberCount.value);
});

const crewDeltaLabel = (crew: number, members: number) => {
  if (!crew || !members) return t("labels.stats.crewDeficit");
  return crew > members
    ? t("labels.stats.crewDeficit")
    : t("labels.stats.crewSurplus");
};

const crewDeficitLabel = computed(() =>
  crewDeltaLabel(minCrew.value, totalMemberCount.value),
);

const crewDeficitIcon = computed(() => {
  if (minCrew.value > totalMemberCount.value)
    return "fa-duotone fa-user-minus fa-4x";
  return "fa-duotone fa-user-plus fa-4x";
});

const membersByRole = computed(() => {
  const byRole = memberStats.value?.metrics?.membersByRole;
  if (!byRole) return null;
  return Object.entries(byRole).map(([name, count]) => ({
    name,
    y: count,
    selected: false,
    sliced: false,
  }));
});

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

const csvScope = computed(() => `${props.fleet.slug}-fleet`);

/*
 * Keyed by the same `name` the Chart component gets, so a panel's export button
 * and its chart cannot drift apart and the page-level export is just every
 * value in here.
 */
const csvCharts = computed(() => ({
  "vehicles-by-model": {
    name: "vehicles-by-model",
    title: t("labels.stats.vehiclesByModel", {
      limit: vehiclesByModelLimit.value,
    }),
    points: vehiclesByModelOptions.value,
  },
  "members-by-role": {
    name: "members-by-role",
    title: t("labels.stats.membersByRole"),
    points: membersByRole.value,
  },
  "models-by-classification": {
    name: "models-by-classification",
    title: t("labels.stats.modelsByClassification"),
    points: modelsByClassificationOptions.value,
  },
  "models-by-manufacturer": {
    name: "models-by-manufacturer",
    title: t("labels.stats.modelsByManufacturer"),
    points: modelsByManufacturerOptions.value,
  },
  "models-by-production-status": {
    name: "models-by-production-status",
    title: t("labels.stats.modelsByProductionStatus"),
    points: modelsByProductionStatusOptions.value,
  },
  "models-by-size": {
    name: "models-by-size",
    title: t("labels.stats.modelsBySize"),
    points: modelsBySizeOptions.value,
  },
}));

const csvChartList = computed<StatsChart[]>(() =>
  Object.values(csvCharts.value),
);

/*
 * Read off the queries, not off the animated refs above - those hold 0 for the
 * first 200ms of every visit, and an export is not an animation. The aUEC
 * figures go out at full precision too; `compactUec` is for a panel that has one
 * line to spend, not for a spreadsheet column.
 */
const csvMetrics = computed<StatsMetric[]>(() => {
  const metrics = vehicleStats.value?.metrics;
  const members = memberStats.value?.total;
  const crew = metrics?.totalMinCrew;

  return [
    { label: t("labels.stats.quickStats.totalMembers"), value: members },
    { label: t("labels.hangarMetrics.totalMinCrew"), value: crew },
    {
      label: t("labels.hangarMetrics.totalMaxCrew"),
      value: metrics?.totalMaxCrew,
    },
    {
      label: crewDeltaLabel(crew || 0, members || 0),
      value: crew && members ? Math.abs(crew - members) : undefined,
    },
    {
      label: t("labels.stats.quickStats.totalShips"),
      value: vehicleStats.value?.total,
    },
    {
      label: t("labels.hangarMetrics.uniqueModels"),
      value: metrics?.uniqueModelsCount,
    },
    {
      label: t("labels.hangarMetrics.flightReady"),
      value: metrics?.flightReadyCount,
    },
    { label: t("labels.hangarMetrics.totalMoney"), value: metrics?.totalMoney },
    {
      label: t("labels.hangarMetrics.totalCredits"),
      value: metrics?.totalCredits,
    },
    {
      label: t("labels.hangarMetrics.totalIngameValue"),
      value: metrics?.totalIngameValue,
    },
    {
      label: t("labels.hangarMetrics.averagePledgePrice"),
      value: metrics?.averagePledgePrice,
    },
    {
      label: t("labels.hangarMetrics.manufacturerCount"),
      value: metrics?.manufacturerCount,
    },
    {
      label: t("labels.hangarMetrics.largestShip"),
      value: metrics?.largestShip,
    },
    {
      label: t("labels.hangarMetrics.smallestShip"),
      value: metrics?.smallestShip,
    },
    { label: t("labels.hangarMetrics.totalCargo"), value: metrics?.totalCargo },
  ];
});
</script>

<template>
  <Teleport to="#header-right">
    <StatsCsvExportBtn
      :scope="csvScope"
      :charts="csvChartList"
      :metrics="csvMetrics"
      :size="BtnSizesEnum.MD"
    />
  </Teleport>

  <div class="row">
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-users-viewfinder fa-4x"
        :value="totalMemberCount"
        :label="t('labels.stats.quickStats.totalMembers')"
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
        icon="fa-duotone fa-users fa-4x"
        :value="maxCrew"
        :label="t('labels.hangarMetrics.totalMaxCrew')"
        :suffix="t('number.units.people', { count: maxCrew })"
      />
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        :icon="crewDeficitIcon"
        :value="crewDeficit"
        :label="crewDeficitLabel"
        :suffix="t('number.units.people', { count: crewDeficit })"
      />
    </div>
  </div>
  <div class="row">
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-rocket fa-4x"
        :value="totalShipCount"
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
    <div class="col-12 col-sm-6 col-lg-3">
      <StatsPanel
        icon="fa-duotone fa-box-taped fa-4x"
        :value="totalCargo"
        :label="t('labels.hangarMetrics.totalCargo')"
        :suffix="t('number.units.cargo')"
      />
    </div>
  </div>

  <div v-if="missingClassifications.length" class="row">
    <div class="col-12 col-sm-6 col-lg-3">
      <MissingRolesPanel :roles="missingClassifications" />
    </div>
  </div>

  <div class="row">
    <div class="col-12 col-md-7">
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{
            t("labels.stats.vehiclesByModel", {
              limit: vehiclesByModelLimit,
            })
          }}
          <template #actions>
            <StatsCsvExportBtn
              :scope="csvScope"
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
    <div class="col-12 col-md-5">
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.stats.membersByRole") }}
          <template #actions>
            <StatsCsvExportBtn
              :scope="csvScope"
              :chart="csvCharts['members-by-role']"
            />
          </template>
        </PanelHeading>
        <PanelBody>
          <Chart
            v-if="membersByRole"
            key="members-by-role"
            name="members-by-role"
            :options="membersByRole"
            :async-status="memberStatsStatus"
            tooltip-type="user-pie"
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
          {{ t("labels.stats.modelsByClassification") }}
          <template #actions>
            <StatsCsvExportBtn
              :scope="csvScope"
              :chart="csvCharts['models-by-classification']"
            />
          </template>
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
    <div class="col-12 col-md-7">
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.stats.modelsByManufacturer") }}
          <template #actions>
            <StatsCsvExportBtn
              :scope="csvScope"
              :chart="csvCharts['models-by-manufacturer']"
            />
          </template>
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
          {{ t("labels.stats.modelsByProductionStatus") }}
          <template #actions>
            <StatsCsvExportBtn
              :scope="csvScope"
              :chart="csvCharts['models-by-production-status']"
            />
          </template>
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
    <div class="col-12 col-md-6">
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.stats.modelsBySize") }}
          <template #actions>
            <StatsCsvExportBtn
              :scope="csvScope"
              :chart="csvCharts['models-by-size']"
            />
          </template>
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
</template>
