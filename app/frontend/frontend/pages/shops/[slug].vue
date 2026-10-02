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
import LocationKindIcon from "@/frontend/components/Locations/KindIcon/index.vue";
import ShopListing from "@/frontend/components/Shops/Listing/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
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
            <ShopListing :items="shop.items" />
          </div>

          <aside class="location-page__aside">
            <section class="location-page__panel">
              <h2 class="location-page__panel-title">
                {{ t("labels.shopPage.facts") }}
              </h2>

              <dl class="shop-facts" data-test="shop-facts">
                <div class="shop-facts__fact">
                  <dt>{{ t("labels.shopPage.place") }}</dt>
                  <dd>
                    <router-link
                      :to="{
                        name: 'location',
                        params: { slug: shop.location.slug },
                      }"
                    >
                      <LocationKindIcon :kind="shop.location.kind" />
                      {{ shop.location.name }}
                    </router-link>
                  </dd>
                </div>

                <div v-if="shop.system" class="shop-facts__fact">
                  <dt>{{ t("labels.shopPage.system") }}</dt>
                  <dd>
                    <router-link
                      :to="{
                        name: 'location',
                        params: { slug: shop.system.slug },
                      }"
                    >
                      {{ shop.system.name }}
                    </router-link>
                  </dd>
                </div>

                <div class="shop-facts__fact">
                  <dt>{{ t("labels.shopPage.carries") }}</dt>
                  <dd class="shop-facts__counts">
                    <span v-for="entry in shop.counts" :key="entry.itemType">
                      {{ t(`labels.location.shopItemTypes.${entry.itemType}`) }}
                      <strong>{{ entry.count }}</strong>
                    </span>
                  </dd>
                </div>
              </dl>

              <p class="shop-facts__source">
                {{ t("labels.shopPage.source") }}
              </p>
            </section>
          </aside>
        </div>
      </div>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
@import "@/frontend/pages/locations/index";

.shop-facts {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin: 0;

  &__fact {
    display: grid;
    grid-template-columns: 7em minmax(0, 1fr);
    gap: 8px;

    dt {
      font-size: 13px;
      color: var(--color-text-dim, #959595);
    }

    dd {
      margin: 0;
    }

    a {
      display: inline-flex;
      align-items: center;
      gap: 6px;
    }
  }

  &__counts {
    display: flex;
    flex-direction: column;
    gap: 2px;

    strong {
      margin-left: 4px;
      font-variant-numeric: tabular-nums;
    }
  }

  &__source {
    margin: 12px 0 0;
    font-size: 12px;
    color: var(--color-text-dim, #959595);
  }
}
</style>
