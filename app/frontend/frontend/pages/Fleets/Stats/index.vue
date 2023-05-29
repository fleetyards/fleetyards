<template>
  <section class="container stats">
    <div v-if="fleet" class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12">
            <BreadCrumbs :crumbs="crumbs" />
            <h1>
              {{ t("headlines.fleets.stats") }}
            </h1>
          </div>
        </div>
        <div class="row">
          <div class="col-12 col-sm-6 col-lg-3">
            <Panel variant="primary">
              <div class="panel-box">
                <div class="panel-box-icon">
                  <i class="fad fa-user fa-4x" />
                </div>
                <div class="panel-box-text">
                  {{ totalMemberCount }}
                  <div class="panel-box-text-info">
                    {{ t("labels.stats.quickStats.totalMembers") }}
                  </div>
                </div>
              </div>
            </Panel>
          </div>
          <div class="col-12 col-sm-6 col-lg-3">
            <Panel variant="primary">
              <div class="panel-box">
                <div class="panel-box-icon">
                  <i class="fad fa-rocket fa-4x" />
                </div>
                <div class="panel-box-text">
                  {{ totalShipCount }}
                  <div class="panel-box-text-info">
                    {{ t("labels.stats.quickStats.totalShips") }}
                  </div>
                </div>
              </div>
            </Panel>
          </div>
          <div class="col-12 col-sm-6 col-lg-3">
            <Panel variant="primary">
              <div class="panel-box">
                <div class="panel-box-icon">
                  <i class="fad fa-user fa-4x" />
                </div>
                <div class="panel-box-text">
                  {{ minCrew }}
                  <div class="panel-box-text-info">
                    {{ t("labels.hangarMetrics.totalMinCrew") }}
                  </div>
                </div>
              </div>
            </Panel>
          </div>
          <div class="col-12 col-sm-6 col-lg-3">
            <Panel variant="primary">
              <div class="panel-box">
                <div class="panel-box-icon">
                  <i class="fad fa-users fa-4x" />
                </div>
                <div class="panel-box-text">
                  {{ maxCrew }}
                  <div class="panel-box-text-info">
                    {{ t("labels.hangarMetrics.totalMaxCrew") }}
                  </div>
                </div>
              </div>
            </Panel>
          </div>
          <div class="col-12 col-sm-6 col-lg-3">
            <Panel variant="primary">
              <div class="panel-box">
                <div class="panel-box-icon">
                  <i class="fad fa-box-open fa-4x" />
                </div>
                <div class="panel-box-text">
                  {{ totalCargo }}
                  <div class="panel-box-text-info">
                    {{ t("labels.hangarMetrics.totalCargo") }}
                  </div>
                </div>
              </div>
            </Panel>
          </div>
        </div>
        <div class="row">
          <div class="col-12 col-md-6">
            <Panel>
              <div class="panel-heading">
                <h2 class="panel-title">
                  {{ t("labels.stats.modelsByClassification") }}
                </h2>
              </div>
              <Chart
                key="models-by-classification"
                :load-data="loadModelsByClassification"
                tooltip-type="ship-pie"
                type="pie"
              />
            </Panel>
          </div>
          <div class="col-12 col-md-6">
            <Panel>
              <div class="panel-heading">
                <h2 class="panel-title">
                  {{ t("labels.stats.modelsBySize") }}
                </h2>
              </div>
              <Chart
                key="models-by-size"
                :load-data="loadModelsBySize"
                tooltip-type="ship-pie"
                type="pie"
              />
            </Panel>
          </div>
        </div>
        <div class="row">
          <div class="col-12 col-md-5">
            <Panel>
              <div class="panel-heading">
                <h2 class="panel-title">
                  {{ t("labels.stats.modelsByProductionStatus") }}
                </h2>
              </div>
              <Chart
                key="models-by-production-status"
                :load-data="loadModelsByProductionStatus"
                tooltip-type="ship-pie"
                type="pie"
              />
            </Panel>
          </div>
          <div class="col-12 col-md-7">
            <Panel>
              <div class="panel-heading">
                <h2 class="panel-title">
                  {{ t("labels.stats.modelsByManufacturer") }}
                </h2>
              </div>
              <Chart
                key="models-by-manufacturer"
                :load-data="loadModelsByManufacturer"
                tooltip-type="ship-pie"
                type="pie"
              />
            </Panel>
          </div>
        </div>
        <div class="row">
          <div class="col-12 col-md-6">
            <Panel>
              <div class="panel-heading">
                <h2 class="panel-title">
                  {{
                    t("labels.stats.vehiclesByModel", {
                      limit: String(vehiclesByModelLimit),
                    })
                  }}
                </h2>
              </div>
              <Chart
                key="vehicles-by-model"
                :load-data="loadVehiclesByModel"
                tooltip-type="ship"
                type="bar"
              />
            </Panel>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router/composables";
