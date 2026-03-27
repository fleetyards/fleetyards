<script lang="ts">
export default {
  name: "MaintenanceRsiApiStatusPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import BasePill from "@/shared/components/base/Pill/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { usePagination } from "@/shared/composables/usePagination";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  useRsiRequestLogs,
  getRsiRequestLogsQueryKey,
  resolveRsiRequestLog,
  type RsiRequestLog,
} from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";

const { t, l } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();

const queryKey = "admin-rsi-request-logs";
const { perPage, page, updatePerPage } = usePagination(queryKey);

const queryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
}));

const {
  data: rsiRequestLogs,
  refetch: _refetch,
  ...asyncStatus
} = useRsiRequestLogs(queryParams);

const queryClient = useQueryClient();
const invalidate = () =>
  queryClient.invalidateQueries({ queryKey: getRsiRequestLogsQueryKey() });

const columns: BaseTableCol<RsiRequestLog>[] = [
  {
    name: "url",
    label: "URL",
    sortable: true,
  },
  {
    name: "resolved",
    label: "Status",
    width: "120px",
    alignment: "center",
  },
  {
    name: "createdAt",
    label: "Created at",
    mobile: false,
    sortable: true,
    width: "200px",
  },
];

const resolve = async (log: RsiRequestLog) => {
  try {
    await resolveRsiRequestLog(log.id);
    void invalidate();
    displaySuccess({ text: t("messages.rsiRequestLogs.resolved") });
  } catch {
    displayAlert({ text: t("messages.rsiRequestLogs.error") });
  }
};
</script>

<template>
  <Heading hero>
    {{ t("headlines.admin.rsiApiStatus.index") }}
    <HeadingSmall v-if="rsiRequestLogs">
      {{
        t("headlines.pagination.count", {
          current: rsiRequestLogs?.items.length,
          total: rsiRequestLogs?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <FilteredList
    name="admin-rsi-request-logs"
    :records="rsiRequestLogs?.items || []"
    :async-status="asyncStatus"
    hide-loading
    hide-empty
  >
    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="rsiRequestLogs?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
        default-sort="created_at desc"
      >
        <template #col-url="{ record }">
          {{ record.url }}
        </template>
        <template #col-resolved="{ record }">
          <BasePill :variant="record.resolved ? 'success' : 'danger'" uppercase>
            {{
              record.resolved
                ? t("labels.rsiRequestLogs.resolved")
                : t("labels.rsiRequestLogs.unresolved")
            }}
          </BasePill>
        </template>
        <template #col-createdAt="{ record }">
          {{ l(record.createdAt, "datetime.formats.short") }}
        </template>
        <template #actions="{ record }">
          <Btn
            v-if="!record.resolved"
            :size="BtnSizesEnum.SMALL"
            @click.prevent="resolve(record)"
          >
            <i class="fa-duotone fa-check" />
            {{ t("actions.resolve") }}
          </Btn>
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        v-if="rsiRequestLogs"
        :query-result-ref="rsiRequestLogs"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        v-if="rsiRequestLogs"
        :query-result-ref="rsiRequestLogs"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
