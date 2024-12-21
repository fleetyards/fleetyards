<script lang="ts">
export default {
  name: "DashboardModels",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Panel from "@/shared/components/Panel/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableColumn } from "@/shared/components/base/Table/types";
import PanelHeading from "@/shared/components/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/Panel/Body/index.vue";
import Chart from "@/shared/components/Chart/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useApiClient } from "@/admin/composables/useApiClient";
import { useApiClient as useFrontendApiClient } from "@/frontend/composables/useApiClient";
import { useQuery } from "@tanstack/vue-query";
import { useSessionStore } from "@/admin/stores/session";

const { t, lUtc: l } = useI18n();

const sessionStore = useSessionStore();

const { models: modelsSerivce } = useApiClient();
const { stats: frontendStatsService } = useFrontendApiClient();

const { data: modelsByClassification, ...modelsByClassificationStatus } =
  useQuery({
    queryKey: ["charts", "models-by-manufacturer"],
    queryFn: () => frontendStatsService.modelsByClassification(),
  });

const { data: models, ...modelsStatus } = useQuery({
  queryKey: ["dashboard", "models"],
  queryFn: () =>
    modelsSerivce.models({
      perPage: "6",
      page: "1",
      s: ["updated_at desc", "name asc"],
    }),
  enabled: () => sessionStore.hasAccessTo("models"),
});

const columns: BaseTableColumn[] = [
  {
    name: "name",
    label: t("labels.name"),
  },
  {
    name: "updatedAt",
    label: t("labels.lastReload"),
  },
];

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
  <div class="col-12 col-md-6">
    <Panel>
      <PanelHeading>
        {{ t("headlines.admin.dashboard.modelsByClassification") }}
      </PanelHeading>
      <PanelBody>
        <Chart
          name="models-by-manufacturer"
          type="pie"
          :options="modelsByClassification"
          :async-status="modelsByClassificationStatus"
          tooltip-type="ship-pie"
        />
      </PanelBody>
    </Panel>
  </div>
  <div v-if="models" class="col-12 col-md-6">
    <BaseTable
      :records="models?.items"
      :columns="columns"
      :async-status="modelsStatus"
      primary-key="id"
    >
      <template #title>
        <router-link :to="{ name: 'admin-models' }">
          {{ t("headlines.admin.dashboard.models") }}
        </router-link>
      </template>
      <template #col-name="{ record }">
        <router-link
          :to="{
            name: 'admin-model-edit',
            params: { id: record.id },
          }"
        >
          {{ record.name }}
        </router-link>
      </template>
      <template #col-updatedAt="{ record }">
        {{ l(record.updatedAt, "datetime.formats.short") }}
      </template>
      <template #actions="{ record }">
        <Btn
          :size="BtnSizesEnum.SMALL"
          inline
          :to="{
            name: 'admin-model-edit',
            params: { id: record.id },
          }"
        >
          <i class="fad fa-pen" />
        </Btn>
      </template>
    </BaseTable>
  </div>
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
</template>
