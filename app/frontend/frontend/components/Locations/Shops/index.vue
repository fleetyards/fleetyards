<script lang="ts">
export default {
  name: "LocationShops",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { type LocationShop } from "@/services/fyApi";

type Props = {
  shops: LocationShop[];
};

defineProps<Props>();

const { t } = useI18n();

// What a shop sells, largest first: "Clothing · Coolers". How many of each is
// the shop's own page to say. A ship has no finer kind than being a ship.
const carries = (shop: LocationShop) =>
  shop.categories
    .map(
      (category) =>
        category.label ??
        t(`labels.location.shopItemTypes.${category.itemType}`),
    )
    .join(" · ");
</script>

<!-- A place's shops, in the shape of its contents groups: a heading like
     "Station · 9", then a tile per shop that opens its own page. -->
<template>
  <section class="location-shops" data-test="location-shops">
    <h2 class="location-shops__title">
      <i class="fa-duotone fa-store" aria-hidden="true" />
      {{ t("labels.location.shops") }} · {{ shops.length }}
    </h2>

    <ul class="location-shops__grid">
      <li v-for="shop in shops" :key="shop.id">
        <router-link
          :to="{ name: 'shop', params: { slug: shop.slug } }"
          class="location-shops__tile"
        >
          <img
            v-if="shop.image"
            :src="shop.image.smallUrl ?? shop.image.url"
            alt=""
            class="location-shops__thumb"
          />
          <span class="location-shops__body">
            <span class="location-shops__name">{{ shop.name }}</span>
            <span class="location-shops__carries">{{ carries(shop) }}</span>
          </span>
        </router-link>
      </li>
    </ul>
  </section>
</template>

<style lang="scss" scoped>
@import "index";
</style>
