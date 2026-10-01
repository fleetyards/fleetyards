<script lang="ts">
export default {
  name: "ContractStatsCard",
};
</script>

<script lang="ts" setup>
import { type RouteLocationRaw } from "vue-router";
import StatsCard from "@/frontend/components/StatsCard/index.vue";
import {
  type StatsCardBadge,
  type StatsCardStatus,
  type StatsCardStatusTone,
} from "@/frontend/components/StatsCard/types";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type FleetContractDetail,
  FleetContractStateEnum,
} from "@/services/fyApi";

type Props = {
  contract?: FleetContractDetail;
  name?: string;
  to?: RouteLocationRaw | false;
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  contract: undefined,
  name: undefined,
  to: undefined,
  loading: false,
});

const emit = defineEmits<{ navigate: [] }>();

const { t, l, toNumber } = useI18n();

// The tones the contract board's state pill uses.
const TONES: Partial<Record<FleetContractStateEnum, StatsCardStatusTone>> = {
  [FleetContractStateEnum.IN_PROGRESS]: "warning",
  [FleetContractStateEnum.FULFILLED]: "success",
  [FleetContractStateEnum.SETTLED]: "success",
  [FleetContractStateEnum.EXPIRED]: "danger",
};

const status = computed<StatsCardStatus | undefined>(() =>
  props.contract
    ? {
        label: t(`labels.fleets.contracts.state.${props.contract.state}`),
        tone: TONES[props.contract.state] ?? "neutral",
      }
    : undefined,
);

const category = computed(() =>
  props.contract
    ? t(`labels.fleets.contracts.kind.${props.contract.kind}`)
    : undefined,
);

const badges = computed<StatsCardBadge[]>(() => {
  const contract = props.contract;
  if (!contract) return [];

  // `toNumber` reads zero as a missing figure, and a contract may pay nothing.
  const reward = Number(contract.reward);

  return [
    {
      key: "reward",
      label: t("labels.fleets.contracts.reward"),
      value: reward ? String(toNumber(reward, "integer")) : "0",
      unit: t("number.units.uec"),
    },
    ...(contract.deadline
      ? [
          {
            key: "deadline",
            label: t("labels.fleets.contracts.deadline"),
            value: l(contract.deadline, "datetime.formats.dateTimeZone"),
          },
        ]
      : []),
  ];
});
</script>

<template>
  <StatsCard
    compact
    :title="contract?.title || name || ''"
    kind="FleetContract"
    :category="category"
    :status="status"
    :badges="badges"
    :to="to === false ? undefined : to"
    :loading="loading"
    :unavailable="!loading && !contract"
    @navigate="emit('navigate')"
  />
</template>
