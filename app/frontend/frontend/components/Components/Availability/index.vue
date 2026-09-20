<script lang="ts">
export default {
  name: "ComponentAvailability",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import { type Component } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";

const { t, toNumber } = useI18n();

const comlink = useComlink();

type Props = {
  component: Component;
  // Whether a recipe card follows this one. An unpriced component that can be
  // crafted is not the same answer as one nothing sells and nothing makes, and
  // the page is the only place that knows which it is.
  craftable?: boolean;
  // The recipe lookup is a query of its own, so `craftable` reads false until
  // it answers. Saying "nothing sells this" and then correcting it a moment
  // later is worse than saying nothing for that moment.
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  craftable: false,
  loading: false,
});

// Shop-perspective, as `item_prices` stores it: a shop sells it at `soldAt`,
// which is where a reader buys it, and buys it back at `boughtAt`.
const soldAt = computed(() => props.component.availability?.soldAt ?? []);
const boughtAt = computed(() => props.component.availability?.boughtAt ?? []);

const cheapestBuy = computed(() =>
  soldAt.value.reduce(
    (best, price) => (!best || price.price < best.price ? price : best),
    undefined as (typeof soldAt.value)[number] | undefined,
  ),
);

const bestSale = computed(() =>
  boughtAt.value.reduce(
    (best, price) => (!best || price.price > best.price ? price : best),
    undefined as (typeof boughtAt.value)[number] | undefined,
  ),
);

const hasPrices = computed(() => !!cheapestBuy.value || !!bestSale.value);

const uec = computed(() => t("number.units.uec"));

// Three different answers, and an empty panel gives none of them. A component
// the build has dropped is never offered to the price sync at all, so silence
// there says nothing about what shops stock; for one the build does carry,
// silence is the answer, and whether it can be crafted decides which answer.
const emptyText = computed(() => {
  if (props.component.retired) {
    return t("labels.component.availability.retired");
  }

  return props.craftable
    ? t("labels.component.availability.craftedOnly")
    : t("labels.component.availability.none");
});

const openAvailability = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/AvailabilityModal/index.vue"),
    props: {
      soldAt: soldAt.value,
      boughtAt: boughtAt.value,
    },
  });
};
</script>

<template>
  <MetricsCard
    :title="t('labels.availability.title')"
    variant="slim"
    :loading="loading && !hasPrices"
    data-test="component-availability"
  >
    <template v-if="hasPrices">
      <div class="metrics-card__hero">
        <div
          v-if="cheapestBuy"
          class="metrics-card__tile metrics-card__tile--primary"
        >
          <div class="metrics-card__tile__label">
            {{ t("labels.availability.cheapest.buy") }}
          </div>
          <div class="metrics-card__tile__value">
            {{ toNumber(cheapestBuy.price, "integer") }}
            <span class="metrics-card__tile__unit">{{ uec }}</span>
          </div>
          <div class="metrics-card__tile__sub">
            {{ t("labels.availability.locations", { count: soldAt.length }) }}
          </div>
        </div>

        <div v-if="bestSale" class="metrics-card__tile">
          <div class="metrics-card__tile__label">
            {{ t("labels.availability.bestSale") }}
          </div>
          <div class="metrics-card__tile__value">
            {{ toNumber(bestSale.price, "integer") }}
            <span class="metrics-card__tile__unit">{{ uec }}</span>
          </div>
          <div class="metrics-card__tile__sub">
            {{ t("labels.availability.locations", { count: boughtAt.length }) }}
          </div>
        </div>
      </div>

      <div class="metrics-card__footer">
        <button
          type="button"
          class="metrics-card__toggle"
          data-test="component-availability-all"
          @click="openAvailability"
        >
          {{ t("labels.availability.allLocations") }}
        </button>
      </div>
    </template>

    <p
      v-else-if="!loading"
      class="metrics-card__hint"
      data-test="component-availability-empty"
    >
      {{ emptyText }}
    </p>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

// The card sits in the 340px rail, where two tiles side by side leave a
// six-figure price about 150px to render in and the tile clips it. Stacked
// instead -- and the tiles need their flex reset with the axis, or the 140px
// basis they carry for width becomes 140px of height each.
.metrics-card__hero {
  flex-direction: column;

  .metrics-card__tile {
    flex: none;
  }
}

.metrics-card__hint {
  margin: 0;
}
</style>
