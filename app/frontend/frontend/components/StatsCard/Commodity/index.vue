<script lang="ts">
export default {
  name: "CommodityStatsCard",
};
</script>

<script lang="ts" setup>
import { type RouteLocationRaw } from "vue-router";
import StatsCard from "@/frontend/components/StatsCard/index.vue";
import { type StatsCardBadge } from "@/frontend/components/StatsCard/types";
import { useCommodityStats } from "@/frontend/composables/useCommodityStats";
import { useI18n } from "@/shared/composables/useI18n";
import { type Commodity } from "@/services/fyApi";

type Props = {
  commodity?: Commodity;
  compact?: boolean;
  // What the card is titled while its record is missing, since a compact card
  // otherwise takes its title from the record.
  name?: string;
  // Where the card's detail link goes, when the caller knows better than the
  // record -- a reference can say the catalogue does not list it. `false`
  // drops the link.
  to?: RouteLocationRaw | false;
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  commodity: undefined,
  compact: false,
  name: undefined,
  to: undefined,
  loading: false,
});

const emit = defineEmits<{ navigate: [] }>();

const { t, toNumber } = useI18n();

const stats = useCommodityStats(() => props.commodity);

// What it trades at, the way the catalogue row states it. Shop-perspective, as
// `item_prices` stores it: what a terminal sells it for is what the reader
// pays, so `sellPrice` is the figure to buy at. The detail page has the chart
// and the terminals for this, so only the compact card carries it.
const badges = computed<StatsCardBadge[]>(() => {
  const commodity = props.commodity;
  if (!commodity) return [];

  return [
    {
      key: "buy",
      label: t("labels.commodity.buyPrice"),
      value: commodity.sellPrice,
    },
    {
      key: "sell",
      label: t("labels.commodity.sellPrice"),
      value: commodity.buyPrice,
    },
  ].flatMap((badge) =>
    badge.value == null
      ? []
      : [{ ...badge, value: String(toNumber(badge.value, "integer")) }],
  );
});

const ownRoute = computed(() =>
  props.commodity?.slug
    ? { name: "commodity", params: { slug: props.commodity.slug } }
    : undefined,
);
</script>

<template>
  <StatsCard
    :compact="compact"
    :title="
      compact
        ? commodity?.name || name || ''
        : t('headlines.commodity.identity')
    "
    variant="slim"
    :badges="badges"
    :stats="stats"
    :to="to === false ? undefined : (to ?? ownRoute)"
    :loading="loading"
    :unavailable="compact && !loading && !commodity"
    @navigate="emit('navigate')"
  >
    <template v-if="$slots.rows" #rows>
      <slot name="rows" />
    </template>
    <slot />
  </StatsCard>
</template>
