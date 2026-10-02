<script lang="ts">
export default {
  name: "ShopListing",
};
</script>

<script lang="ts" setup>
import { type RouteLocationRaw } from "vue-router";
import { useI18n } from "@/shared/composables/useI18n";
import { type ShopItem, type ShopItemPrice } from "@/services/fyApi";

type Props = {
  items: ShopItem[];
};

const props = defineProps<Props>();

const { t, toUEC } = useI18n();

// One group per kind of thing, the largest first: a counter that rents ships
// and sells a few paints reads as a ship rental.
const groups = computed(() => {
  const byType = new Map<string, ShopItem[]>();

  props.items.forEach((item) => {
    byType.set(item.itemType, [...(byType.get(item.itemType) ?? []), item]);
  });

  return [...byType.entries()]
    .map(([itemType, items]) => ({ itemType, items }))
    .sort((a, b) => b.items.length - a.items.length);
});

const ITEM_ROUTES: Record<string, string> = {
  Model: "ship",
  Equipment: "equipment-item",
  Component: "component",
  Commodity: "commodity",
};

const itemLink = (item: ShopItem): RouteLocationRaw | undefined => {
  const name = ITEM_ROUTES[item.itemType];

  return name && item.slug ? { name, params: { slug: item.slug } } : undefined;
};

// Shop-perspective, as everywhere: `sell` is the shop selling it, which is
// the player buying.
const PRICE_LABELS: Record<string, string> = {
  sell: "labels.availability.buy",
  rental: "labels.availability.rent",
  buy: "labels.availability.sell",
};

const priceLabel = (price: ShopItemPrice) => {
  const label = t(PRICE_LABELS[price.priceType] ?? PRICE_LABELS.sell);

  return price.timeRange
    ? `${label} · ${t(`labels.availability.timeRange.${price.timeRange}`)}`
    : label;
};
</script>

<template>
  <div class="shop-listing">
    <section
      v-for="group in groups"
      :key="group.itemType"
      class="shop-listing__group"
    >
      <h2 class="shop-listing__title">
        {{ t(`labels.location.shopItemTypes.${group.itemType}`) }} ·
        {{ group.items.length }}
      </h2>

      <ul class="shop-listing__items">
        <li
          v-for="item in group.items"
          :key="item.id"
          class="shop-listing__item"
          data-test="shop-item"
        >
          <router-link
            v-if="itemLink(item)"
            :to="itemLink(item)!"
            class="shop-listing__name"
          >
            {{ item.name }}
          </router-link>
          <span v-else class="shop-listing__name">{{ item.name }}</span>

          <span class="shop-listing__prices">
            <span
              v-for="(price, index) in item.prices"
              :key="index"
              class="shop-listing__price"
            >
              <span class="shop-listing__price-label">
                {{ priceLabel(price) }}
              </span>
              <!-- eslint-disable-next-line vue/no-v-html -- toUEC wraps its unit in markup, from a number -->
              <span v-html="toUEC(price.price)" />
            </span>
          </span>
        </li>
      </ul>
    </section>
  </div>
</template>

<style lang="scss" scoped>
.shop-listing {
  display: flex;
  flex-direction: column;
  gap: 20px;

  &__group {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  &__title {
    margin: 0;
    padding: 0 2px;
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 13px;
    font-weight: 500;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: var(--color-text-dim, #959595);
  }

  &__items {
    margin: 0;
    padding: 0;
    list-style: none;
    background-color: var(--color-control, rgb(39 43 48 / 0.9));
    border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
    border-radius: 8px;
    overflow: hidden;
  }

  &__item {
    display: flex;
    flex-wrap: wrap;
    align-items: baseline;
    justify-content: space-between;
    gap: 2px 16px;
    padding: 8px 12px;

    &:nth-child(even) {
      background-color: rgb(0 0 0 / 0.14);
    }
  }

  &__name {
    min-width: 0;
    color: var(--color-text, #c8c8c8);
    font-weight: 600;
  }

  a.shop-listing__name:hover,
  a.shop-listing__name:focus-visible {
    color: #fff;
  }

  &__prices {
    display: flex;
    flex-wrap: wrap;
    gap: 2px 16px;
    font-size: 13px;
    font-variant-numeric: tabular-nums;
  }

  &__price-label {
    margin-right: 6px;
    font-size: 12px;
    color: var(--color-text-dim, #959595);
  }
}
</style>
