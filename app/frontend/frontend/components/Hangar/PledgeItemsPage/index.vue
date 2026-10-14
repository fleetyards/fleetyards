<script lang="ts">
export default {
  name: "HangarPledgeItemsPage",
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
  useHangarPaints,
  getHangarPaintsQueryKey,
  useHangarFlair,
  getHangarFlairQueryKey,
  useHangarUpgrades,
  getHangarUpgradesQueryKey,
  useHangarEquipment,
  getHangarEquipmentQueryKey,
  type HangarPledgeItemQuery,
} from "@/services/fyApi";

type Props = {
  kind: "paints" | "flair" | "equipment" | "upgrades";
};

const props = defineProps<Props>();

const KINDS = {
  upgrades: {
    useItems: useHangarUpgrades,
    getQueryKey: getHangarUpgradesQueryKey,
    headline: "headlines.hangar.upgrades",
    emptyName: "labels.hangarPledgeItems.upgrades",
    icon: "fa-duotone fa-arrow-up",
  },
  paints: {
    useItems: useHangarPaints,
    getQueryKey: getHangarPaintsQueryKey,
    headline: "headlines.hangar.paints",
    emptyName: "labels.hangarPledgeItems.paints",
    icon: "fa-duotone fa-paintbrush",
  },
  flair: {
    useItems: useHangarFlair,
    getQueryKey: getHangarFlairQueryKey,
    headline: "headlines.hangar.flair",
    emptyName: "labels.hangarPledgeItems.flair",
    icon: "fa-duotone fa-trophy-star",
  },
  equipment: {
    useItems: useHangarEquipment,
    getQueryKey: getHangarEquipmentQueryKey,
    headline: "headlines.hangar.equipment",
    emptyName: "labels.hangarPledgeItems.equipment",
    icon: "fa-duotone fa-shirt",
  },
};

// Each kind is its own route, so the kind never changes under a mounted page.
const config = KINDS[props.kind];

const { t } = useI18n();

const queryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: getQuery(),
}));

const { perPage, page, updatePerPage } = usePagination();

const { isFilterSelected, getQuery } = useFilters<HangarPledgeItemQuery>({
  updateCallback: async () => {
    await refetch();
  },
});

const {
  data: pledgeItems,
  refetch,
  ...asyncStatus
} = config.useItems(queryParams);

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
    {{ t(config.headline) }}
    <!-- Reserved before the count is known, so the page does not move when the
         first page lands. -->
    <HeadingSmall data-test="pledge-items-count">
      <template v-if="pledgeItems">
        {{
          t("headlines.pagination.count", {
            current: pledgeItems.items.length,
            total: pledgeItems.meta.pagination?.totalCount,
          })
        }}
      </template>
      <template v-else>&nbsp;</template>
    </HeadingSmall>
  </Heading>

  <FilteredList
    :name="`hangar-${kind}`"
    :records="pledgeItems?.items || []"
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
        :query-result-ref="pledgeItems"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>

    <template #skeleton="{ count }">
      <RowsSkeleton :count="count" meta />
    </template>

    <template #default="{ records, emptyVisible }">
      <PledgeItemsList
        :items="records"
        :empty-visible="emptyVisible"
        :empty-name="t(config.emptyName)"
        :icon="config.icon"
      />
    </template>

    <template #pagination-bottom>
      <Paginator
        :query-result-ref="pledgeItems"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
