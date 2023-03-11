<template>
  <section class="container">
    <div class="row">
      <div class="col-12">
        <BreadCrumbs :crumbs="crumbs" />
        <h1 v-if="celestialObject">
          {{ celestialObject.name }}
          <small class="text-muted">{{ celestialObject.designation }}</small>
        </h1>
      </div>
    </div>
    <div v-if="celestialObject" class="row">
      <div class="col-12 col-lg-8">
        <blockquote v-if="celestialObject.description" class="description">
          <p v-html="celestialObject.description" />
        </blockquote>
      </div>
      <div class="col-12 col-lg-4">
        <Panel>
          <CelestialObjectMetrics :celestial-object="celestialObject" padding />
        </Panel>
      </div>
    </div>
    <div class="row">
      <div
        v-if="celestialObject && celestialObject.moons.length"
        class="col-12"
      >
        <h2>{{ $t("headlines.moons") }}</h2>
        <transition-group name="fade-list" class="row" tag="div" appear>
          <div
            v-for="moon in celestialObject.moons"
            :key="moon.slug"
            class="col-12 col-md-6 col-lg-3 fade-list-item"
          >
            <ItemPanel
              :item="moon"
              :route="{
                name: 'celestial-object',
                params: {
                  starsystem: celestialObject.starsystem.slug,
                  slug: moon.slug,
                },
              }"
            />
          </div>
        </transition-group>
      </div>
    </div>

    <FilteredList
      v-if="celestialObject"
      key="clestialObjectStations"
      :collection="collection"
      :name="route.name"
      :route-query="route.query"
      :hash="route.hash"
      :params="{ filters: { celestialObjectEq: celestialObject.slug } }"
      :paginated="true"
    >
      <template #headline="{ records }">
        <h2 v-if="records.length">{{ $t("headlines.stations") }}</h2>
      </template>
      <template #default="{ records }">
        <transition-group name="fade-list" class="row" tag="div" appear>
          <div
            v-for="station in records"
            :key="station.slug"
            class="col-12 fade-list-item"
          >
            <StationPanel :station="station" />
          </div>
        </transition-group>
      </template>
    </FilteredList>
  </section>
</template>

<script lang="ts" setup>
import { computed } from "vue";
import Panel from "@/frontend/core/components/Panel/index.vue";
import StationPanel from "@/frontend/components/Stations/Panel/index.vue";
import ItemPanel from "@/frontend/components/Stations/Item/index.vue";
import BreadCrumbs from "@/frontend/core/components/BreadCrumbs/index.vue";
import CelestialObjectMetrics from "@/frontend/components/CelestialObjects/Metrics/index.vue";
import { useMetaInfo } from "@/frontend/composables/useMetaInfo";
import { useRoute } from "vue-router/composables";
import { useI18n } from "@/frontend/composables/useI18n";
import celestialObjectsCollection from "@/frontend/api/collections/CelestialObjects";
import stationsCollection from "@/frontend/api/collections/Stations";
import { TBreadCrumb } from "@/@types/breadcrumbs";
import { celestialObjectRouteGuard } from "@/frontend/utils/RouteGuards/CelestialObjects";
import FilteredList from "@/frontend/core/components/FilteredList/index.vue";

const collection = stationsCollection;

const route = useRoute();

const celestialObject = computed(() => celestialObjectsCollection.record);

const { t } = useI18n();

const metaTitle = computed(() => {
  if (!celestialObject.value) {
    return undefined;
  }

  return t("title.celestialObject", {
    celestialObject: celestialObject.value.name,
    starsystem: celestialObject.value.starsystem.name,
  });
});

useMetaInfo(metaTitle);

const crumbs = computed(() => {
  if (!celestialObject.value) {
    return [];
  }

  const crumbs: TBreadCrumb[] = [
    {
      to: {
        name: "starsystems",
        hash: `#${celestialObject.value.starsystem.slug}`,
      },
      label: t("nav.starsystems"),
    },
    {
      to: {
        name: "starsystem",
        params: {
          slug: celestialObject.value.starsystem.slug,
        },
        hash: `#${celestialObject.value.slug}`,
      },
      label: celestialObject.value.starsystem.name,
    },
  ];

  if (celestialObject.value.parent) {
    crumbs.push({
      to: {
        name: "celestial-object",
        params: {
          starsystem: celestialObject.value.starsystem.slug,
          slug: celestialObject.value.parent.slug,
        },
      },
      label: celestialObject.value.parent.name,
    });
  }

  return crumbs;
});
</script>

<script lang="ts">
export default {
  name: "CelestialObjectDetailPage",
  beforeRouteEnter: celestialObjectRouteGuard,
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
