<script lang="ts" setup>
import { type TradeRoute } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  tradeRoute: TradeRoute;
  availableCargo?: number;
  average?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  availableCargo: undefined,
  average: false,
});

const profit = computed(() => {
  if (props.average && props.tradeRoute.averageProfitPerUnit) {
    return props.tradeRoute.averageProfitPerUnit;
  }

  if (props.tradeRoute.profitPerUnit) {
    return props.tradeRoute.profitPerUnit;
  }

  return 0;
});

const profitPerUnitPercent = computed(() => {
  if (props.average && props.tradeRoute.averageProfitPerUnitPercent) {
    return props.tradeRoute.averageProfitPerUnitPercent;
  }

  if (props.tradeRoute.profitPerUnitPercent) {
    return props.tradeRoute.profitPerUnitPercent;
  }

  return 0;
});

const { t, toUEC } = useI18n();

const tPrice = (price: number) => {
  return toUEC(price, t("labels.uecPerUnit"));
};
</script>

<script lang="ts">
export default {
  name: "TradeRouteProfit",
};
</script>

<template>
  <div class="profit">
    <!-- eslint-disable-next-line vue/no-v-html -->
    <span v-if="availableCargo" v-html="tPrice(profit * availableCargo)" />
    <!-- eslint-disable-next-line vue/no-v-html -->
    <span v-else v-html="tPrice(profit)" />
    <small class="profit-percent">({{ profitPerUnitPercent }} %)</small>
  </div>
</template>
