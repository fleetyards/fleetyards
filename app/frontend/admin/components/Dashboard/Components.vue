<script lang="ts">
export default {
  name: "DashboardComponents",
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
import { useComponents, type Component } from "@/services/fyAdminApi";
import { useComponentsByClass } from "@/services/fyApi";
import { useSessionStore } from "@/admin/stores/session";

const { t, lUtc: l } = useI18n();

const sessionStore = useSessionStore();

const { data: componentsByClass, ...componentsByClassStatus } =
  useComponentsByClass();

const { data: components, ...componentsStatus } = useComponents(
  {
    perPage: "6",
    page: "1",
    s: ["updated_at desc", "name asc"],
  },
  {
    query: {
      enabled: sessionStore.hasAccessTo("components"),
    },
  },
);

const columns: BaseTableCol<Component>[] = [
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
    <BaseTable
      :records="components?.items || []"
      :columns="columns"
      :async-status="componentsStatus"
      :fill-height="true"
      :admin="true"
      primary-key="id"
    >
      <template #title>
        <router-link :to="{ name: 'admin-components' }">
          {{ t("headlines.admin.dashboard.components") }}
        </router-link>
      </template>
      <template #col-name="{ record }">
        <router-link
          :to="{
            name: 'admin-component-edit',
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
            name: 'admin-component-edit',
            params: { id: record.id },
          }"
        >
          <i class="fa-duotone fa-pen" />
        </Btn>
      </template>
    </BaseTable>
  </div>
  <div class="col-12 col-md-6">
    <Panel fill-height>
      <PanelHeading>
        {{ t("headlines.admin.dashboard.componentsByClass") }}
      </PanelHeading>
      <PanelBody class="dashboard-panel-body">
        <AsyncData :async-status="componentsByClassStatus" hide-error>
          <template #loading>
            <Loader :loading="true" relative admin />
          </template>
          <template #resolved>
            <Chart
              name="components-by-class"
              type="pie"
              :options="componentsByClass"
              :async-status="componentsByClassStatus"
              tooltip-type="component-pie"
            />
          </template>
        </AsyncData>
      </PanelBody>
    </Panel>
  </div>
</template>

<style lang="scss" scoped>
.dashboard-panel-body {
  position: relative;
  flex: 1;
}
</style>
