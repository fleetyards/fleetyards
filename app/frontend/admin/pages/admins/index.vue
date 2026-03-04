<script lang="ts">
export default {
  name: "AdminAdminsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import {
  useAdminUsers,
  getAdminUsersQueryKey,
  type AdminUser,
} from "@/services/fyAdminApi";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import AdminUserActions from "@/admin/components/AdminUsers/Actions/index.vue";

const adminUsersQueryKey = computed(() => {
  return getAdminUsersQueryKey(adminUsersQueryParams.value);
});

const { perPage, page, updatePerPage } = usePagination(adminUsersQueryKey);

const adminUsersQueryParams = computed(() => {
  return {
    page: page.value,
  };
});

const { data: adminUsers, ...asyncStatus } = useAdminUsers(
  adminUsersQueryParams,
);

const columns: BaseTableCol<AdminUser>[] = [
  {
    name: "username",
    label: "Username",
  },
  {
    name: "email",
    label: "Email",
    mobile: false,
  },
  {
    name: "superAdmin",
    label: "Super Admin",
    mobile: false,
  },
  {
    name: "resourceAccess",
    label: "Access",
    mobile: false,
  },
  {
    name: "createdAt",
    label: "Created At",
    mobile: false,
  },
];

const { t, l } = useI18n();
</script>

<template>
  <Heading>
    {{ t("headlines.admin.admins.index") }}
    <HeadingSmall v-if="adminUsers">
      {{
        t("headlines.pagination.count", {
          current: adminUsers?.items.length,
          total: adminUsers?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <FilteredList
    name="admin-admins"
    :records="adminUsers?.items || []"
    :async-status="asyncStatus"
    hide-loading
    hide-empty
  >
    <template #default="{ loading, emptyVisible }">
      <BaseTable
        :records="adminUsers?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading"
        :empty-visible="emptyVisible"
        selectable
      >
        <template #col-username="{ record }">
          {{ record.username }}
        </template>
        <template #col-email="{ record }">
          {{ record.email }}
        </template>
        <template #col-superAdmin="{ record }">
          <i v-if="record.superAdmin" class="fad fa-check" />
          <i v-else class="fad fa-times" />
        </template>
        <template #col-resourceAccess="{ record }">
          {{ record.resourceAccess.join(", ") }}
        </template>
        <template #col-createdAt="{ record }">
          {{ l(record.createdAt, "datetime.formats.short") }}
        </template>
        <template #actions="{ record }">
          <AdminUserActions :admin-user="record" />
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        v-if="adminUsers"
        :query-result-ref="adminUsers"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        v-if="adminUsers"
        :query-result-ref="adminUsers"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
