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
import BulkSelectionBar from "@/shared/components/BulkSelectionBar/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useBulkSelection } from "@/shared/composables/useBulkSelection";
import { useFeatures } from "@/frontend/composables/useFeatures";
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
  useHangarShipComponents,
  getHangarShipComponentsQueryKey,
  FeatureFlagName,
  type HangarPledgeItem,
  type HangarPledgeItemQuery,
} from "@/services/fyApi";

type Props = {
  kind: "paints" | "flair" | "equipment" | "shipComponents" | "upgrades";
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
    icon: "fa-duotone fa-paint-roller",
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
  shipComponents: {
    useItems: useHangarShipComponents,
    getQueryKey: getHangarShipComponentsQueryKey,
    headline: "headlines.hangar.shipComponents",
    emptyName: "labels.hangarPledgeItems.shipComponents",
    icon: "fa-duotone fa-microchip",
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

const { isFeatureEnabled } = useFeatures();

// Ship components and FPS gear are things to keep in an inventory.
const inventoryActions = computed(
  () =>
    ["shipComponents", "equipment"].includes(props.kind) &&
    isFeatureEnabled(FeatureFlagName.HANGAR_INVENTORIES),
);

const records = computed(() => pledgeItems.value?.items ?? []);

// The endpoint takes the items themselves, not a query, so a selection stays
// within the page: the matching count is the page's.
const {
  selectedIds,
  allMatchingSelected,
  selectedCount,
  matchingCount,
  pageSelected,
  pagePartiallySelected,
  canSelectAllMatching,
  toggle: toggleSelection,
  togglePage,
  selectAllMatching,
  clear: clearSelection,
} = useBulkSelection(
  records,
  () => queryParams.value.q,
  () => records.value.length,
);

const openAddToInventory = (items: HangarPledgeItem[]) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Hangar/AddToInventoryModal/index.vue"),
    props: { items, onAdded: clearSelection },
  });
};

const addSelectedToInventory = () => {
  openAddToInventory(
    records.value.filter((item) => selectedIds.value.includes(item.id)),
  );
};

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
      <FilterForm :upgrades="kind === 'upgrades'" />
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

    <template #default="{ records: listed, emptyVisible }">
      <BulkSelectionBar
        v-if="inventoryActions && listed.length"
        :selected-count="selectedCount"
        :matching-count="matchingCount"
        :page-selected="pageSelected"
        :page-partially-selected="pagePartiallySelected"
        :can-select-all-matching="canSelectAllMatching"
        :all-matching-selected="allMatchingSelected"
        data-test="pledge-items-selection"
        @toggle-page="togglePage"
        @select-all-matching="selectAllMatching"
        @clear="clearSelection"
      >
        <Btn
          :disabled="!selectedCount"
          data-test="pledge-items-add-selected"
          @click="addSelectedToInventory"
        >
          <i class="fa-light fa-box-open" />
          <span>{{ t("actions.hangarPledgeItems.addToInventory") }}</span>
        </Btn>
      </BulkSelectionBar>
      <PledgeItemsList
        :items="listed"
        :empty-visible="emptyVisible"
        :empty-name="t(config.emptyName)"
        :icon="config.icon"
        :selectable="inventoryActions"
        :selected-ids="selectedIds"
        :inventory-actions="inventoryActions"
        @toggle="toggleSelection"
        @add-to-inventory="(item) => openAddToInventory([item])"
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
