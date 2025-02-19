<script lang="ts">
export default {
  name: "AdminUsersPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import FilterForm from "@/admin/components/Users/FilterForm.vue";
import UserActions from "@/admin/components/Users/Actions/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import { BaseTableColumn } from "@/shared/components/base/Table/types";
import { usePagination } from "@/shared/composables/usePagination";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import {
  useUsers as useUsersQuery,
  getUsersQueryKey,
} from "@/services/fyAdminApi";
import { useUserFilters } from "@/admin/composables/useUserFilters";

const { t, lUtc: l, timeDistance } = useI18n();

const route = useRoute();

const sorts = computed(() => {
  return route.query.s ? [route.query.s as string] : [];
});

watch(
  () => sorts.value,
  () => {
    refetch();
  },
);

const usersQueryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
    q: filters.value,
    s: sorts.value,
  };
});

const usersQueryKey = computed(() => {
  return getUsersQueryKey(usersQueryParams);
});

const { perPage, page, updatePerPage } = usePagination(usersQueryKey);

const { filters } = useUserFilters(() => refetch());

const {
  data: users,
  refetch,
  ...asyncStatus
} = useUsersQuery(usersQueryParams);

const columns: BaseTableColumn[] = [
  {
    name: "avatar",
    label: "",
  },
  {
    name: "username",
    label: t("labels.username"),
    sortable: true,
  },
  {
    name: "email",
    label: t("labels.email"),
    sortable: true,
  },
  {
    name: "rsiHandle",
    field: "rsi_handle",
    label: t("labels.user.rsiHandle"),
    sortable: true,
  },
  {
    name: "lastActiveAt",
    field: "last_active_at",
    label: t("labels.user.lastActiveAt"),
    sortable: true,
  },
  {
    name: "confirmedAt",
    field: "confirmed_at",
    label: t("labels.user.confirmedAt"),
    sortable: true,
  },
  {
    name: "createdAt",
    field: "created_at",
    label: t("labels.createdAt"),
    sortable: true,
  },
];
</script>

<template>
  <Heading>
    {{ t("headlines.admin.users.index") }}
    <HeadingSmall v-if="users">
      {{
        t("headlines.pagination.count", {
          current: users?.items.length,
          total: users?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <FilteredList
    v-if="users"
    name="admin-users"
    :records="users.items || []"
    :async-status="asyncStatus"
    hide-loading
    hide-empty-box
  >
    <template #filter>
      <FilterForm />
    </template>
    <template #default="{ loading, emptyBoxVisible }">
      <BaseTable
        :records="users.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading"
        :empty-box-visible="emptyBoxVisible"
        selectable
      >
        <template #col-avatar="{ record }">
          <LazyImage
            v-if="record.avatar"
            :variant="LazyImageVariantsEnum.EXTRA_SMALL"
            :src="record.avatar"
            alt="User Avatar"
            shadow
          />
        </template>
        <template #col-lastActiveAt="{ record }">
          <template v-if="record.lastActiveAt">
            {{ timeDistance(record.lastActiveAt) }}
          </template>
        </template>
        <template #col-confirmedAt="{ record }">
          <template v-if="record.confirmedAt">
            {{ l(record.confirmedAt, "datetime.formats.short") }}
          </template>
        </template>
        <template #col-createdAt="{ record }">
          {{ l(record.createdAt, "datetime.formats.short") }}
        </template>
        <template #actions="{ record }">
          <UserActions :user="record" />
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        v-if="users"
        :query-result-ref="users"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        v-if="users"
        :query-result-ref="users"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
