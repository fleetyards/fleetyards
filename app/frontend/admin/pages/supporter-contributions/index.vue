<script lang="ts">
export default {
  name: "AdminSupporterContributionsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import SupporterContributionActions from "@/admin/components/SupporterContributions/Actions/index.vue";
import FilterForm from "@/admin/components/SupporterContributions/FilterForm/index.vue";
import Stats from "@/admin/components/SupporterContributions/Stats/index.vue";
import {
  useSupporterContributions,
  getSupporterContributionsQueryKey,
  type SupporterContribution,
  type SupporterContributionSortEnum,
} from "@/services/fyAdminApi";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useCurrencyFormat } from "@/shared/composables/useCurrencyFormat";
import { useSupporterContributionFilters } from "@/admin/composables/useSupporterContributionFilters";

const route = useRoute();

const sorts = computed((): SupporterContributionSortEnum[] => {
  return route.query.s ? [route.query.s as SupporterContributionSortEnum] : [];
});

watch(
  () => sorts.value,
  async () => {
    await refetch();
  },
);

const supporterContributionsQueryKey = computed(() => {
  return getSupporterContributionsQueryKey(
    supporterContributionsQueryParams.value,
  );
});

const { perPage, page, updatePerPage } = usePagination(
  supporterContributionsQueryKey,
);

const { filters, isFilterSelected } = useSupporterContributionFilters(
  async () => {
    await refetch();
  },
);

const supporterContributionsQueryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
    q: {
      ...filters.value,
      sorts: sorts.value,
    },
  };
});

const statsQueryParams = computed(() => {
  return {
    q: {
      ...filters.value,
    },
  };
});

const {
  data: supporterContributions,
  refetch,
  ...asyncStatus
} = useSupporterContributions(supporterContributionsQueryParams);

const columns: BaseTableCol<SupporterContribution>[] = [
  {
    name: "name",
    label: "Name",
    sortable: true,
  },
  {
    name: "amount",
    label: "Amount",
    sortable: false,
  },
  {
    name: "startedAt",
    label: "Started at",
    sortable: true,
  },
  {
    name: "endedAt",
    label: "Ended at",
    mobile: false,
    sortable: true,
  },
  {
    name: "recurring",
    label: "Recurring",
    mobile: false,
  },
  {
    name: "anonymous",
    label: "Anonymous",
    mobile: false,
  },
];

const { t, l } = useI18n();
const { formatCents } = useCurrencyFormat();
</script>

<template>
  <Heading hero>
    {{ t("headlines.admin.supporterContributions.index") }}
    <HeadingSmall v-if="supporterContributions">
      {{
        t("headlines.pagination.count", {
          current: supporterContributions?.items.length,
          total: supporterContributions?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <Teleport to="#header-right">
    <Btn
      :to="{ name: 'admin-funding-goals' }"
      :aria-label="t('headlines.admin.fundingGoals.index')"
      mobile-icon-only
    >
      <i class="fa-duotone fa-bullseye-arrow" />
      {{ t("headlines.admin.fundingGoals.index") }}
    </Btn>
    <Btn
      :to="{ name: 'admin-supporter-contribution-create' }"
      :aria-label="t('actions.create')"
      mobile-icon-only
    >
      <i class="fa fa-plus" />
      {{ t("actions.create") }}
    </Btn>
  </Teleport>

  <FilteredList
    name="admin-supporter-contributions"
    :records="supporterContributions?.items || []"
    :async-status="asyncStatus"
    hide-loading
    hide-empty
    :is-filter-selected="isFilterSelected"
  >
    <template #filter>
      <FilterForm />
    </template>
    <template #header>
      <Stats :params="statsQueryParams" />
    </template>
    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="supporterContributions?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
        default-sort="startedAt desc"
        selectable
      >
        <template #col-name="{ record }">
          <router-link
            :to="{
              name: 'admin-supporter-contribution-edit',
              params: { id: record.id },
            }"
          >
            <span v-if="record.name">{{ record.name }}</span>
            <em v-else>—</em>
          </router-link>
        </template>
        <template #col-amount="{ record }">
          {{ formatCents(record.amountCents, record.currency) }}
        </template>
        <template #col-startedAt="{ record }">
          {{ l(record.startedAt, "datetime.formats.short") }}
        </template>
        <template #col-endedAt="{ record }">
          <span v-if="record.endedAt">
            {{ l(record.endedAt, "datetime.formats.short") }}
          </span>
          <span v-else>—</span>
        </template>
        <template #col-recurring="{ record }">
          <i v-if="record.recurring" class="fa-duotone fa-arrows-rotate" />
        </template>
        <template #col-anonymous="{ record }">
          <i v-if="record.anonymous" class="fa-duotone fa-user-secret" />
        </template>
        <template #actions="{ record }">
          <SupporterContributionActions :supporter-contribution="record" />
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        v-if="supporterContributions"
        :query-result-ref="supporterContributions"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        v-if="supporterContributions"
        :query-result-ref="supporterContributions"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
