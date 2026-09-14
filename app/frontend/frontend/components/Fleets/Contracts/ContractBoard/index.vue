<script lang="ts">
export default {
  name: "FleetContractsBoard",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
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
const comlink = useComlink();
const route = useRoute();

const contractsStore = useContractsStore();
const { gridView } = storeToRefs(contractsStore);

const openDisplayOptionsModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Contracts/ContractDisplayOptionsModal/index.vue"),
  });
};

const fleetSlug = computed(() => props.fleet.slug);

const queryParams = computed(() => ({
  mine: props.view.mine ? true : undefined,
  // The states are spelled out rather than sent as "archived", because a
  // contract has five of them and each board means a different few.
  q: { stateIn: props.view.states },
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
    :key="`fleet-contracts-${view.key}`"
    :name="route.name?.toString() || ''"
    :records="contractList"
    :async-status="asyncStatus"
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
          :to="{ name: board.route, params: { slug: fleet.slug } }"
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

    <template #default="{ records }">
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
      <ContractTable
        v-else
        :fleet="fleet"
        :contracts="records as FleetContract[]"
        :async-status="asyncStatus"
      />
    </template>
  </FilteredList>
</template>
