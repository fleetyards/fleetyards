<template>
  <section class="container">
    <div class="row">
      <div class="col-12 col-md-8">
        <BreadCrumbs :crumbs="crumbs" />
        <h1 v-if="shop">
          {{ shop.name }}
          <small class="text-muted">{{ shop.location }}</small>
        </h1>
      </div>
      <div class="col-12 col-md-4">
        <div class="page-actions page-actions-right">
          <PriceModalBtn
            v-if="shop"
            :station-slug="shop.station.slug"
            :shop-id="shop.id"
          />
        </div>
      </div>
    </div>
    <div class="row">
      <div v-if="shop" class="col-12 col-lg-8">
        <blockquote v-if="shop.description" class="description">
          <p v-html="shop.description" />
        </blockquote>
      </div>
      <div v-if="shop" class="col-12 col-lg-4">
        <Panel>
          <ShopBaseMetrics :shop="shop" padding />
        </Panel>
      </div>
    </div>

    <FilteredList
      key="shop"
      :collection="collection"
      :name="route.name"
      :route-query="route.query"
      :params="route.params"
      :hash="route.hash"
      :paginated="true"
      :hide-empty-box="true"
      :hide-loading="true"
    >
      <FilterForm slot="filter" />

      <template v-if="!mobile" slot="actions">
        <Btn
          v-for="item in subCategories"
          :key="item.value"
          size="small"
          :class="{
            active: (subCategory || []).includes(item.value),
          }"
          @click.native="toggleSubcategory(item.value)"
        >
          {{ item.name }}
        </Btn>
      </template>

      <template #default="{ records, loading, emptyBoxVisible, primaryKey }">
        <FilteredTable
          :records="records"
          :primary-key="primaryKey"
          :columns="tableColumns"
          :loading="loading"
          :empty-box-visible="emptyBoxVisible"
        >
          <template #col-store_image="{ record }">
            <router-link
              v-if="record.category === 'model'"
              :to="{
                name: 'model',
                params: {
                  slug: record.slug,
                },
              }"
            >
              <div
                :key="record.storeImageSmall"
                v-lazy:background-image="record.storeImageSmall"
                class="image lazy"
                alt="storeImage"
              />
            </router-link>
            <div
              v-else
              :key="record.storeImageSmall"
              v-lazy:background-image="record.storeImageSmall"
              class="image lazy"
              alt="storeImage"
            />
          </template>
          <template #col-description="{ record }">
            <h2>
              <router-link v-if="link(record)" :to="link(record)">
                <span v-html="name(record)" />
              </router-link>
              <span v-else v-html="name(record)" />
              <small class="text-muted">{{ record.subCategoryLabel }}</small>
            </h2>
            <div class="row">
              <div class="col-12 col-lg-6">
                <ul class="list-unstyled">
                  <li v-if="record.item.grade">
                    <b>{{ $t("commodityItem.grade") }}:</b>
                    {{ record.item.grade }}
                  </li>
                  <li v-if="record.item.size">
                    <b>{{ $t("commodityItem.size") }}:</b>
                    {{ record.item.size }}
                  </li>
                  <li v-if="record.item.typeLabel">
                    <b>{{ $t("commodityItem.type") }}:</b>
                    {{ record.item.typeLabel }}
                  </li>
                  <li v-if="record.item.itemTypeLabel">
                    <b>{{ $t("commodityItem.itemType") }}:</b>
                    {{ record.item.itemTypeLabel }}
                  </li>
                  <li v-if="record.item.weaponClassLabel">
                    <b>{{ $t("commodityItem.weaponClass") }}:</b>
                    {{ record.item.weaponClassLabel }}
                  </li>
                  <li v-if="record.item.itemClassLabel">
                    <b>{{ $t("commodityItem.itemClass") }}:</b>
                    {{ record.item.itemClassLabel }}
                  </li>
                </ul>
              </div>
              <div class="col-12 col-lg-6">
                <ul class="list-unstyled">
                  <li v-if="record.item.range">
                    <b>{{ $t("commodityItem.range") }}:</b>
                    {{ $toNumber(record.item.range, "distance") }}
                  </li>
                  <li v-if="record.item.damageReduction">
                    <b>{{ $t("commodityItem.damageReduction") }}:</b>
                    {{ $toNumber(record.item.damageReduction, "percent") }}
                  </li>
                  <li v-if="record.item.rateOfFire">
                    <b>{{ $t("commodityItem.rateOfFire") }}:</b>
                    {{ $toNumber(record.item.rateOfFire, "rateOfFire") }}
                  </li>
                  <li v-if="record.item.extras">
                    {{ record.item.extras }}
                  </li>
                </ul>
              </div>
            </div>
            {{ record.description }}
          </template>
          <template #col-buy_price="{ record }">
            <span v-if="mobile" class="price-label">
              {{ $t("labels.shopCommodity.prices.buyPrice") }}:&nbsp;
            </span>
            <b v-html="$toUEC(record.buyPrice)" />
          </template>
          <template #col-sell_price="{ record }">
            <span v-if="mobile" class="price-label">
              {{ $t("labels.shopCommodity.prices.sellPrice") }}:&nbsp;
            </span>
            <b v-html="$toUEC(record.sellPrice)" />
          </template>
          <template #col-rental_price="{ record }">
            <span v-if="mobile" class="price-label">
              {{ $t("labels.shopCommodity.prices.rentalPrice") }}:&nbsp;
            </span>
            <ul class="list-unstyled">
              <li v-if="record.rentalPrice1Day">
                {{ $t("labels.shopCommodity.prices.rentalPrice1Day") }}
                <b v-html="$toUEC(record.rentalPrice1Day)" />
              </li>
              <li v-if="record.rentalPrice3Days">
                {{ $t("labels.shopCommodity.prices.rentalPrice3Days") }}
                <b v-html="$toUEC(record.rentalPrice3Days)" />
              </li>
              <li v-if="record.rentalPrice7Days">
                {{ $t("labels.shopCommodity.prices.rentalPrice7Days") }}
                <b v-html="$toUEC(record.rentalPrice7Days)" />
              </li>
              <li v-if="record.rentalPrice30Days">
                {{ $t("labels.shopCommodity.prices.rentalPrice30Days") }}
                <b v-html="$toUEC(record.rentalPrice30Days)" />
              </li>
            </ul>
          </template>
          <template #col-actions="{ record }">
            <AddToCartBtn
              :item="record.item"
              :type="record.commodityItemType"
            />
          </template>
        </FilteredTable>
      </template>
    </FilteredList>
  </section>
