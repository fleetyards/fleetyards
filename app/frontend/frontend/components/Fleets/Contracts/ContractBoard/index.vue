<script lang="ts">
export default {
  name: "FleetContractsBoard",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import SortBar from "@/shared/components/base/Table/SortBar/index.vue";
import { useSortParam } from "@/shared/composables/useSortParam";
import { type FleetContractSortEnum } from "@/services/fyApi";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import GridSkeleton from "@/shared/components/GridSkeleton/index.vue";
import ContractPanel from "@/frontend/components/Fleets/Contracts/ContractPanel/index.vue";
import ContractTable from "@/frontend/components/Fleets/Contracts/ContractTable/index.vue";
import {
  type Fleet,
  type FleetContract,
  useFleetContracts,
} from "@/services/fyApi";
import {
  type ContractBoardView,
  CONTRACT_BOARD_VIEWS,
} from "@/frontend/components/Fleets/Contracts/ContractBoard/views";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import type { LocationQuery } from "vue-router";
import { storeToRefs } from "pinia";
import { useContractsStore } from "@/frontend/stores/contracts";

type Props = {
  fleet: Fleet;
  // Which of the four this board is showing. One page asks four questions; the
  // key rides in the route, so each of them can be linked to.
  view: ContractBoardView;
};

const props = defineProps<Props>();

const { t } = useI18n();

// Grid view only: the table carries the same sorts on its headings.
const sortFields = computed<BaseTableCol<unknown>[]>(() => [
  {
    name: "title",
    label: t("headlines.fleets.contracts.index"),
    sortable: true,
  },
  {
    name: "reward",
    label: t("labels.fleets.contracts.reward"),
    sortable: true,
  },
  {
    name: "deadline",
    label: t("labels.fleets.contracts.deadline"),
    sortable: true,
  },
]);
const comlink = useComlink();
const route = useRoute();

const contractsStore = useContractsStore();
const { gridView } = storeToRefs(contractsStore);

const openDisplayOptionsModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/shared/components/DisplayOptionsModal/index.vue"),
    props: {
      gridView: gridView.value,
      testPrefix: "contracts",
      updateCallback: (next: boolean) => {
        contractsStore.gridView = next;
      },
    },
  });
};

const fleetSlug = computed(() => props.fleet.slug);

// Same route, different query: the page keeps its instance, and the list below
// refetches rather than being rebuilt. The page number belongs to the board it
// was counted on, so it does not come along.
const boardLink = (board: ContractBoardView) => {
  const query: LocationQuery = { ...route.query, view: board.key };
  delete query.page;

  return { name: "fleet-contracts", params: { slug: props.fleet.slug }, query };
};

const sortParam = useSortParam<FleetContractSortEnum>();

const queryParams = computed(() => ({
  mine: props.view.mine ? true : undefined,
  inHand: props.view.inHand ? true : undefined,
  // The states are spelled out rather than sent as "archived", because a
  // contract has five of them and each board means a different few.
  q: { stateIn: props.view.states, ...sortParam.value },
}));

const {
  data: contracts,
  refetch,
  ...asyncStatus
} = useFleetContracts(fleetSlug, queryParams);

const contractList = computed<FleetContract[]>(
  () => contracts.value?.items ?? [],
);

const contractUpdatedComlink = ref<() => void>();

onMounted(() => {
  contractUpdatedComlink.value = comlink.on(
    "fleet-contract-updated",
    () => void refetch(),
  );
});

onUnmounted(() => {
  contractUpdatedComlink.value?.();
});
</script>

<template>
  <FilteredList
    :name="route.name?.toString() || ''"
    :records="contractList"
    :async-status="asyncStatus"
    :hide-empty="!gridView"
  >
    <template #actions-right>
      <Btn
        :aria-label="t('actions.models.openTableConfiguration')"
        data-test="contracts-display-options"
        @click="openDisplayOptionsModal"
      >
        <i class="fa-duotone fa-sliders" />
      </Btn>
    </template>

    <template #actions-left>
      <BtnGroup segmented>
        <Btn
          v-for="board in CONTRACT_BOARD_VIEWS"
          :key="board.key"
          :to="boardLink(board)"
          :active="board.key === view.key"
          :data-test="`contracts-board-${board.key}`"
          mobile-icon-only
        >
          <i :class="board.icon" />
          {{ t(`labels.fleets.contracts.views.${board.key}`) }}
        </Btn>
      </BtnGroup>
    </template>

    <template #skeleton="{ filterVisible }">
      <GridSkeleton :filter-visible="filterVisible" />
    </template>

    <template #sort>
      <SortBar
        v-if="gridView"
        :columns="sortFields"
        default-sort="deadline asc"
      />
    </template>

    <template #default="{ records, emptyVisible }">
      <Grid
        v-if="gridView"
        :records="records as FleetContract[]"
        primary-key="id"
      >
        <template #default="{ record }">
          <ContractPanel :contract="record" :fleet="fleet" />
        </template>
      </Grid>

      <!-- The dense board: every job on one screen, in the app's table. -->
      <!-- The table draws its own empty row inside its frame, so the list's
           panel would be a second one under it. -->
      <ContractTable
        v-else
        :fleet="fleet"
        :contracts="records as FleetContract[]"
        :async-status="asyncStatus"
        :empty-visible="emptyVisible"
      />
    </template>
  </FilteredList>
</template>
