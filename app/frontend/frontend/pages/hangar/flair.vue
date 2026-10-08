<script lang="ts">
export default {
  name: "HangarFlairPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import RowsSkeleton from "@/shared/components/RowsSkeleton/index.vue";
import FilterForm from "@/frontend/components/Hangar/PledgeItemsFilterForm/index.vue";
import PledgeItemsList from "@/frontend/components/Hangar/PledgeItemsList/index.vue";
import PledgeItemsSwitch from "@/frontend/components/Hangar/PledgeItemsSwitch/index.vue";
import HangarSyncBtn from "@/frontend/components/Hangar/SyncBtn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useFilters } from "@/shared/composables/useFilters";
import { usePagination } from "@/shared/composables/usePagination";
import {
  useHangarFlair,
  getHangarFlairQueryKey,
  type HangarPledgeItemQuery,
} from "@/services/fyApi";

const { t } = useI18n();

const queryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: getQuery(),
}));

// Declared before the pagination it reads: both sides are computed, so the
// forward reference resolves on first access rather than at definition.
const queryKey = computed(() => getHangarFlairQueryKey(queryParams));

const { perPage, page, updatePerPage } = usePagination(queryKey);

const { isFilterSelected, getQuery } = useFilters<HangarPledgeItemQuery>({
  updateCallback: async () => {
    await refetch();
  },
});

const { data: flair, refetch, ...asyncStatus } = useHangarFlair(queryParams);

const comlink = useComlink();

let offSyncFinished: (() => void) | undefined;

onMounted(() => {
  offSyncFinished = comlink.on("hangar-sync-finished", () => refetch());
});

onUnmounted(() => {
  offSyncFinished?.();
});
</script>

<template>
  <BreadCrumbs
    :crumbs="[{ to: { name: 'hangar' }, label: t('nav.hangar.index') }]"
  />

  <Heading hero>
    {{ t("headlines.hangar.flair") }}
    <!-- Reserved before the count is known, so the page does not move when the
         first page lands. -->
    <HeadingSmall data-test="pledge-items-count">
      <template v-if="flair">
        {{
          t("headlines.pagination.count", {
            current: flair.items.length,
            total: flair.meta.pagination?.totalCount,
          })
        }}
      </template>
      <template v-else>&nbsp;</template>
    </HeadingSmall>
  </Heading>

  <p class="pledge-items-intro">{{ t("texts.hangarFlair.intro") }}</p>

  <FilteredList
    name="hangar-flair"
    :records="flair?.items || []"
    :async-status="asyncStatus"
    :is-filter-selected="isFilterSelected"
  >
    <template #filter>
      <FilterForm />
    </template>

    <template #actions-left>
      <PledgeItemsSwitch />
    </template>

    <template #actions-right>
      <HangarSyncBtn :size="BtnSizesEnum.SM" />
    </template>

    <template #pagination-top>
      <Paginator
        :query-result-ref="flair"
        :per-page="perPage"
        @update-per-page="updatePerPage"
      />
    </template>

    <template #skeleton="{ count }">
      <RowsSkeleton :count="count" meta />
    </template>

    <template #default="{ records, emptyVisible }">
      <PledgeItemsList
        :items="records"
        :empty-visible="emptyVisible"
        :empty-name="t('labels.hangarPledgeItems.flair')"
        icon="fa-duotone fa-trophy-star"
      />
    </template>

    <template #pagination-bottom>
      <Paginator
        :query-result-ref="flair"
        :per-page="perPage"
        @update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>

<style lang="scss" scoped>
.pledge-items-intro {
  margin-bottom: 1rem;
  color: var(--color-text-dim);
}
</style>
