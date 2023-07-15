<template>
  <AsyncData :is-error="isError" :is-loading="isLoading || isFetching">
    <template #resolved>
      <section class="container">
        <div class="row">
          <div class="col-12 col-md-8">
            <BreadCrumbs :crumbs="crumbs" />
            <h1 v-if="station">
              {{ station.name }}
            </h1>
          </div>
          <div class="col-12 col-md-4">
            <div class="page-actions page-actions-right">
              <PriceModalBtn
                v-if="station && station.shops?.length"
                :station-slug="station.slug"
              />
            </div>
          </div>
        </div>
        <div class="row">
          <div v-if="station" class="col-12 col-lg-8">
            <img
              v-if="station.media.storeImage"
              :src="station.media.storeImage.large"
              class="image"
              alt="model image"
            />
            <blockquote v-if="station.description" class="description">
              <p v-html="station.description" />
            </blockquote>
          </div>
          <div v-if="station" class="col-12 col-lg-4">
            <Panel>
              <StationBaseMetrics :station="station" :padding="true" />
              <StationDocks :station="station" :padding="true" />
              <StationHabitations :station="station" :padding="true" />
            </Panel>
            <div class="text-right">
              <div class="page-actions page-actions-right">
                <Btn
                  v-if="station.hasImages"
                  :to="{
                    name: 'station-images',
                    params: { slug: station.slug },
                  }"
                >
                  <i class="fa fa-images" />
                </Btn>
              </div>
            </div>
          </div>
        </div>
        <div class="row">
          <div class="col-12">
            <template v-if="station && station.shops?.length">
              <h2>{{ t("headlines.shops") }}</h2>
              <transition-group name="fade-list" class="row" tag="div" appear>
                <div
                  v-for="shop in station.shops"
                  :key="shop.slug"
                  class="col-12 col-lg-3 fade-list-item"
                >
                  <ShopPanel
                    :item="shop"
                    :route="{
                      name: 'shop',
                      params: {
                        stationSlug: station.slug,
                        slug: shop.slug,
                      },
                    }"
                  />
                </div>
              </transition-group>
              <Loader :loading="loading" :fixed="true" />
            </template>
          </div>
        </div>
      </section>
    </template>
  </AsyncData>
</template>

<script lang="ts" setup>
import Loader from "@/frontend/core/components/Loader/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import PriceModalBtn from "@/frontend/components/ShopCommodities/PriceModalBtn/index.vue";
import Panel from "@/frontend/core/components/Panel/index.vue";
import ShopPanel from "@/frontend/components/Stations/Item/index.vue";
import StationBaseMetrics from "@/frontend/components/Stations/BaseMetrics/index.vue";
import StationDocks from "@/frontend/components/Stations/Docks/index.vue";
import StationHabitations from "@/frontend/components/Stations/Habitations/index.vue";
import BreadCrumbs from "@/frontend/core/components/BreadCrumbs/index.vue";
import AsyncData from "@/frontend/core/components/AsyncData.vue";
import type { Crumb } from "@/frontend/core/components/BreadCrumbs/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useRoute } from "vue-router/composables";
import { useMetaInfo } from "@/frontend/composables/useMetaInfo";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useQuery } from "@tanstack/vue-query";

const { updateMetaInfo } = useMetaInfo();

const { t } = useI18n();

const loading = ref(false);

const crumbs = computed(() => {
  if (!station.value) {
    return undefined;
  }

  const crumbs: Crumb[] = [
    {
      to: {
        name: "starsystems",
        hash: `#${station.value.celestialObject.starsystem?.slug}`,
      },
      label: t("nav.starsystems"),
    },
    {
      to: {
        name: "starsystem",
        params: {
          slug: station.value.celestialObject.starsystem?.slug,
        },
        hash: `#${station.value.celestialObject.slug}`,
      },
      label: station.value.celestialObject.starsystem?.name,
    },
  ];

  if (station.value.celestialObject.parent) {
    crumbs.push({
      to: {
        name: "celestial-object",
        params: {
          starsystem: station.value.celestialObject.starsystem?.slug,
          slug: station.value.celestialObject.parent.slug,
        },
      },
      label: station.value.celestialObject.parent.name,
    });
  }

  crumbs.push({
    to: {
      name: "celestial-object",
      params: {
        starsystem: station.value.celestialObject.starsystem?.slug,
        slug: station.value.celestialObject.slug,
      },
      hash: `#${station.value.slug}`,
    },
    label: station.value.celestialObject.name,
  });

  return crumbs;
});

const { stations } = useApiClient();

const route = useRoute();

const {
  isLoading,
  isFetching,
  isError,
  data: station,
} = useQuery({
  queryKey: ["station", route.params.slug],
  queryFn: () => stations.get({ slug: route.params.slug }),
});

watch(
  () => station.value,
  () => {
    if (!station.value) {
      return;
    }

    updateMetaInfo({
      title: t("title.station", {
        station: station.value.name,
        celestialObject: station.value.celestialObject.name,
      }),
      description: station.value.description || undefined,
      image: station.value.media.storeImage?.medium || undefined,
      type: "article",
    });
  }
);
</script>

<script lang="ts">
export default {
  name: "StationPage",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
