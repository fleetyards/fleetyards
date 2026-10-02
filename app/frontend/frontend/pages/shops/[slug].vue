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
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import RowList from "@/shared/components/RowList/index.vue";
import RowsSkeleton from "@/shared/components/RowsSkeleton/index.vue";
import ListToolbar from "@/shared/components/base/ListToolbar/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import ShopFilterForm from "@/frontend/components/Shops/FilterForm/index.vue";
import ShopCategoryFilters from "@/frontend/components/Shops/CategoryFilters/index.vue";
import ShopItemRow from "@/frontend/components/Shops/ItemRow/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { useFilters } from "@/shared/composables/useFilters";
import { usePagination } from "@/shared/composables/usePagination";
import {
  type ShopItem,
  type ShopItemQuery,
  getShopItemsQueryKey,
  useShop,
  useShopItems,
} from "@/services/fyApi";

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

const itemsParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: getQuery(),
}));

const { perPage, page, updatePerPage } = usePagination(
  computed(() => getShopItemsQueryKey(slug, itemsParams)),
);

const { isFilterSelected, getQuery } = useFilters<ShopItemQuery>({
  updateCallback: async () => {
    await refetch();
  },
});

const {
  data: items,
  refetch,
  ...itemsStatus
} = useShopItems(slug, itemsParams);

const sortFields = computed<BaseTableCol<ShopItem>[]>(() => [
  { name: "name", label: t("labels.shopPage.sortName"), sortable: true },
  { name: "price", label: t("labels.shopPage.sortPrice"), sortable: true },
]);

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
            <FilteredList
              name="shop-items"
              :records="items?.items ?? []"
              :async-status="itemsStatus"
              :is-filter-selected="isFilterSelected"
            >
              <template #filter>
                <ShopFilterForm :categories="shop.categories" />
              </template>

              <template #pagination-top>
                <Paginator
                  :query-result-ref="items"
                  :per-page="perPage"
                  @update-per-page="updatePerPage"
                />
              </template>

              <template #skeleton="{ count }">
                <RowsSkeleton :count="count" icon meta trailing />
              </template>

              <template #sort>
                <ShopCategoryFilters
                  :categories="shop.categories"
                  :total="shop.itemsCount"
                />
                <ListToolbar :columns="sortFields" default-sort="name asc" />
              </template>

              <template #default="{ records, emptyVisible: listEmpty }">
                <RowList
                  :records="records"
                  :empty-visible="listEmpty"
                  :empty-name="t('labels.shopPage.emptyName')"
                >
                  <template #default="{ record }">
                    <ShopItemRow :item="record" />
                  </template>
                </RowList>
              </template>

              <template #pagination-bottom>
                <Paginator
                  :query-result-ref="items"
                  :per-page="perPage"
                  @update-per-page="updatePerPage"
                />
              </template>
            </FilteredList>
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

.shop-facts {
  &__source {
    margin: 12px 0 0;
    font-size: 12px;
    color: var(--color-text-dim, #959595);
  }
}
</style>
