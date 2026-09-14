<script lang="ts">
export default {
  name: "FleetContractsDeliveredBar",
};
</script>

<script lang="ts" setup>
import {
  type FleetContractProgressSummary,
  FleetContractStateEnum,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  progress: FleetContractProgressSummary;
  state: FleetContractStateEnum;
  // The board's rows put the figure under the bar; a card has room beside it.
  labelAbove?: boolean;
};

const props = withDefaults(defineProps<Props>(), { labelAbove: false });

const { t, toNumber } = useI18n();

const percent = computed(() =>
  Math.round(Math.min(Math.max(props.progress.fraction, 0), 1) * 100),
);

// Nothing can have landed on a draft, and a cancelled one stopped counting.
const QUIET_STATES: string[] = [
  FleetContractStateEnum.DRAFT,
  FleetContractStateEnum.CANCELLED,
  FleetContractStateEnum.EXPIRED,
];

const quiet = computed(() => QUIET_STATES.includes(props.state));

const tone = computed(() => {
  if (quiet.value) return "quiet";
  if (props.progress.complete) return "complete";

  return percent.value > 0 ? "underway" : "waiting";
});

/*
 * The quantities when every line is measured the same way, and the share when
 * they are not -- "720 / 1,200" means nothing across a contract asking for SCU
 * of one thing and pieces of another.
 */
const label = computed(() => {
  if (!props.progress.unit) return `${percent.value}%`;

  return t("labels.fleets.contracts.deliveredOf", {
    delivered: toNumber(props.progress.delivered),
    requested: toNumber(props.progress.requested),
    unit: t(`labels.logistics.units.${props.progress.unit}`),
  });
});
</script>

<template>
  <div class="delivered-bar" :class="`delivered-bar--${tone}`">
    <div v-if="labelAbove" class="delivered-bar__head">
      <span>{{ t("labels.fleets.contracts.delivered") }}</span>
      <span class="delivered-bar__figure">{{ label }}</span>
    </div>

    <div class="delivered-bar__track">
      <div class="delivered-bar__fill" :style="{ width: `${percent}%` }" />
    </div>

    <span v-if="!labelAbove" class="delivered-bar__figure">{{ label }}</span>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
