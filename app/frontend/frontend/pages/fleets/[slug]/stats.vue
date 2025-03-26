<script lang="ts">
export default {
  name: "FleetStatsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import StatsPanel from "@/shared/components/StatsPanel/index.vue";
import Panel from "@/shared/components/Panel/index.vue";
import PanelHeading from "@/shared/components/Panel/Heading/index.vue";
import { PanelHeadingLevelEnum } from "@/shared/components/Panel/Heading/types";
import PanelBody from "@/shared/components/Panel/Body/index.vue";
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

const vehiclesByModelLimit = ref(20);

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

// use refs and watch for stats to trigger animation on every page visit
watch(
  () => [
    memberStats.value?.total,
    vehicleStats.value?.total,
    vehicleStats.value?.metrics.totalMinCrew,
    vehicleStats.value?.metrics.totalMaxCrew,
    vehicleStats.value?.metrics.totalCargo,
  ],
  () => {
    setTimeout(() => {
      totalMemberCount.value = memberStats.value?.total || 0;
      totalShipCount.value = vehicleStats.value?.total || 0;
      minCrew.value = vehicleStats.value?.metrics.totalMinCrew || 0;
      maxCrew.value = vehicleStats.value?.metrics.totalMaxCrew || 0;
      totalCargo.value = vehicleStats.value?.metrics.totalCargo || 0;
    }, 200);
  },
  { immediate: true },
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
    <div class="col-12 col-md-6">
      <Panel>
        <PanelHeading :level="PanelHeadingLevelEnum.H2">
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
        <PanelHeading :level="PanelHeadingLevelEnum.H2">
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
        <PanelHeading :level="PanelHeadingLevelEnum.H2">
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
        <PanelHeading :level="PanelHeadingLevelEnum.H2">
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
        <PanelHeading :level="PanelHeadingLevelEnum.H2">
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
