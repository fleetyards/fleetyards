<script lang="ts">
export default {
  name: "DashboardManufacturers",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Chart from "@/shared/components/Chart/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import Loader from "@/shared/components/Loader/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useManufacturers, type Manufacturer } from "@/services/fyAdminApi";
import { useModelsByManufacturer } from "@/services/fyApi";
import { useSessionStore } from "@/admin/stores/session";

const { t, lUtc: l } = useI18n();

const sessionStore = useSessionStore();

const { data: modelsByManufacturer, ...modelsByManufacturerStatus } =
  useModelsByManufacturer();

const { data: manufacturers, ...manufacturersStatus } = useManufacturers(
  {
    perPage: "6",
    page: "1",
    s: ["updated_at desc", "name asc"],
  },
  {
    query: {
      enabled: () => sessionStore.hasAccessTo("manufacturers"),
    },
  },
);

const columns: BaseTableCol<Manufacturer>[] = [
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
  <div class="col-12 col-md-6">
    <Panel fill-height>
      <PanelHeading>
        {{ t("headlines.admin.dashboard.modelsByManufacturer") }}
      </PanelHeading>
      <PanelBody class="dashboard-panel-body">
        <AsyncData :async-status="modelsByManufacturerStatus" hide-error>
          <template #loading>
            <Loader :loading="true" relative admin />
          </template>
          <template #resolved>
            <Chart
              name="models-by-manufacturer"
              type="pie"
              :options="modelsByManufacturer"
              :async-status="modelsByManufacturerStatus"
              tooltip-type="ship-pie"
            />
          </template>
        </AsyncData>
      </PanelBody>
    </Panel>
  </div>
  <div class="col-12 col-md-6">
    <BaseTable
      :records="manufacturers?.items || []"
      :columns="columns"
      :async-status="manufacturersStatus"
      :fill-height="true"
      :admin="true"
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
          <i class="fa-duotone fa-pen" />
        </Btn>
      </template>
    </BaseTable>
  </div>
</template>

<style lang="scss" scoped>
.dashboard-panel-body {
  position: relative;
  flex: 1;
}
</style>
