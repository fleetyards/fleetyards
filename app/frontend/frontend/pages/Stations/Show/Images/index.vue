<template>
  <section class="container">
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12">
            <BreadCrumbs :crumbs="crumbs" />
            <h1>
              {{ metaTitle }}
            </h1>
          </div>
        </div>
      </div>
    </div>
    <FilteredList
      :collection="collection"
      collection-method="findAllForGallery"
      :name="route.name"
      :route-query="route.query"
      :hash="route.hash"
      :params="routeParams"
      :paginated="true"
      class="images"
    >
      <template #default="{ records, loading, filterVisible, primaryKey }">
        <FilteredGrid
          :records="records"
          :loading="loading"
          :filter-visible="filterVisible"
          :primary-key="primaryKey"
        >
          <template #default="{ record, index }">
            <GalleryImage
              :src="record.smallUrl"
              :href="record.url"
              :alt="record.name"
              :title="record.caption || record.name"
              @click.native.prevent.exact="openGallery(index)"
            />
          </template>
        </FilteredGrid>
      </template>
    </FilteredList>

    <Gallery ref="gallery" :items="collection.records" />
  </section>
</template>

<script lang="ts" setup>
import { ref, computed } from "vue";
import { useRoute } from "vue-router/composables";
import FilteredList from "@/frontend/core/components/FilteredList/index.vue";
import FilteredGrid from "@/frontend/core/components/FilteredGrid/index.vue";
import BreadCrumbs from "@/frontend/core/components/BreadCrumbs/index.vue";
import Gallery from "@/frontend/core/components/Gallery/index.vue";
import GalleryImage from "@/frontend/core/components/Gallery/Image/index.vue";
import imagesCollection from "@/frontend/api/collections/Images";
import stationsCollection from "@/frontend/api/collections/Stations";
import { stationRouteGuard } from "@/frontend/utils/RouteGuards/Stations";
import { useI18n } from "@/frontend/composables/useI18n";
import { useMetaInfo } from "@/frontend/composables/useMetaInfo";
import type { TBreadCrumb } from "@/@types/breadcrumbs";

const collection = imagesCollection;

const station = computed(() => stationsCollection.record);

const { t } = useI18n();

const metaTitle = computed(() => {
  if (!station.value) {
    return undefined;
  }

  return t("title.stationImages", {
    station: station.value.name,
    celestialObject: station.value.celestialObject.name,
  });
});

useMetaInfo(metaTitle);

const route = useRoute();

const routeParams = computed(() => ({
  ...route.params,
  galleryType: "stations",
}));

const crumbs = computed(() => {
  if (!station.value) {
    return null;
  }

  const crumbs: TBreadCrumb[] = [
    {
      to: {
        name: "starsystems",
        hash: `#${station.value.celestialObject.starsystem.slug}`,
      },
      label: t("nav.starsystems"),
    },
    {
      to: {
        name: "starsystem",
        params: {
          slug: station.value.celestialObject.starsystem.slug,
        },
        hash: `#${station.value.celestialObject.slug}`,
      },
      label: station.value.celestialObject.starsystem.name,
    },
  ];

  if (station.value.celestialObject.parent) {
    crumbs.push({
      to: {
        name: "celestial-object",
        params: {
          starsystem: station.value.celestialObject.starsystem.slug,
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
        starsystem: station.value.celestialObject.starsystem.slug,
        slug: station.value.celestialObject.slug,
      },
      hash: `#${station.value.slug}`,
    },
    label: station.value.celestialObject.name,
  });

  crumbs.push({
    to: {
      name: "station",
      params: {
        slug: station.value.slug,
      },
    },
    label: station.value.name,
  });

  return crumbs;
});

const gallery = ref<InstanceType<typeof Gallery> | null>(null);

const openGallery = (index: number) => {
  gallery.value?.open(index);
};
</script>

<script lang="ts">
export default {
  name: "ModelImagesPage",
  beforeRouteEnter: stationRouteGuard,
};
</script>
