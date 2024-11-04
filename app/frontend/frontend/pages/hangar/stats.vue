<script lang="ts">
export default {
  name: "HangarStatsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/frontend/core/components/BreadCrumbs/index.vue";
import { type HangarStats } from "@/services/fyApi";
import Chart from "@/shared/components/Chart/index.vue";
import Panel from "@/shared/components/Panel/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

const { t, toNumber } = useI18n();

const quickStats = ref<HangarStats>();

const totalCount = computed(() => {
  if (!quickStats.value) {
    return 0;
  }

  return quickStats.value.total;
});

const minCrew = computed(() => {
  if (!quickStats.value) {
    return toNumber(0, "people");
  }

  return toNumber(quickStats.value.metrics.totalMinCrew, "people");
});

const maxCrew = computed(() => {
  if (!quickStats.value) {
    return toNumber(0, "people");
  }

  return toNumber(quickStats.value.metrics.totalMaxCrew, "people");
});

const totalCargo = computed(() => {
  if (!quickStats.value) {
    return toNumber(0, "cargo");
  }

  return toNumber(quickStats.value.metrics.totalCargo, "cargo");
});

onMounted(() => {
  loadQuickStats();
});

const loadQuickStats = async () => {
  const response = await this.$api.get("vehicles/quick-stats");
  if (!response.error) {
    quickStats.value = response.data;
  }
};

// const loadModelsByClassification = async () => {
//   const response = await this.$api.get(
//     "vehicles/stats/models-by-classification",
//   );
//   if (!response.error) {
//     return response.data;
//   }
//   return [];
// }

// async loadModelsBySize() {
//   const response = await this.$api.get("vehicles/stats/models-by-size");
//   if (!response.error) {
//     return response.data;
//   }
//   return [];
// },

// async loadModelsByManufacturer() {
//   const response = await this.$api.get(
//     "vehicles/stats/models-by-manufacturer",
//   );
//   if (!response.error) {
//     return response.data;
//   }
//   return [];
// },

// async loadModelsByProductionStatus() {
//   const response = await this.$api.get(
//     "vehicles/stats/models-by-production-status",
//   );
//   if (!response.error) {
//     return response.data;
//   }
//   return [];
// }
</script>

<template>
  <div class="row">
    <div class="col-12">
      <div class="row">
        <div class="col-12">
          <BreadCrumbs
            :crumbs="[{ to: { name: 'hangar' }, label: t('nav.hangar') }]"
          />
          <h1>
            {{ t("headlines.hangar.stats") }}
          </h1>
        </div>
      </div>
      <div class="row">
        <div class="col-12 col-sm-6 col-lg-3">
          <Panel variant="primary">
            <div class="panel-box">
              <div class="panel-box-icon">
                <i class="fad fa-rocket fa-4x" />
              </div>
              <div class="panel-box-text">
                {{ totalCount }}
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
              name="models-by-size"
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
              name="models-by-production-status"
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
              name="models-by-manufacturer"
              :load-data="loadModelsByManufacturer"
              tooltip-type="ship-pie"
              type="pie"
            />
          </Panel>
        </div>
      </div>
    </div>
  </div>
</template>
