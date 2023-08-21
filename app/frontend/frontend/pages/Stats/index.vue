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
                        year: String(new Date().getFullYear()),
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
                name="models-by-classification"
                key="models-by-classification"
                :load-data="statsService.modelsByClassification"
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
                key="models-by-size"
                :load-data="statsService.modelsBySize"
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
                key="models-by-production-status"
                :load-data="statsService.modelsByProductionStatus"
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
                name="models-per-month"
                key="models-per-month"
                :load-data="statsService.modelsPerMonth"
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
                name="models-by-manufacturer"
                key="models-by-manufacturer"
                :load-data="statsService.modelsByManufacturer"
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
import Chart from "@/shared/components/Chart/index.vue";
import Panel from "@/shared/components/Panel/index.vue";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useQuery } from "@tanstack/vue-query";
import { useI18n } from "@/frontend/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";

const { stats: statsService } = useApiClient();

const { t } = useI18n();

useMetaInfo(t);

const { data: quickStats } = useQuery({
  queryKey: ["quickstats"],
  queryFn: () => statsService.stats(),
});
</script>

<script lang="ts">
export default {
  name: "StatsPage",
};
</script>
