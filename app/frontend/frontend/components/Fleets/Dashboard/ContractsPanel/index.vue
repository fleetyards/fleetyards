<script lang="ts">
export default {
  name: "FleetDashboardContractsPanel",
};
</script>

<script lang="ts" setup>
import { liveQuery } from "@/frontend/components/Fleets/Dashboard/liveQuery";
import DashboardPanel from "@/frontend/components/Fleets/Dashboard/DashboardPanel/index.vue";
import ContractStatePill from "@/frontend/components/Fleets/Contracts/ContractStatePill/index.vue";
import { useContractCover } from "@/frontend/composables/useContractCover";
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

const { resolve: resolveCover } = useContractCover();

// Darkest under the text, so a bright cover never washes out the title.
const SCRIM =
  "linear-gradient(90deg, rgb(0 0 0 / 0.8) 0%, rgb(0 0 0 / 0.45) 55%, rgb(0 0 0 / 0.35) 100%)";

// The cover the board shows for it, so a job reads as the same job here.
const coverFor = (contract: FleetContract) => ({
  backgroundImage: `${SCRIM}, url(${resolveCover(contract, props.fleet)})`,
});

const SHOWN = 4;

const fleetSlug = computed(() => props.fleet.slug);

// The reader's own work first, then what is there to be picked up.
const { data: mine, isLoading: mineLoading } = useFleetContracts(
  fleetSlug,
  {
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
  },
  { query: liveQuery },
);

const { data: open, isLoading: openLoading } = useFleetContracts(
  fleetSlug,
  {
    perPage: SHOWN,
    q: { stateIn: [FleetContractStateEnum.OPEN] },
  },
  { query: liveQuery },
);

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
        <li v-for="contract in group.items" :key="contract.id">
          <router-link
            :to="linkFor(contract)"
            class="contracts-panel__entry"
            :style="coverFor(contract)"
            data-test="fleet-dashboard-contract"
          >
            <span class="contracts-panel__text">
              <span class="contracts-panel__title">{{ contract.title }}</span>
              <span class="contracts-panel__meta">
                {{ t(`labels.fleets.contracts.kind.${contract.kind}`) }}
                <template v-if="Number(contract.reward) > 0">
                  · <span v-html="toUEC(Number(contract.reward))" />
                </template>
              </span>
            </span>
            <ContractStatePill
              v-if="group.key === 'mine'"
              :state="contract.state"
            />
          </router-link>
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
  margin: 8px 0;
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

// A strip of the contract's cover behind a scrim that darkens towards the text,
// so the job is recognisable at a glance and its title stays readable.
.contracts-panel__entry {
  display: flex;
  align-items: center;
  gap: 10px;
  min-height: 64px;
  padding: 10px 14px;
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-control, 8px);
  background-position: center;
  background-size: cover;
  color: #fff;
  text-decoration: none;
  text-shadow: 0 1px 2px rgb(0 0 0 / 0.9);
  transition: filter 150ms ease;

  &:hover,
  &:focus-visible {
    filter: brightness(1.2);
    color: #fff;
  }
}

.contracts-panel__text {
  display: flex;
  flex: 1 1 auto;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.contracts-panel__title {
  overflow: hidden;
  font-weight: 600;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.contracts-panel__meta {
  color: rgb(255 255 255 / 0.85);
  font-size: 13px;
}

@media (prefers-reduced-motion: reduce) {
  .contracts-panel__entry {
    transition-duration: 1ms;
  }
}
</style>