import Chart from "@/frontend/core/components/Chart/index.vue";
import Panel from "@/frontend/core/components/Panel/index.vue";
import { fleetRouteGuard } from "@/frontend/utils/RouteGuards/Fleets";
import fleetsCollection from "@/frontend/api/collections/Fleets";
import vehiclesCollection from "@/frontend/api/collections/FleetVehicles";
import membersCollection from "@/frontend/api/collections/FleetMembers";
import BreadCrumbs from "@/frontend/core/components/BreadCrumbs/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useMetaInfo } from "@/frontend/composables/useMetaInfo";

const { t, toNumber } = useI18n();

const vehiclesByModelLimit = 20;

const fleet = computed(() => fleetsCollection.record);

const route = useRoute();

const slug = computed(() => route.params.slug);

const vehicleStats = computed(() => vehiclesCollection.stats);

const memberStats = computed(() => membersCollection.stats);

const totalMemberCount = computed(() => {
  if (!memberStats.value) {
    return 0;
  }

  return memberStats.value.total;
});

const totalShipCount = computed(() => {
  if (!vehicleStats.value) {
    return 0;
  }

  return vehicleStats.value.total;
});

const minCrew = computed(() => {
  if (!vehicleStats.value) {
    return toNumber(0, "people");
  }

  return toNumber(vehicleStats.value.metrics.totalMinCrew, "people");
});

const maxCrew = computed(() => {
  if (!vehicleStats.value) {
    return toNumber(0, "people");
  }

  return toNumber(vehicleStats.value.metrics.totalMaxCrew, "people");
});

const totalCargo = computed(() => {
  if (!vehicleStats.value) {
    return toNumber(0, "cargo");
  }

  return toNumber(vehicleStats.value.metrics.totalCargo, "cargo");
});

const crumbs = computed(() => {
  if (!fleet.value) {
    return [];
  }

  return [
    {
      to: {
        name: "fleet",
        params: {
          slug: fleet.value.slug,
        },
      },
      label: fleet.value.name,
    },
  ];
});

const metaTitle = computed(() => {
  if (!fleet.value) {
    return undefined;
  }

  return t("title.fleets.stats", { fleet: fleet.value.name });
});

onMounted(() => {
  fetchFleet();
  loadQuickStats();
});

const loadQuickStats = () => {
  vehiclesCollection.findStats({ slug: slug.value });
  membersCollection.findStats({ slug: slug.value });
};

const loadModelsByClassification = () =>
  fleetsCollection.findModelsByClassificationBySlug(slug.value);

const loadVehiclesByModel = () =>
  fleetsCollection.findVehiclesByModelBySlug(slug.value, vehiclesByModelLimit);

const loadModelsBySize = () =>
  fleetsCollection.findModelsBySizeBySlug(slug.value);

const loadModelsByManufacturer = () =>
  fleetsCollection.findModelsByManufacturerBySlug(slug.value);

const loadModelsByProductionStatus = () =>
  fleetsCollection.findModelsByProductionStatusBySlug(slug.value);

const { updateMetaInfo } = useMetaInfo();

const fetchFleet = async () => {
  await fleetsCollection.findBySlug(route.params.slug);

  updateMetaInfo(metaTitle.value);
};
</script>

<script lang="ts">
export default {
  name: "FleetStats",
  beforeRouteEnter: fleetRouteGuard,
};
</script>
