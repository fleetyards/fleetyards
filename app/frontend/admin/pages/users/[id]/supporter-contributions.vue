<script lang="ts">
export default {
  name: "AdminUserSupporterContributionsPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import SourcePill from "@/admin/components/SupporterContributions/SourcePill/index.vue";
import LinkedViaPill from "@/admin/components/SupporterContributions/LinkedViaPill/index.vue";
import SupporterStatus from "@/shared/components/SupporterStatus/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import { usePagination } from "@/shared/composables/usePagination";
import { useCurrencyFormat } from "@/shared/composables/useCurrencyFormat";
import {
  type User,
  type SupporterContribution,
  SupporterContributionSortEnum,
  useSupporterContributions,
  getSupporterContributionsQueryKey,
} from "@/services/fyAdminApi";

type Props = {
  user: User;
};

const props = defineProps<Props>();

const { t, l } = useI18n();
const { formatCents } = useCurrencyFormat();

// The same list the supporters section serves, narrowed to this account --
// there is no second endpoint, so a column added there shows up here too.
const queryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: {
    userIdEq: props.user.id,
    sorts: [SupporterContributionSortEnum.STARTED_AT_DESC],
  },
}));

const queryKey = computed(() =>
  getSupporterContributionsQueryKey(queryParams.value),
);

const { perPage, page, updatePerPage } = usePagination(queryKey);

const { data: contributions, ...asyncStatus } =
  useSupporterContributions(queryParams);

const columns: BaseTableCol<SupporterContribution>[] = [
  {
    name: "name",
    label: t("labels.supporterContribution.name"),
  },
  {
    name: "amount",
    label: t("labels.supporterContribution.amount"),
  },
  {
    name: "source",
    label: t("labels.supporterContribution.source"),
  },
  {
    name: "linkedVia",
    label: t("labels.supporterContribution.linkedVia"),
    mobile: false,
  },
  {
    name: "startedAt",
    label: t("labels.supporterContribution.startedAt"),
  },
  {
    name: "endedAt",
    label: t("labels.supporterContribution.endedAt"),
    mobile: false,
  },
  {
    name: "recurring",
    label: t("labels.supporterContribution.recurring"),
    mobile: false,
  },
];
</script>

<template>
  <Heading hero>
    {{ t("headlines.admin.users.supporterContributions") }}
    <HeadingSmall v-if="contributions">
      {{
        t("headlines.pagination.count", {
          current: contributions?.items.length,
          total: contributions?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <SupporterStatus
    :supporter="props.user.supporter"
    :supporter-until="props.user.supporterUntil"
    :tier-projections="props.user.supporterTierProjections"
  />

  <FilteredList
    name="admin-user-supporter-contributions"
    :records="contributions?.items || []"
    :async-status="asyncStatus"
    hide-loading
    hide-empty
  >
    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="contributions?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
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
        <template #col-source="{ record }">
          <SourcePill :source="record.source" />
        </template>
        <template #col-linkedVia="{ record }">
          <LinkedViaPill :linked-via="record.linkedVia" />
        </template>
        <template #col-startedAt="{ record }">
          {{ l(record.startedAt, "datetime.formats.date") }}
        </template>
        <template #col-endedAt="{ record }">
          <span v-if="record.endedAt">
            {{ l(record.endedAt, "datetime.formats.date") }}
          </span>
          <span v-else>—</span>
        </template>
        <template #col-recurring="{ record }">
          <i v-if="record.recurring" class="fa-duotone fa-arrows-rotate" />
        </template>
      </BaseTable>
    </template>
    <template #pagination-bottom>
      <Paginator
        :query-result-ref="contributions"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
