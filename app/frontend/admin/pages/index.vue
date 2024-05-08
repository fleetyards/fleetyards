<script lang="ts">
export default {
  name: "AdminHomePage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import StatsPanel from "@/shared/components/StatsPanel/index.vue";
import Panel from "@/shared/components/Panel/index.vue";
import PanelHeading from "@/shared/components/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/Panel/Body/index.vue";
import Chart from "@/shared/components/Chart/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import DashboardUsers from "@/admin/components/Dashboard/Users.vue";
import DashboardModels from "@/admin/components/Dashboard/Models.vue";
import DashboardManufacturers from "@/admin/components/Dashboard/Manufacturers.vue";
import DashboardComponents from "@/admin/components/Dashboard/Components.vue";
import { useApiClient } from "@/admin/composables/useApiClient";
import { useApiClient as useFrontendApiClient } from "@/frontend/composables/useApiClient";
import { useQuery } from "@tanstack/vue-query";

const { t } = useI18n();

const { stats: statsService } = useApiClient();
const { stats: frontendStatsService } = useFrontendApiClient();

const { data: quickStats, refetch } = useQuery({
  queryKey: ["quickstats"],
  queryFn: () => statsService.stats(),
});

onMounted(() => {
  setInterval(() => {
    refetch();
  }, 30 * 1000);
});

const { data: visitsPerDay, ...visitsPerDayStatus } = useQuery({
  queryKey: ["charts", "visits-per-day"],
  queryFn: () => statsService.visitsPerDay(),
});

const { data: mostViewedPages, ...mostViewedPagesStatus } = useQuery({
  queryKey: ["charts", "most-viewed-pages"],
  queryFn: () => statsService.mostViewedPages(),
});

const { data: visitsPerMonth, ...visitsPerMonthStatus } = useQuery({
  queryKey: ["charts", "visits-per-month"],
  queryFn: () => statsService.visitsPerMonth(),
});

const { data: registrationsPerMonth, ...registrationsPerMonthStatus } =
  useQuery({
    queryKey: ["charts", "registrations-per-month"],
    queryFn: () => statsService.registrationsPerMonth(),
  });

const { data: modelsBySize, ...modelsBySizeStatus } = useQuery({
  queryKey: ["charts", "models-by-size"],
  queryFn: () => frontendStatsService.modelsBySize(),
});

const { data: modelsByProductionStatus, ...modelsByProductionStatusStatus } =
  useQuery({
    queryKey: ["charts", "models-by-production-status"],
    queryFn: () => frontendStatsService.modelsByProductionStatus(),
  });

const { data: modelsPerMonth, ...modelsPerMonthStatus } = useQuery({
  queryKey: ["charts", "models-per-month"],
  queryFn: () => frontendStatsService.modelsPerMonth(),
});
</script>

<template>
  <Teleport to="#header-left">
    <Heading>{{ t("headlines.admin.dashboard.title") }}</Heading>
  </Teleport>

  <Teleport to="#header-right">
    <Btn>
      <i class="fa fa-rotate" />
      {{ t("actions.admin.dashboard.reloadModels") }}
    </Btn>
    <Btn>
      <i class="fa fa-rotate" />
      {{ t("actions.admin.dashboard.reloadScData") }}
    </Btn>
  </Teleport>

  <section>
    <div class="row">
      <div class="col-12 col-md-6 col-lg-4">
        <div v-if="quickStats" class="row">
          <div class="col-12 col-sm-6">
            <StatsPanel
              icon="fad fa-user fa-4x"
              :value="quickStats.onlineCount"
              :label="t('labels.admin.dashboard.quickStats.onlineUsers')"
            />
            <StatsPanel
              icon="fad fa-rocket fa-4x"
              :value="quickStats.shipsCountYear"
              :label="
                t('labels.admin.dashboard.quickStats.newShipsInYear', {
                  year: new Date().getFullYear(),
                })
              "
            />
            <StatsPanel
              icon="fad fa-users-class fa-4x"
              :value="quickStats.fleetsCountTotal"
              :label="t('labels.admin.dashboard.quickStats.totalFleets')"
            />
          </div>
          <div class="col-12 col-sm-6">
            <StatsPanel
              icon="fad fa-users fa-4x"
              :value="quickStats.usersCountTotal"
              :label="t('labels.admin.dashboard.quickStats.totalUsers')"
            />
            <StatsPanel
              icon="fad fa-starship fa-4x"
              :value="quickStats.shipsCountTotal"
              :label="t('labels.admin.dashboard.quickStats.totalShips')"
            />
          </div>
        </div>
      </div>
      <div class="col-12 col-md-6 col-lg-8">
        <Panel>
          <PanelHeading>
            {{ t("headlines.admin.dashboard.visitsPerDay") }}
          </PanelHeading>
          <PanelBody>
            <Chart
              name="visits-per-day"
              type="area"
              :options="visitsPerDay"
              :async-status="visitsPerDayStatus"
              tooltip-type="visit"
              :height="292"
              :reload="30"
            />
          </PanelBody>
        </Panel>
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-5">
        <Panel>
          <PanelHeading>
            {{ t("headlines.admin.dashboard.mostViewedPages") }}
          </PanelHeading>
          <PanelBody>
            <Chart
              name="most-viewed-pages"
              type="bar"
              :options="mostViewedPages"
              :async-status="mostViewedPagesStatus"
              tooltip-type="view"
              :height="344"
              :reload="30"
            />
          </PanelBody>
        </Panel>
      </div>
      <div class="col-12 col-md-7">
        <Panel>
          <PanelHeading>
            {{ t("headlines.admin.dashboard.visitsPerMonth") }}
          </PanelHeading>
          <PanelBody>
            <Chart
              name="visits-per-month"
              type="column"
              :options="visitsPerMonth"
              :async-status="visitsPerMonthStatus"
              tooltip-type="visit"
              :height="344"
              :reload="30"
            />
          </PanelBody>
        </Panel>
      </div>
    </div>
    <DashboardUsers />
    <DashboardModels />
    <div class="row">
      <div class="col-12 col-md-6">
        <Panel>
          <PanelHeading>
            {{ t("headlines.admin.dashboard.modelsByStatus") }}
          </PanelHeading>
          <PanelBody>
            <Chart
              name="models-by-status"
              type="pie"
              :options="modelsByProductionStatus"
              :async-status="modelsByProductionStatusStatus"
              tooltip-type="ship-pie"
            />
          </PanelBody>
        </Panel>
      </div>
      <div class="col-12 col-md-6">
        <Panel>
          <PanelHeading>
            {{ t("headlines.admin.dashboard.modelsBySize") }}
          </PanelHeading>
          <PanelBody>
            <Chart
              name="models-by-size"
              type="pie"
              :options="modelsBySize"
              :async-status="modelsBySizeStatus"
              tooltip-type="ship-pie"
            />
          </PanelBody>
        </Panel>
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <Panel>
          <PanelHeading>
            {{ t("headlines.admin.dashboard.modelsPerMonth") }}
          </PanelHeading>
          <PanelBody>
            <Chart
              name="models-per-month"
              type="column"
              :options="modelsPerMonth"
              :async-status="modelsPerMonthStatus"
              tooltip-type="ship"
              :height="344"
            />
          </PanelBody>
        </Panel>
      </div>
    </div>
    <DashboardManufacturers />
    <DashboardComponents />
  </section>
</template>
