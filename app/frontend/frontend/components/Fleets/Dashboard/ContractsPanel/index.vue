<script lang="ts">
export default {
  name: "FleetDashboardContractsPanel",
};
</script>

<script lang="ts" setup>
import DashboardPanel from "@/frontend/components/Fleets/Dashboard/DashboardPanel/index.vue";
import ContractStatePill from "@/frontend/components/Fleets/Contracts/ContractStatePill/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  FleetContractStateEnum,
  useFleetContracts,
  type Fleet,
  type FleetContract,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t, toUEC } = useI18n();

const SHOWN = 4;

const fleetSlug = computed(() => props.fleet.slug);

// The reader's own work first, then what is there to be picked up.
const { data: mine, isLoading: mineLoading } = useFleetContracts(fleetSlug, {
  mine: true,
  inHand: true,
  perPage: SHOWN,
  q: {
    stateIn: [
      FleetContractStateEnum.OPEN,
      FleetContractStateEnum.IN_PROGRESS,
      FleetContractStateEnum.FULFILLED,
    ],
  },
});

const { data: open, isLoading: openLoading } = useFleetContracts(fleetSlug, {
  perPage: SHOWN,
  q: { stateIn: [FleetContractStateEnum.OPEN] },
});

const mineItems = computed(() => mine.value?.items ?? []);

const mineIds = computed(() => new Set(mineItems.value.map(({ id }) => id)));

const openItems = computed(() =>
  (open.value?.items ?? []).filter(({ id }) => !mineIds.value.has(id)),
);

// Said to the dashboard once both answers are in, so an empty board can be
// offered as something to start instead of a box saying there is nothing.
const emit = defineEmits<{ empty: [boolean] }>();

const isEmpty = computed(
  () =>
    !!mine.value &&
    !!open.value &&
    !mineItems.value.length &&
    !openItems.value.length,
);

watch(isEmpty, (value) => emit("empty", value), { immediate: true });

const linkFor = (contract: FleetContract) => ({
  name: "fleet-contract",
  params: { slug: props.fleet.slug, contract: contract.slug },
});

const groups = computed(() =>
  [
    {
      key: "mine",
      label: t("fleetDashboard.contracts.mine"),
      items: mineItems.value,
    },
    {
      key: "open",
      label: t("fleetDashboard.contracts.open"),
      items: openItems.value,
    },
  ].filter((group) => group.items.length),
);
</script>

<template>
  <DashboardPanel
    v-if="groups.length"
    :title="t('fleetDashboard.contracts.title')"
    :loading="mineLoading || openLoading"
    :more="{ name: 'fleet-contracts', params: { slug: fleet.slug } }"
    data-test="fleet-dashboard-contracts"
  >
    <section
      v-for="group in groups"
      :key="group.key"
      class="contracts-panel__group"
      :data-test="`fleet-dashboard-contracts-${group.key}`"
    >
      <h3 class="contracts-panel__label">{{ group.label }}</h3>
      <ul class="contracts-panel__list">
        <li
          v-for="contract in group.items"
          :key="contract.id"
          class="contracts-panel__entry"
        >
          <router-link :to="linkFor(contract)" class="contracts-panel__title">
            {{ contract.title }}
          </router-link>
          <span
            class="contracts-panel__reward"
            v-html="toUEC(Number(contract.reward))"
          />
          <ContractStatePill
            v-if="group.key === 'mine'"
            :state="contract.state"
          />
        </li>
      </ul>
    </section>
  </DashboardPanel>
</template>

<style lang="scss" scoped>
.contracts-panel__group + .contracts-panel__group {
  margin-top: 16px;
}

.contracts-panel__label {
  margin: 0 0 8px;
  color: var(--color-text-dim, #959595);
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 10px;
  letter-spacing: 0.16em;
  text-transform: uppercase;
}

.contracts-panel__list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.contracts-panel__entry {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
}

.contracts-panel__title {
  flex: 1 1 auto;
  min-width: 0;
  overflow: hidden;
  color: var(--color-lifted, #eee);
  font-weight: 600;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.contracts-panel__reward {
  flex: 0 0 auto;
  color: var(--color-text-dim, #959595);
  font-size: 13px;
}
</style>
