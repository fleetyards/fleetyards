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
  <div v-if="components" class="col-12 col-md-6">
    <BaseTable
      :records="components?.items"
      :columns="columns"
      :async-status="componentsStatus"
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
          <i class="fad fa-pen" />
        </Btn>
      </template>
    </BaseTable>
  </div>
  <div class="col-12 col-md-6">
    <Panel>
      <PanelHeading>
        {{ t("headlines.admin.dashboard.componentsByClass") }}
      </PanelHeading>
      <PanelBody>
        <Chart
          name="components-by-class"
          type="pie"
          :options="componentsByClass"
          :async-status="componentsByClassStatus"
          tooltip-type="component-pie"
        />
      </PanelBody>
    </Panel>
  </div>
</template>
