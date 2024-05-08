<script lang="ts">
export default {
  name: "DashboardManufacturers",
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

const { t, lUtc: l } = useI18n();

const { manufacturers: manufacturersService } = useApiClient();
const { stats: frontendStatsService } = useFrontendApiClient();

const { data: modelsByManufacturer, ...modelsByManufacturerStatus } = useQuery({
  queryKey: ["charts", "models-by-manufacturer"],
  queryFn: () => frontendStatsService.modelsByManufacturer(),
});

const { data: manufacturers, ...manufacturersStatus } = useQuery({
  queryKey: ["dashboard", "manufacturers"],
  queryFn: () =>
    manufacturersService.manufacturers({
      perPage: "6",
      page: "1",
      s: ["updated_at desc", "name asc"],
    }),
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
</script>

<template>
  <div class="row">
    <div class="col-12 col-md-6">
      <Panel>
        <PanelHeading>
          {{ t("headlines.admin.dashboard.modelsByManufacturer") }}
        </PanelHeading>
        <PanelBody>
          <Chart
            name="models-by-manufacturer"
            type="pie"
            :options="modelsByManufacturer"
            :async-status="modelsByManufacturerStatus"
            tooltip-type="ship-pie"
          />
        </PanelBody>
      </Panel>
    </div>
    <div class="col-12 col-md-6">
      <BaseTable
        v-if="manufacturers"
        :records="manufacturers?.items"
        :columns="columns"
        :async-status="manufacturersStatus"
        primary-key="id"
      >
        <template #title>
          <router-link :to="{ name: 'admin-manufacturers' }">
            {{ t("headlines.admin.dashboard.manufacturers") }}
          </router-link>
        </template>
        <template #col-name="{ record }">
          <router-link
            :to="{
              name: 'admin-manufacturer-edit',
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
              name: 'admin-manufacturer-edit',
              params: { id: record.id },
            }"
          >
            <i class="fad fa-pen" />
          </Btn>
        </template>
      </BaseTable>
    </div>
  </div>
</template>
