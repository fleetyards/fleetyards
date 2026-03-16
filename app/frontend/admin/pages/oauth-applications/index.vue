<script lang="ts">
export default {
  name: "AdminOauthApplicationsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import {
  useOauthApplications,
  getOauthApplicationsQueryKey,
  type OauthApplication,
} from "@/services/fyAdminApi";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import OauthApplicationActions from "@/admin/components/OauthApplications/Actions/index.vue";

const queryKey = computed(() => {
  return getOauthApplicationsQueryKey(queryParams.value);
});

const { perPage, page, updatePerPage } = usePagination(queryKey);

const queryParams = computed(() => {
  return {
    page: page.value,
  };
});

const { data: oauthApplications, ...asyncStatus } =
  useOauthApplications(queryParams);

const columns: BaseTableCol<OauthApplication>[] = [
  {
    name: "name",
    label: "Name",
  },
  {
    name: "ownerName",
    label: "Owner",
  },
  {
    name: "uid",
    label: "Client ID",
    mobile: false,
  },
  {
    name: "confidential",
    label: "Confidential",
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
  <Heading hero>
    {{ t("headlines.admin.oauthApplications.index") }}
    <HeadingSmall v-if="oauthApplications">
      {{
        t("headlines.pagination.count", {
          current: oauthApplications?.items.length,
          total: oauthApplications?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <Teleport to="#header-right">
    <Btn :to="{ name: 'admin-oauth-application-create' }">
      <i class="fa fa-plus" />
      {{ t("actions.create") }}
    </Btn>
  </Teleport>

  <FilteredList
    name="admin-oauth-applications"
    :records="oauthApplications?.items || []"
    :async-status="asyncStatus"
    hide-loading
    hide-empty
  >
    <template #default="{ loading, emptyVisible }">
      <BaseTable
        :records="oauthApplications?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading"
        :empty-visible="emptyVisible"
        selectable
      >
        <template #col-name="{ record }">
          {{ record.name }}
        </template>
        <template #col-ownerName="{ record }">
          {{ record.ownerName || "-" }}
        </template>
        <template #col-uid="{ record }">
          <code>{{ record.uid }}</code>
        </template>
        <template #col-confidential="{ record }">
          <i v-if="record.confidential" class="fa-duotone fa-check" />
          <i v-else class="fa-duotone fa-times" />
        </template>
        <template #col-createdAt="{ record }">
          {{ l(record.createdAt, "datetime.formats.short") }}
        </template>
        <template #actions="{ record }">
          <OauthApplicationActions :oauth-application="record" />
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        v-if="oauthApplications"
        :query-result-ref="oauthApplications"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        v-if="oauthApplications"
        :query-result-ref="oauthApplications"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
