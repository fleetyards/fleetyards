<script lang="ts">
export default {
  name: "AdminOauthApplicationsPage",
};
</script>

<script lang="ts" setup>
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
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
import OauthApplicationState from "@/shared/components/OauthApplicationState/index.vue";
import BulkSelectionBar from "@/shared/components/BulkSelectionBar/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useBulkSelection } from "@/shared/composables/useBulkSelection";
import { useComlink } from "@/shared/composables/useComlink";

const queryKey = computed(() => {
  return getOauthApplicationsQueryKey(queryParams.value);
});

const { perPage, page, updatePerPage } = usePagination(queryKey);

const queryParams = computed(() => {
  return {
    page: page.value,
    q: {},
  };
});

const { data: oauthApplications, ...asyncStatus } =
  useOauthApplications(queryParams);

const records = computed(() => oauthApplications.value?.items || []);

const totalCount = computed(
  () => oauthApplications.value?.meta.pagination?.totalCount,
);

const {
  selectedIds,
  allMatchingSelected,
  selectedCount,
  matchingCount,
  pageSelected,
  pagePartiallySelected,
  canSelectAllMatching,
  togglePage,
  selectAllMatching,
  clear: clearSelection,
  payload: bulkPayload,
} = useBulkSelection(records, () => queryParams.value.q, totalCount);

const comlink = useComlink();

// The modal owns the reason, because it is required and there is nowhere on a
// toolbar to type one.
const rejectSelected = () => {
  if (!selectedCount.value) return;

  comlink.emit("open-modal", {
    component: () =>
      import("@/admin/components/OauthApplications/RejectModal/index.vue"),
    props: {
      bulkPayload: bulkPayload.value,
      count: selectedCount.value,
      onRejected: clearSelection,
    },
  });
};

const columns: BaseTableCol<OauthApplication>[] = [
  {
    name: "name",
    label: "Name",
  },
  {
    name: "state",
    label: "Status",
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
    <Btn
      :size="BtnSizesEnum.MD"
      :to="{ name: 'admin-oauth-application-create' }"
      :aria-label="t('actions.create')"
      mobile-icon-only
    >
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
    <template #default="{ loading, refetching, emptyVisible }">
      <BulkSelectionBar
        :disabled="!records.length"
        :selected-count="selectedCount"
        :matching-count="matchingCount"
        :page-selected="pageSelected"
        :page-partially-selected="pagePartiallySelected"
        :can-select-all-matching="canSelectAllMatching"
        :all-matching-selected="allMatchingSelected"
        @toggle-page="togglePage"
        @select-all-matching="selectAllMatching"
        @clear="clearSelection"
      >
        <Btn
          v-tooltip="t('actions.oauthApplications.rejectSelected')"
          :aria-label="t('actions.oauthApplications.rejectSelected')"
          data-test="bulk-reject"
          @click="rejectSelected"
        >
          <i class="fa-duotone fa-circle-xmark" />
        </Btn>
      </BulkSelectionBar>

      <BaseTable
        :records="oauthApplications?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
        :selected="selectedIds"
        selectable
        @selected-change="selectedIds = $event"
      >
        <template #col-state="{ record }">
          <OauthApplicationState :state="record.state" />
        </template>
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
        :query-result-ref="oauthApplications"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        :query-result-ref="oauthApplications"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
