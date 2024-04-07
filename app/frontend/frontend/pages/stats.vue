<script lang="ts">
export default {
  name: "StatsPage",
};
</script>

<script lang="ts" setup>
import Chart from "@/shared/components/Chart/index.vue";
import Panel from "@/shared/components/Panel/index.vue";
import PanelHeading from "@/shared/components/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/Panel/Body/index.vue";
import StatsPanel from "@/shared/components/StatsPanel/index.vue";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useQuery } from "@tanstack/vue-query";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";

const { stats: statsService } = useApiClient();

const { t } = useI18n();

useMetaInfo(t);

const { data: quickStats } = useQuery({
  queryKey: ["quickstats"],
  queryFn: () => statsService.stats(),
});

const { data: modelsByClassification, ...modelsByClassificationStatus } =
  useQuery({
    queryKey: ["charts", "models-by-classification"],
    queryFn: () => statsService.modelsByClassification(),
  });

const { data: modelsBySize, ...modelsBySizeStatus } = useQuery({
  queryKey: ["charts", "models-by-size"],
  queryFn: () => statsService.modelsBySize(),
});

const { data: modelsByProductionStatus, ...modelsByProductionStatusStatus } =
  useQuery({
    queryKey: ["charts", "models-by-production-status"],
    queryFn: () => statsService.modelsByProductionStatus(),
  });

const { data: modelsPerMonth, ...modelsPerMonthStatus } = useQuery({
  queryKey: ["charts", "models-per-month"],
  queryFn: () => statsService.modelsPerMonth(),
});

const { data: modelsByManufacturer, ...modelsByManufacturerStatus } = useQuery({
  queryKey: ["charts", "models-by-manufacturer"],
  queryFn: () => statsService.modelsByManufacturer(),
});
</script>

<template>
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
          <StatsPanel
            icon="fad fa-rocket-launch fa-4x"
            :value="quickStats.shipsCountYear"
            :label="
              t('labels.stats.quickStats.newShips', {
                year: String(new Date().getFullYear()),
              })
            "
          />
        </div>
        <div class="col-12 col-sm-6 col-lg-3">
          <StatsPanel
            icon="fad fa-rocket fa-4x"
            :value="quickStats.shipsCountTotal"
            :label="t('labels.stats.quickStats.totalShips')"
          />
        </div>
      </div>
      <div class="row">
        <div class="col-12 col-md-6">
          <Panel>
            <PanelHeading level="h2">
              {{ t("labels.stats.modelsByClassification") }}
            </PanelHeading>
            <PanelBody>
              <Chart
                v-if="modelsByClassification"
                key="models-by-classification"
                name="models-by-classification"
                :options="modelsByClassification"
                :async-status="modelsByClassificationStatus"
                tooltip-type="ship-pie"
                type="pie"
              />
            </PanelBody>
          </Panel>
        </div>
        <div class="col-12 col-md-6">
          <Panel>
            <PanelHeading level="h2">
              {{ t("labels.stats.modelsBySize") }}
            </PanelHeading>
            <PanelBody>
              <Chart
                key="models-by-size"
                name="models-by-size"
                :options="modelsBySize"
                :async-status="modelsBySizeStatus"
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
            <PanelHeading level="h2">
              {{ t("labels.stats.modelsByProductionStatus") }}
            </PanelHeading>
            <PanelBody>
              <Chart
                key="models-by-production-status"
                name="models-by-production-status"
                :options="modelsByProductionStatus"
                :async-status="modelsByProductionStatusStatus"
                tooltip-type="ship-pie"
                type="pie"
              />
            </PanelBody>
          </Panel>
        </div>
        <div class="col-12 col-md-7">
          <Panel>
            <PanelHeading level="h2">
              {{ t("labels.stats.modelsPerMonth") }}
            </PanelHeading>
            <PanelBody>
              <Chart
                key="models-per-month"
                name="models-per-month"
                :options="modelsPerMonth"
                :async-status="modelsPerMonthStatus"
                tooltip-type="ship"
                type="column"
              />
            </PanelBody>
          </Panel>
        </div>
      </div>
      <div class="row">
        <div class="col-12 col-lg-6">
          <Panel>
            <PanelHeading level="h2">
              {{ t("labels.stats.modelsByManufacturer") }}
            </PanelHeading>
            <PanelBody>
              <Chart
                key="models-by-manufacturer"
                name="models-by-manufacturer"
                :options="modelsByManufacturer"
                :async-status="modelsByManufacturerStatus"
                tooltip-type="ship-pie"
                type="pie"
              />
            </PanelBody>
          </Panel>
        </div>
      </div>
    </div>
  </div>
</template>
