<script lang="ts">
export default {
  name: "FleetContractsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import GridSkeleton from "@/shared/components/GridSkeleton/index.vue";
import ContractPanel from "@/frontend/components/Fleets/Contracts/ContractPanel/index.vue";
import {
  type Fleet,
  type FleetMember,
  type FleetContract,
  FleetContractStateEnum,
  useFleetContracts,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { checkAccess } from "@/shared/utils/Access";
import { useRouter } from "vue-router";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const route = useRoute();
const router = useRouter();

const fleetSlug = computed(() => props.fleet.slug);
const showClosed = ref(false);

// Two views rather than a filter bar: an open board and a history. The states
// are spelled out instead of sent as "archived", because a contract has five
// of them and only two mean "still worth looking at".
const queryParams = computed(() => ({
  q: {
    stateIn: showClosed.value
      ? [
          FleetContractStateEnum.FULFILLED,
          FleetContractStateEnum.CANCELLED,
          FleetContractStateEnum.EXPIRED,
        ]
      : [
          FleetContractStateEnum.DRAFT,
          FleetContractStateEnum.OPEN,
          FleetContractStateEnum.IN_PROGRESS,
        ],
  },
}));

const {
  data: contracts,
  refetch,
  ...asyncStatus
} = useFleetContracts(fleetSlug, queryParams);

const contractList = computed<FleetContract[]>(
  () => contracts.value?.items ?? [],
);

const canCreate = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:contracts:manage",
    "fleet:contracts:create",
  ]),
);

const goToCreate = () => {
  void router.push({
    name: "fleet-contract-new",
    params: { slug: props.fleet.slug },
  });
};

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

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
  {
    to: { name: "fleet-contracts", params: { slug: props.fleet.slug } },
    label: t("headlines.fleets.contracts.index"),
  },
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <Heading size="hero" hero>
    {{ t("headlines.fleets.contracts.index") }}
  </Heading>

  <Teleport v-if="canCreate" to="#header-right">
    <Btn
      :size="BtnSizesEnum.MD"
      :aria-label="t('actions.fleets.contracts.create')"
      data-test="create-contract"
      mobile-icon-only
      @click="goToCreate"
    >
      <i class="fa-duotone fa-plus" />
      {{ t("actions.fleets.contracts.create") }}
    </Btn>
  </Teleport>

  <FilteredList
    key="fleet-contracts-index"
    :name="route.name?.toString() || ''"
    :records="contractList"
    :async-status="asyncStatus"
    hide-empty
  >
    <template #actions-left>
      <BtnGroup segmented>
        <Btn :active="!showClosed" mobile-icon-only @click="showClosed = false">
          <i class="fa-light fa-clipboard-list" />
          {{ t("labels.fleets.contracts.openTab") }}
        </Btn>
        <Btn :active="showClosed" mobile-icon-only @click="showClosed = true">
          <i class="fa-light fa-box-archive" />
          {{ t("labels.fleets.contracts.closedTab") }}
        </Btn>
      </BtnGroup>
    </template>

    <template #skeleton="{ filterVisible }">
      <GridSkeleton :filter-visible="filterVisible" />
    </template>

    <template #default="{ records }">
      <Grid :records="records as FleetContract[]" primary-key="id">
        <template #default="{ record }">
          <ContractPanel :contract="record" :fleet="fleet" />
        </template>
      </Grid>
    </template>
  </FilteredList>
</template>
