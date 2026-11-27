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

const feature = (record: Feedback) =>
  record.featureName
    ? featureLabel(record.featureName)
    : t("feedback.admin.general");

const columns: BaseTableCol<Feedback>[] = [
  { name: "message", label: t("feedback.admin.message") },
  { name: "featureName", label: t("feedback.admin.feature"), mobile: false },
  { name: "state", label: t("feedback.admin.state") },
  { name: "repliesCount", label: t("feedback.mine.replies"), mobile: false },
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
        <template #col-message="{ record, mobile }">
          <div class="feedback-summary">
            <router-link
              :to="{ name: 'admin-feedback-show', params: { id: record.id } }"
              class="feedback-message"
            >
              {{ record.message }}
            </router-link>
            <small v-if="mobile" class="feedback-detail">
              {{ feature(record) }}
            </small>
            <small
              v-if="record.pagePath"
              class="feedback-detail feedback-detail--path"
            >
              {{ record.pagePath }}
            </small>
          </div>
        </template>
        <template #col-featureName="{ record }">
          {{ feature(record) }}
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
            {{ t(`feedback.states.${record.state}`) }}
          </BasePill>
        </template>
        <template #col-repliesCount="{ record }">
          {{ record.repliesCount }}
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
.feedback-summary {
  min-width: 0;
}

.feedback-message {
  display: block;
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}

.feedback-detail {
  display: block;
  color: var(--color-text-dim);
  overflow-wrap: anywhere;
}

@media (max-width: $desktop-breakpoint) {
  .feedback-message {
    display: -webkit-box;
    overflow: hidden;
    -webkit-line-clamp: 3;
    -webkit-box-orient: vertical;
  }

  .feedback-detail--path {
    display: -webkit-box;
    overflow: hidden;
    -webkit-line-clamp: 1;
    -webkit-box-orient: vertical;
  }
}
</style>
