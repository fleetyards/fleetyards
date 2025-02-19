<script lang="ts">
export default {
  name: "DashboardUsers",
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
import { useRegistrationsPerMonth } from "@/services/fyAdminApi";
import { useUsers as useUsersQuery } from "@/services/fyAdminApi";
import { useSessionStore } from "@/admin/stores/session";

const { t, lUtc: l, timeDistance } = useI18n();

const sessionStore = useSessionStore();

const { data: registrationsPerMonth, ...registrationsPerMonthStatus } =
  useRegistrationsPerMonth({
    query: {
      enabled: () => sessionStore.hasAccessTo("stats"),
    },
  });

const { data: users, ...usersStatus } = useUsersQuery(
  {
    perPage: "6",
    page: "1",
    s: ["last_active_at desc", "created_at desc", "name asc"],
  },
  {
    query: {
      enabled: () => sessionStore.hasAccessTo("users"),
    },
  },
);

const columns: BaseTableColumn[] = [
  {
    name: "username",
    label: t("labels.username"),
  },
  {
    name: "lastActiveAt",
    label: t("labels.user.lastActiveAt"),
  },
  {
    name: "createdAt",
    label: t("labels.createdAt"),
  },
];
</script>

<template>
  <div v-if="registrationsPerMonth" class="col-12 col-md-7">
    <Panel>
      <PanelHeading>
        {{ t("headlines.admin.dashboard.registrationsPerMonth") }}
      </PanelHeading>
      <PanelBody>
        <Chart
          name="models-by-manufacturer"
          type="column"
          :options="registrationsPerMonth"
          :async-status="registrationsPerMonthStatus"
          tooltip-type="user"
        />
      </PanelBody>
    </Panel>
  </div>
  <div v-if="users" class="col-12 col-md-5">
    <BaseTable
      :records="users?.items"
      :columns="columns"
      :async-status="usersStatus"
      primary-key="id"
    >
      <template #title>
        <router-link :to="{ name: 'admin-users' }">
          {{ t("headlines.admin.dashboard.users") }}
        </router-link>
      </template>
      <template #col-username="{ record }">
        <router-link
          :to="{
            name: 'admin-user-edit',
            params: { id: record.id },
          }"
        >
          {{ record.username }}
        </router-link>
      </template>
      <template #col-lastActiveAt="{ record }">
        <template v-if="record.lastActiveAt">
          {{ timeDistance(record.lastActiveAt) }}
        </template>
      </template>
      <template #col-createdAt="{ record }">
        {{ l(record.createdAt, "datetime.formats.short") }}
      </template>
      <template #actions="{ record }">
        <Btn
          :size="BtnSizesEnum.SMALL"
          inline
          :to="{
            name: 'admin-user-edit',
            params: { id: record.id },
          }"
        >
          <i class="fad fa-pen" />
        </Btn>
      </template>
    </BaseTable>
  </div>
</template>