</template>

<script lang="ts" setup>
import { ref, computed, onMounted } from "vue";
import { useRoute, useRouter } from "vue-router/composables";
import Panel from "@/frontend/core/components/Panel/index.vue";
import PriceModalBtn from "@/frontend/components/ShopCommodities/PriceModalBtn/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import shopCommoditiesCollection from "@/frontend/api/collections/ShopCommodities";
import shopsCollection from "@/frontend/api/collections/Shops";
import AddToCartBtn from "@/frontend/core/components/AppShoppingCart/AddToCartBtn/index.vue";
import { shopRouteGuard } from "@/frontend/utils/RouteGuards/Shops";
import BreadCrumbs from "@/frontend/core/components/BreadCrumbs/index.vue";
import FilteredTable from "@/frontend/core/components/FilteredTable/index.vue";
import FilteredList from "@/frontend/core/components/FilteredList/index.vue";
import FilterForm from "@/frontend/components/Shops/ShopItemFilterForm/index.vue";
import ShopBaseMetrics from "@/frontend/components/Shops/BaseMetrics/index.vue";
import { storeToRefs } from "pinia";
import { useAppStore } from "@/frontend/stores/App";
import { useI18n } from "@/frontend/composables/useI18n";
import { useMetaInfo } from "@/frontend/composables/useMetaInfo";
import { TBreadCrumb } from "@/@types/breadcrumbs";
import type { FilteredTableColumn } from "@/frontend/core/components/FilteredTable/index.vue";
import type { FleetYardsLocation } from "@/frontend/utils/Sorting";

const collection = shopCommoditiesCollection;

const subCategories = ref<TShopCommoditySubCategroy[]>([]);

const appStore = useAppStore();

const { mobile } = storeToRefs(appStore);

const shop = computed(() => shopsCollection.record);

const { t } = useI18n();

