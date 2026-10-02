<script lang="ts">
export default {
  name: "LocationShops",
};
</script>

<script lang="ts" setup>
import { type RouteLocationRaw } from "vue-router";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type LocationShop,
  type LocationShopItem,
  type LocationShopItemPrice,
} from "@/services/fyApi";

type Props = {
  shops: LocationShop[];
};

defineProps<Props>();

const { t, toUEC } = useI18n();

// Closed by default: Everus Harbor's six shops hold over 500 prices.
const open = ref<Record<string, boolean>>({});

const toggle = (shop: LocationShop) => {
  open.value = { ...open.value, [shop.name]: !open.value[shop.name] };
};

const ITEM_ROUTES: Record<string, string> = {
  Model: "ship",
  Equipment: "equipment-item",
  Component: "component",
  Commodity: "commodity",
};

const itemLink = (item: LocationShopItem): RouteLocationRaw | undefined => {
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

const priceLabel = (price: LocationShopItemPrice) => {
  const label = t(PRICE_LABELS[price.priceType] ?? PRICE_LABELS.sell);

  return price.timeRange
    ? `${label} · ${t(`labels.availability.timeRange.${price.timeRange}`)}`
    : label;
};
</script>

<template>
  <section class="location-shops" data-test="location-shops">
    <h2 class="location-shops__title">
      <i class="fa-duotone fa-store" aria-hidden="true" />
      {{ t("labels.location.shops") }} · {{ shops.length }}
    </h2>

    <div v-for="shop in shops" :key="shop.name" class="location-shops__shop">
      <button
        type="button"
        class="location-shops__head"
        :aria-expanded="!!open[shop.name]"
        @click="toggle(shop)"
      >
        <span class="location-shops__name">{{ shop.name }}</span>
        <span class="location-shops__count">
          {{ t("labels.location.shopItems", { count: shop.itemsCount }) }}
        </span>
        <i
          class="fa-light fa-chevron-down location-shops__chevron"
          :class="{ 'location-shops__chevron--open': open[shop.name] }"
          aria-hidden="true"
        />
      </button>

      <ul v-if="open[shop.name]" class="location-shops__items">
        <li
          v-for="item in shop.items"
          :key="item.id"
          class="location-shops__item"
        >
          <router-link
            v-if="itemLink(item)"
            :to="itemLink(item)!"
            class="location-shops__item-name"
          >
            {{ item.name }}
          </router-link>
          <span v-else class="location-shops__item-name">{{ item.name }}</span>

          <span class="location-shops__item-type">
            {{ t(`labels.location.shopItemTypes.${item.itemType}`) }}
          </span>

          <span class="location-shops__prices">
            <span
              v-for="(price, index) in item.prices"
              :key="index"
              class="location-shops__price"
            >
              <span class="location-shops__price-label">
                {{ priceLabel(price) }}
              </span>
              <!-- eslint-disable-next-line vue/no-v-html -- toUEC wraps its unit in markup, from a number -->
              <span v-html="toUEC(price.price)" />
            </span>
          </span>
        </li>
      </ul>
    </div>
  </section>
</template>

<style lang="scss" scoped>
@import "index";
</style>
