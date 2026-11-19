<script lang="ts">
export default {
  name: "AdminFeedbackPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import Paginator from "@/shared/components/Paginator/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { usePagination } from "@/shared/composables/usePagination";
import { useFilters } from "@/shared/composables/useFilters";
import { useI18n } from "@/shared/composables/useI18n";
import { featureLabel } from "@/shared/utils/BetaFeatures";
import FilterForm from "@/admin/components/Feedback/FilterForm/index.vue";
import FeedbackActions from "@/admin/components/Feedback/Actions/index.vue";
import {
  type Feedback,
  type FeedbackQuery,
  FeedbackStateEnum,
  useFeedbacks,
} from "@/services/fyAdminApi";

const { t, l } = useI18n();

const { perPage, page, updatePerPage } = usePagination();

const { filters, isFilterSelected } = useFilters<FeedbackQuery>();

const queryParams = computed(() => ({
  page: page.value,
  q: { ...filters.value },
}));

const { data: feedbacks, ...asyncStatus } = useFeedbacks(queryParams);

const columns: BaseTableCol<Feedback>[] = [
  { name: "message", label: t("feedback.admin.message") },
  { name: "featureName", label: t("feedback.admin.feature") },
  { name: "state", label: t("feedback.admin.state") },
  { name: "username", label: t("feedback.admin.user"), mobile: false },
  { name: "createdAt", label: t("feedback.admin.sentAt"), mobile: false },
];
</script>

<template>
  <Heading hero mobile-hidden>
    {{ t("headlines.admin.feedback.index") }}
    <HeadingSmall v-if="feedbacks">
      {{
        t("headlines.pagination.count", {
          current: feedbacks.items.length,
          total: feedbacks.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <FilteredList
    name="admin-feedback"
    :records="feedbacks?.items || []"
    :async-status="asyncStatus"
    :is-filter-selected="isFilterSelected"
    hide-loading
    hide-empty
  >
    <template #filter>
      <FilterForm />
    </template>
    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="feedbacks?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
        data-test="feedback-list"
      >
        <template #col-message="{ record }">
          <p class="feedback-message">{{ record.message }}</p>
          <small v-if="record.pagePath" class="feedback-page">
            {{ record.pagePath }}
          </small>
        </template>
        <template #col-featureName="{ record }">
          {{
            record.featureName
              ? featureLabel(record.featureName)
              : t("feedback.admin.general")
          }}
        </template>
        <template #col-state="{ record }">
          <BasePill
            :variant="
              record.state === FeedbackStateEnum.RESOLVED
                ? PillVariantsEnum.SUCCESS
                : PillVariantsEnum.WARNING
            "
            uppercase
          >
            {{ t(`feedback.admin.states.${record.state}`) }}
          </BasePill>
        </template>
        <template #col-username="{ record }">
          {{ record.username || "-" }}
        </template>
        <template #col-createdAt="{ record }">
          {{ l(record.createdAt, "datetime.formats.short") }}
        </template>
        <template #actions="{ record }">
          <FeedbackActions :feedback="record" />
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        :query-result-ref="feedbacks"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        :query-result-ref="feedbacks"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>

<style lang="scss" scoped>
.feedback-message {
  margin: 0;
  white-space: pre-wrap;
}

.feedback-page {
  color: var(--color-text-dim, #959595);
}
</style>
