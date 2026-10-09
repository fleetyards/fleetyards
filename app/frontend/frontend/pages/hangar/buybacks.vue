<script lang="ts">
export default {
  name: "HangarBuybacksPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import RowsSkeleton from "@/shared/components/RowsSkeleton/index.vue";
import ListToolbar from "@/shared/components/base/ListToolbar/index.vue";
import FilterForm from "@/frontend/components/Hangar/BuybacksFilterForm/index.vue";
import BuybacksList from "@/frontend/components/Hangar/BuybacksList/index.vue";
import BuybackSyncBtn from "@/frontend/components/Hangar/BuybackSyncBtn/index.vue";
import PledgeItemsSwitch from "@/frontend/components/Hangar/PledgeItemsSwitch/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useFilters } from "@/shared/composables/useFilters";
import { usePagination } from "@/shared/composables/usePagination";
import {
  useHangarBuybacks,
  getHangarBuybacksQueryKey,
  type BuybackPledge,
  type BuybackPledgeQuery,
} from "@/services/fyApi";

const { t } = useI18n();

const queryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: getQuery(),
}));

// Declared before the pagination it reads: both sides are computed, so the
// forward reference resolves on first access rather than at definition.
const queryKey = computed(() => getHangarBuybacksQueryKey(queryParams));

const { perPage, page, updatePerPage } = usePagination(queryKey);

const { isFilterSelected, getQuery } = useFilters<BuybackPledgeQuery>({
  updateCallback: async () => {
    await refetch();
  },
});

const {
  data: buybacks,
  refetch,
  ...asyncStatus
} = useHangarBuybacks(queryParams);

const sortFields = computed<BaseTableCol<BuybackPledge>[]>(() => [
  {
    name: "reclaimedOn",
    label: t("labels.buybacks.reclaimedOn"),
    sortable: true,
  },
  { name: "name", label: t("labels.name"), sortable: true },
  { name: "price", label: t("labels.buybacks.price"), sortable: true },
]);

const comlink = useComlink();

let offSyncFinished: (() => void) | undefined;

onMounted(() => {
  offSyncFinished = comlink.on("buyback-sync-finished", () => refetch());
});

onUnmounted(() => {
  offSyncFinished?.();
});
</script>

<template>
  <BreadCrumbs
    :crumbs="[{ to: { name: 'hangar' }, label: t('nav.hangar.index') }]"
  />

  <Heading hero>{{ t("headlines.hangar.buybacks") }}</Heading>

  <p class="buybacks-intro">{{ t("texts.buybacks.intro") }}</p>

  <FilteredList
    name="buybacks"
    :records="buybacks?.items || []"
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
      <BuybackSyncBtn :size="BtnSizesEnum.SM" />
    </template>

    <template #pagination-top>
      <Paginator
        :query-result-ref="buybacks"
        :per-page="perPage"
        @update-per-page="updatePerPage"
      />
    </template>

    <template #sort>
      <ListToolbar :columns="sortFields" default-sort="reclaimedOn desc" />
    </template>

    <template #skeleton="{ count }">
      <RowsSkeleton :count="count" meta trailing />
    </template>

    <template #default="{ records, emptyVisible }">
      <BuybacksList :buybacks="records" :empty-visible="emptyVisible" />
    </template>

    <template #pagination-bottom>
      <Paginator
        :query-result-ref="buybacks"
        :per-page="perPage"
        @update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>

<style lang="scss" scoped>
.buybacks-intro {
  margin-bottom: 1rem;
  color: var(--color-text-dim);
}
</style>