const tableColumns = computed<FilteredTableColumn[]>(() => {
  const columns: FilteredTableColumn[] = [
    { name: "store_image", class: "store-image" },
    { name: "description", class: "description" },
  ];

  if (shop.value) {
    if (shop.value.buying) {
      columns.push({
        name: "buy_price",
        label: t("labels.shop.buyPrice"),
        class: "price",
      });
    }

    if (shop.value.selling) {
      columns.push({
        name: "sell_price",
        label: t("labels.shop.sellPrice"),
        class: "price",
      });
    }

    if (shop.value.rental) {
      columns.push({
        name: "rental_price",
        label: t("labels.shop.rentalPrice"),
        class: "rent-price",
      });
    }
  }

  columns.push({ name: "actions", class: "actions actions-1x" });

  return columns;
});

const metaTitle = computed(() => {
  if (!shop.value) {
    return undefined;
  }

  return t("title.shop", {
    shop: shop.value.name,
    station: shop.value.station.name,
  });
});

useMetaInfo(metaTitle);

const route = useRoute();

const query = computed(() => {
  if (!route.query || !route.query.q) {
    return null;
  }

  return route.query.q as Partial<TShopCommoditiesFilter>;
});

const subCategory = computed(() => {
  if (!query.value?.subCategoryIn) {
    return null;
  }

  return query.value.subCategoryIn;
});

const crumbs = computed(() => {
  if (!shop.value) {
    return null;
  }

  const crumbs: TBreadCrumb[] = [
    {
      to: {
        name: "starsystems",
        hash: `#${shop.value.celestialObject.starsystem.slug}`,
      },
      label: t("nav.starsystems"),
    },
    {
      to: {
        name: "starsystem",
        params: {
          slug: shop.value.celestialObject.starsystem.slug,
        },
        hash: `#${shop.value.celestialObject.slug}`,
      },
      label: shop.value.celestialObject.starsystem.name,
    },
  ];

  if (shop.value.celestialObject.parent) {
    crumbs.push({
      to: {
        name: "celestial-object",
        params: {
          starsystem: shop.value.celestialObject.starsystem.slug,
          slug: shop.value.celestialObject.parent.slug,
        },
      },
      label: shop.value.celestialObject.parent.name,
    });
  }

  crumbs.push({
    to: {
      name: "celestial-object",
      params: {
        starsystem: shop.value.celestialObject.starsystem.slug,
        slug: shop.value.celestialObject.slug,
      },
      hash: `#${shop.value.station.slug}`,
    },
    label: shop.value.celestialObject.name,
  });

  crumbs.push({
    to: {
      name: "station",
      params: {
        slug: shop.value.station.slug,
      },
    },
    label: shop.value.station.name,
  });

  return crumbs;
});

const fetchSubCategories = async () => {
  if (!shop.value) {
    return;
  }

  const response = await shopCommoditiesCollection.subCategories(
    shop.value.station.slug,
    shop.value.slug
  );

  if (!response) {
    subCategories.value = response;
  }
};

onMounted(() => {
  if (shop.value) {
    fetchSubCategories();
  }
});

const manufacturer = (record) => {
  if (!record.item || !record.item.manufacturer) {
    return null;
  }

  return record.item.manufacturer;
};

const name = (record) => {
  if (manufacturer(record)) {
    if (manufacturer(record).code) {
      return `${manufacturer(record).code} ${record.name}`;
    }
    return `${manufacturer(record).name} ${record.name}`;
  }

  return record.name;
};

const link = (record) => {
  if (record.category !== "model") {
    return null;
  }

  return {
    name: "model",
    params: {
      slug: record.slug,
    },
  };
};

const router = useRouter();

const toggleSubcategory = (value) => {
  if (!route.name) {
    return;
  }

  if ((subCategory.value || []).includes(value)) {
    const q = {
      ...JSON.parse(JSON.stringify(route.query.q)),
    };

    delete q.subCategoryIn;

    router
      .replace({
        name: route.name,
        query: {
          ...route.query,
          q: {
            ...q,
          },
        },
      })
      .catch((err) => {
        console.info(err);
      });
  } else {
    const newQuery: Partial<TShopCommoditiesFilter> = {
      ...query.value,
      subCategoryIn: [value],
    };

    router
      .replace({
        name: route.name,
        query: {
          ...route.query,
          q: newQuery,
        },
      } as FleetYardsLocation)
      .catch((err) => {
        console.info(err);
      });
  }
};
</script>

<script lang="ts">
export default {
  name: "ShopDetailPage",
  beforeRouteEnter: shopRouteGuard,
};
</script>
