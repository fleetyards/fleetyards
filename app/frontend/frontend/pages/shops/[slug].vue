<script lang="ts">
export default {
  name: "ShopPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import type { Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import ShopStockEquipment from "@/frontend/components/Shops/Stock/Equipment.vue";
import ShopStockComponents from "@/frontend/components/Shops/Stock/Components.vue";
import ShopStockShips from "@/frontend/components/Shops/Stock/Ships.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { type Component } from "vue";
import { useShop } from "@/services/fyApi";

const { t } = useI18n();
const { updateMetaInfo } = useMetaInfo();
const route = useRoute();

const slug = computed(() => route.params.slug as string);

const { data: shop, ...asyncStatus } = useShop(slug);

const crumbs = computed<Crumb[]>(() => [
  { to: { name: "locations" }, label: t("labels.location.allSystems") },
  ...(shop.value?.ancestors ?? []).map((ancestor) => ({
    to: { name: "location", params: { slug: ancestor.slug } },
    label: ancestor.name ?? undefined,
  })),
]);

// What the shop sells, as the catalogue lists it: one list per catalogue, the
// largest first, each narrowed to this shop.
const STOCK_LISTS: Record<string, Component> = {
  Equipment: ShopStockEquipment,
  Component: ShopStockComponents,
  Model: ShopStockShips,
};

const stocks = computed(() => {
  const counts = new Map<string, number>();

  (shop.value?.categories ?? []).forEach((category) => {
    counts.set(
      category.itemType,
      (counts.get(category.itemType) ?? 0) + category.count,
    );
  });

  return [...counts.entries()]
    .filter(([itemType]) => STOCK_LISTS[itemType])
    .map(([itemType, count]) => ({
      itemType,
      count,
      component: STOCK_LISTS[itemType],
    }))
    .sort((a, b) => b.count - a.count);
});

const headerImage = computed(() => {
  const image = shop.value?.image;

  return image ? (image.xlargeUrl ?? image.largeUrl ?? image.url) : undefined;
});

watch(
  () => shop.value,
  (value) => {
    if (!value) return;

    updateMetaInfo({
      title: [value.name, value.location.name].join(" - "),
    });
  },
  { immediate: true },
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <div v-if="shop" class="location-page">
        <div>
          <BreadCrumbs :crumbs="crumbs" />

          <img
            v-if="headerImage"
            :src="headerImage"
            alt=""
            class="location-page__header-image"
            data-test="shop-header-image"
          />

          <div class="location-page__masthead">
            <div class="location-page__title">
              <Heading hero>{{ shop.name }}</Heading>
            </div>

            <div class="location-page__badges">
              <span class="location-page__badge">
                <span class="location-page__badge-label">
                  {{ t("labels.location.kind") }}
                </span>
                <span class="location-page__badge-value">
                  {{ t("labels.shopPage.kind") }}
                </span>
              </span>
              <span class="location-page__badge">
                <span class="location-page__badge-label">
                  {{ t("labels.shopPage.items") }}
                </span>
                <span class="location-page__badge-value">
                  {{ shop.itemsCount }}
                </span>
              </span>
            </div>
          </div>
        </div>

        <div class="location-page__layout">
          <div class="location-page__main">
            <section
              v-for="stock in stocks"
              :key="stock.itemType"
              class="shop-stock"
            >
              <h2 class="shop-stock__title">
                {{ t(`labels.location.shopItemTypes.${stock.itemType}`) }} ·
                {{ stock.count }}
              </h2>
              <component :is="stock.component" :shop="shop.slug" />
            </section>
          </div>

          <aside class="location-page__aside">
            <MetricsCard :title="t('labels.shopPage.facts')" variant="slim">
              <div class="metrics-card__rows" data-test="shop-facts">
                <div class="metrics-card__row">
                  <span class="metrics-card__row__label">
                    {{ t("labels.shopPage.place") }}
                  </span>
                  <span class="metrics-card__row__value">
                    <router-link
                      :to="{
                        name: 'location',
                        params: { slug: shop.location.slug },
                      }"
                    >
                      {{ shop.location.name }}
                    </router-link>
                  </span>
                </div>

                <div v-if="shop.system" class="metrics-card__row">
                  <span class="metrics-card__row__label">
                    {{ t("labels.shopPage.system") }}
                  </span>
                  <span class="metrics-card__row__value">
                    <router-link
                      :to="{
                        name: 'location',
                        params: { slug: shop.system.slug },
                      }"
                    >
                      {{ shop.system.name }}
                    </router-link>
                  </span>
                </div>

                <div
                  v-for="category in shop.categories"
                  :key="`${category.itemType}:${category.key}`"
                  class="metrics-card__row"
                >
                  <span class="metrics-card__row__label">
                    {{
                      category.label ??
                      t(`labels.location.shopItemTypes.${category.itemType}`)
                    }}
                  </span>
                  <span class="metrics-card__row__value">
                    {{ category.count }}
                  </span>
                </div>
              </div>

              <p class="shop-facts__source">
                {{ t("labels.shopPage.source") }}
              </p>
            </MetricsCard>
          </aside>
        </div>
      </div>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
@import "@/frontend/pages/locations/index";
@import "@/shared/components/metricsCard";

.shop-stock {
  display: flex;
  flex-direction: column;
  gap: 8px;

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
}

.shop-facts {
  &__source {
    margin: 12px 0 0;
    font-size: 12px;
    color: var(--color-text-dim, #959595);
  }
}
</style>
