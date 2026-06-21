<script lang="ts">
export default {
  name: "AdminFundingGoalsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import FundingGoalActions from "@/admin/components/FundingGoals/Actions/index.vue";
import {
  useFundingGoals,
  getFundingGoalsQueryKey,
  type FundingGoal,
  type FundingGoalSortEnum,
} from "@/services/fyAdminApi";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useCurrencyFormat } from "@/shared/composables/useCurrencyFormat";
import { todayIsoDateLocal } from "@/shared/utils/dateHelpers";
import { useFundingGoalFilters } from "@/admin/composables/useFundingGoalFilters";

const route = useRoute();

const sorts = computed((): FundingGoalSortEnum[] => {
  return route.query.s ? [route.query.s as FundingGoalSortEnum] : [];
});

watch(
  () => sorts.value,
  async () => {
    await refetch();
  },
);

const fundingGoalsQueryKey = computed(() => {
  return getFundingGoalsQueryKey(fundingGoalsQueryParams.value);
});

const { perPage, page, updatePerPage } = usePagination(fundingGoalsQueryKey);

const { filters, isFilterSelected } = useFundingGoalFilters(async () => {
  await refetch();
});

const fundingGoalsQueryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
    q: {
      ...filters.value,
      sorts: sorts.value,
    },
  };
});

const {
  data: fundingGoals,
  refetch,
  ...asyncStatus
} = useFundingGoals(fundingGoalsQueryParams);

const columns: BaseTableCol<FundingGoal>[] = [
  {
    name: "title",
    label: "Title",
    sortable: true,
  },
  {
    name: "amount",
    label: "Amount",
    sortable: true,
  },
  {
    name: "effectiveFrom",
    label: "Effective from",
    sortable: true,
  },
  {
    name: "endedAt",
    label: "Ended at",
    mobile: false,
    sortable: false,
  },
  {
    name: "active",
    label: "Active",
    mobile: false,
  },
];

const { t, l } = useI18n();
const { formatCents } = useCurrencyFormat();
</script>

<template>
  <BreadCrumbs
    :crumbs="[
      {
        to: { name: 'admin-supporter-contributions' },
        label: t('headlines.admin.supporterContributions.index'),
      },
    ]"
  />
  <Heading hero>
    {{ t("headlines.admin.fundingGoals.index") }}
    <HeadingSmall v-if="fundingGoals">
      {{
        t("headlines.pagination.count", {
          current: fundingGoals?.items.length,
          total: fundingGoals?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <Teleport to="#header-right">
    <Btn
      :to="{ name: 'admin-supporter-contributions' }"
      :aria-label="t('headlines.admin.supporterContributions.index')"
      mobile-icon-only
    >
      <i class="fa-duotone fa-hand-holding-heart" />
      {{ t("headlines.admin.supporterContributions.index") }}
    </Btn>
    <Btn
      :to="{ name: 'admin-funding-goal-create' }"
      :aria-label="t('actions.create')"
      mobile-icon-only
    >
      <i class="fa fa-plus" />
      {{ t("actions.create") }}
    </Btn>
  </Teleport>

  <FilteredList
    name="admin-funding-goals"
    :records="fundingGoals?.items || []"
    :async-status="asyncStatus"
    hide-loading
    hide-empty
    :is-filter-selected="isFilterSelected"
  >
    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="fundingGoals?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
        default-sort="effectiveFrom desc"
        selectable
      >
        <template #col-title="{ record }">
          <router-link
            :to="{
              name: 'admin-funding-goal-edit',
              params: { id: record.id },
            }"
          >
            {{ record.title }}
          </router-link>
        </template>
        <template #col-amount="{ record }">
          {{ formatCents(record.amountCents, record.currency) }}
        </template>
        <template #col-effectiveFrom="{ record }">
          {{ l(record.effectiveFrom, "datetime.formats.short") }}
        </template>
        <template #col-endedAt="{ record }">
          <span v-if="record.endedAt">
            {{ l(record.endedAt, "datetime.formats.short") }}
          </span>
          <span v-else>—</span>
        </template>
        <template #col-active="{ record }">
          <i
            v-if="!record.endedAt || record.endedAt >= todayIsoDateLocal()"
            class="fa-duotone fa-circle-check"
          />
          <i v-else class="fa-duotone fa-circle-xmark" />
        </template>
        <template #actions="{ record }">
          <FundingGoalActions :funding-goal="record" />
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        v-if="fundingGoals"
        :query-result-ref="fundingGoals"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        v-if="fundingGoals"
        :query-result-ref="fundingGoals"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
