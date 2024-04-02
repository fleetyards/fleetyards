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
                name="models-by-classification"
                :async-status="modelsByClassificationStatus"
                :options="modelsByClassificationOptions"
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
                name="models-by-size"
                :async-status="modelsBySizeStatus"
                :options="modelsBySizeOptions"
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
                name="models-by-production-status"
                :async-status="modelsByProductionStatusStatus"
                :options="modelsByProductionStatusOptions"
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
                name="models-by-manufacturer"
                :async-status="modelsByManufacturerStatus"
                :options="modelsByManufacturerOptions"
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
                      limit: vehiclesByModelLimit,
                    })
                  }}
                </h2>
              </div>
              <Chart
                name="vehicles-by-model"
                :async-status="vehiclesByModelStatus"
                :options="vehiclesByModelOptions"
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

<script lang="ts">
export default {
  name: "FleetStatsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/frontend/core/components/BreadCrumbs/index.vue";
import { Fleet } from "@/services/fyApi";
import Chart from "@/shared/components/Chart/index.vue";
import Panel from "@/shared/components/Panel/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t, toNumber } = useI18n();

const vehiclesByModelLimit = ref(20);

const vehicleStats = computed(() => {
  return this.vehiclesCollection.stats;
});

const memberStats = computed(() => {
  return this.membersCollection.stats;
});

const totalMemberCount = computed(() => {
  if (!this.memberStats) {
    return 0;
  }

  return this.memberStats.total;
});

const totalShipCount = computed(() => {
  if (!this.vehicleStats) {
    return 0;
  }

  return this.vehicleStats.total;
});

const minCrew = computed(() => {
  if (!this.vehicleStats) {
    return toNumber(0, "people");
  }

  return toNumber(this.vehicleStats.metrics.totalMinCrew, "people");
});

const maxCrew = computed(() => {
  if (!this.vehicleStats) {
    return toNumber(0, "people");
  }

  return toNumber(this.vehicleStats.metrics.totalMaxCrew, "people");
});

const totalCargo = computed(() => {
  if (!this.vehicleStats) {
    return toNumber(0, "cargo");
  }

  return toNumber(this.vehicleStats.metrics.totalCargo, "cargo");
});

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

// get metaTitle() {
//   if (!props.fleet) {
//     return null;
//   }

//   return t("title.fleets.stats", { fleet: props.fleet.name });
// }

// onMounted(() => {
//   loadQuickStats();
// })

// const loadQuickStats = () => {
//   this.vehiclesCollection.findStats({ slug: this.slug });
//   this.membersCollection.findStats({ slug: this.slug });
// }
</script>
