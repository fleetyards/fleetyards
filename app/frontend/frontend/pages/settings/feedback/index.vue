<script lang="ts">
export default {
  name: "SettingsFeedbackPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import Empty from "@/shared/components/Empty/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { featureLabel } from "@/shared/utils/BetaFeatures";
import { usePagination } from "@/shared/composables/usePagination";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Feedback,
  FeedbackStateEnum,
  useFeedbacks,
} from "@/services/fyApi";

const { t, l } = useI18n();

const crumbs = computed<Crumb[]>(() => [
  { to: { name: "settings-profile" }, label: t("nav.settings.index") },
]);

const { perPage, page, updatePerPage } = usePagination();

const params = computed(() => ({ page: page.value, perPage: perPage.value }));

const { data: feedbacks, ...asyncStatus } = useFeedbacks(params);

const columns: BaseTableCol<Feedback>[] = [
  { name: "message", label: t("feedback.mine.message") },
  { name: "state", label: t("feedback.mine.state") },
  { name: "repliesCount", label: t("feedback.mine.replies"), mobile: false },
  { name: "createdAt", label: t("feedback.mine.sentAt"), mobile: false },
];
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />
  <Heading hero>{{ t("headlines.settings.feedback") }}</Heading>

  <FilteredList
    name="settings-feedback"
    :records="feedbacks?.items || []"
    :async-status="asyncStatus"
    hide-loading
  >
    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="feedbacks?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
        data-test="my-feedback"
      >
        <template #col-message="{ record }">
          <router-link
            :to="{ name: 'settings-feedback-show', params: { id: record.id } }"
            class="my-feedback__message"
          >
            {{ record.message }}
          </router-link>
          <small v-if="record.featureName" class="my-feedback__feature">
            {{ featureLabel(record.featureName) }}
          </small>
        </template>
        <template #col-state="{ record }">
          <Pill
            :variant="
              record.state === FeedbackStateEnum.RESOLVED
                ? PillVariantsEnum.SUCCESS
                : PillVariantsEnum.DEFAULT
            "
            uppercase
          >
            {{ t(`feedback.states.${record.state}`) }}
          </Pill>
        </template>
        <template #col-repliesCount="{ record }">
          {{ record.repliesCount }}
        </template>
        <template #col-createdAt="{ record }">
          {{ l(record.createdAt, "datetime.formats.short") }}
        </template>
      </BaseTable>
    </template>
    <template #empty>
      <Empty variant="box" :title="t('feedback.mine.empty')" hide-actions />
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
.my-feedback__message {
  display: -webkit-box;
  overflow: hidden;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

.my-feedback__feature {
  display: block;
  color: var(--color-text-dim);
}
</style>
