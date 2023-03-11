<template>
  <section class="container stats">
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12">
            <h1 class="sr-only">
              {{ t("headlines.stats") }}
            </h1>
          </div>
        </div>
        <div v-if="quickStats" class="row">
          <div class="col-12 col-sm-6 col-lg-3">
            <Panel variant="primary">
              <div class="panel-box">
                <div class="panel-box-icon">
                  <i class="fad fa-rocket-launch fa-4x" />
                </div>
                <div class="panel-box-text">
                  {{ quickStats.shipsCountYear }}
                  <div class="panel-box-text-info">
                    {{
                      t("labels.stats.quickStats.newShips", {
                        year: new Date().getFullYear(),
                      })
                    }}
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
                  {{ quickStats.shipsCountTotal }}
                  <div class="panel-box-text-info">
                    {{ t("labels.stats.quickStats.totalShips") }}
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
                  {{ t("labels.stats.modelsPerMonth") }}
                </h2>
              </div>
              <Chart
                key="models-per-month"
                :load-data="loadModelsPerMonth"
                tooltip-type="ship"
                type="column"
              />
            </Panel>
          </div>
        </div>
        <div class="row">
          <div class="col-12 col-lg-6">
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
      </div>
    </div>
  </section>
</template>

<script lang="ts" setup>
import { ref, onMounted } from "vue";
import Chart from "@/frontend/core/components/Chart/index.vue";
import Panel from "@/frontend/core/components/Panel/index.vue";
import statsCollection from "@/frontend/api/collections/Stats";
import { useI18n } from "@/frontend/composables/useI18n";

const { t } = useI18n();

const quickStats = ref<TQuickStats | null>(null);

const loadQuickStats = async () => {
  const response = await statsCollection.quickStats();

  if (!response.error) {
    quickStats.value = response.data;
  }
};

onMounted(() => {
  loadQuickStats();
});

const loadModelsByClassification = async () => {
  const response = await statsCollection.modelsByClassification();

  if (!response.error) {
    return response.data;
  }

  return [];
};

const loadModelsBySize = async () => {
  const response = await statsCollection.modelsBySize();

  if (!response.error) {
    return response.data;
  }

  return [];
};

const loadModelsPerMonth = async () => {
  const response = await statsCollection.modelsPerMonth();

  if (!response.error) {
    return response.data;
  }

  return [];
};

const loadModelsByManufacturer = async () => {
  const response = await statsCollection.modelsByManufacturer();

  if (!response.error) {
    return response.data;
  }

  return [];
};

const loadModelsByProductionStatus = async () => {
  const response = await statsCollection.modelsByProductionStatus();

  if (!response.error) {
    return response.data;
  }

  return [];
};
</script>

<script lang="ts">
export default {
  name: "StatsPage",
};
</script>
