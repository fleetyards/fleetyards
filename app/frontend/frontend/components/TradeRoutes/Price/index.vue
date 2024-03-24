<script lang="ts" setup>
import { type TradeRoute } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  tradeRoute: TradeRoute;
  priceType?: "buy" | "sell";
  availableCargo?: number;
  average?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  priceType: "buy",
  availableCargo: undefined,
  average: false,
});

const priceTypeCapitalized = computed(() => {
  return props.priceType.charAt(0).toUpperCase() + props.priceType.slice(1);
});

const price = computed(() => {
  if (props.average) {
    return props.tradeRoute[
      `average${priceTypeCapitalized.value}Price` as keyof TradeRoute
    ] as number;
  }

  return props.tradeRoute[`${props.priceType}Price`] as number;
});

const { t, toUEC } = useI18n();

const tPrice = (price: number) => {
  return toUEC(price, t("labels.uecPerUnit"));
};

const tPriceLong = (price: number) => {
  return t(`labels.tradeRoutes.${props.priceType}`, {
    uec: tPrice(price),
  });
};
</script>

<script lang="ts">
export default {
  name: "TradeRoutePrice",
};
</script>

<template>
  <div>
    <template v-if="availableCargo">
      <!-- eslint-disable-next-line vue/no-v-html -->
      <span v-html="tPriceLong(price * availableCargo)" />
      <!-- eslint-disable-next-line vue/no-v-html -->
      <small v-html="tPrice(price)" />
    </template>
    <!-- eslint-disable-next-line vue/no-v-html -->
    <span v-else v-html="tPriceLong(price)" />
  </div>
</template>
