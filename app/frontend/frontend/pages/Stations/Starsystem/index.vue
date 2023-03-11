<template>
  <section class="container">
    <div class="row">
      <div class="col-12">
        <BreadCrumbs :crumbs="crumbs" />
        <h1 v-if="starsystem">
          {{ t("headlines.starsystem", { starsystem: starsystem.name }) }}
        </h1>
      </div>
    </div>
    <div v-if="starsystem" class="row">
      <div class="col-12 col-lg-8">
        <blockquote v-if="starsystem.description" class="description">
          <p v-html="starsystem.description" />
        </blockquote>
      </div>
      <div class="col-12 col-lg-4">
        <Panel>
          <StarsystemBaseMetrics :starsystem="starsystem" padding />
          <StarsystemLevelsMetrics :starsystem="starsystem" padding />
        </Panel>
      </div>
    </div>

    <FilteredList
      v-if="starsystem"
      key="celestialObjects"
      :collection="collection"
      :name="route.name"
      :route-query="route.query"
      :hash="route.hash"
      :params="{ filters: { starsystemEq: starsystem.slug } }"
      :paginated="true"
    >
      <template #default="{ records }">
        <transition-group name="fade-list" class="row" tag="div" appear>
          <div
            v-for="celestialObject in records"
            :key="celestialObject.slug"
            class="col-12 fade-list-item"
          >
            <PlanetList
              :item="celestialObject"
              :route="{
                name: 'celestial-object',
                params: {
                  starsystem: celestialObject.starsystem.slug,
                  slug: celestialObject.slug,
                },
              }"
            >
              <template v-if="celestialObject.moons.length">
                <h3 class="sr-only">
                  {{ t("headlines.celestialObjects") }}
                </h3>
                <transition-group name="fade-list" class="row" tag="div" appear>
                  <div
                    v-for="moon in celestialObject.moons"
                    :key="moon.slug"
                    class="col-12 col-lg-3 fade-list-item"
                  >
                    <MoonPanel
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
              </template>
            </PlanetList>
          </div>
        </transition-group>
      </template>
    </FilteredList>
  </section>
</template>

<script lang="ts" setup>
import { computed } from "vue";
import { useRoute } from "vue-router/composables";
import { useMetaInfo } from "@/frontend/composables/useMetaInfo";
import { useI18n } from "@/frontend/composables/useI18n";
import FilteredList from "@/frontend/core/components/FilteredList/index.vue";
import Panel from "@/frontend/core/components/Panel/index.vue";
import PlanetList from "@/frontend/components/Planets/List/index.vue";
import MoonPanel from "@/frontend/components/Planets/Panel/index.vue";
import StarsystemBaseMetrics from "@/frontend/components/Starsystems/BaseMetrics/index.vue";
import StarsystemLevelsMetrics from "@/frontend/components/Starsystems/LevelsMetrics/index.vue";
import BreadCrumbs from "@/frontend/core/components/BreadCrumbs/index.vue";
import celestialObjectCollection from "@/frontend/api/collections/CelestialObjects";
import starsystemCollection from "@/frontend/api/collections/Starsystems";
import { starsystemRouteGuard } from "@/frontend/utils/RouteGuards/Starsystems";

const route = useRoute();

const collection = celestialObjectCollection;

const { t } = useI18n();

const starsystem = computed<TStarsystem | undefined>(
  () => starsystemCollection.record
);

const metaTitle = computed(() => {
  if (!starsystem.value) {
    return undefined;
  }
  return t("title.starsystem", { starsystem: starsystem.value.name });
});

useMetaInfo(metaTitle);

const crumbs = computed(() => {
  if (!starsystem.value) {
    return null;
  }

  return [
    {
      to: {
        name: "starsystems",
        hash: `#${starsystem.value.slug}`,
      },
      label: t("nav.starsystems"),
    },
  ];
});
</script>

<script lang="ts">
export default {
  name: "StarsystemDetailPage",
  beforeRouteEnter: starsystemRouteGuard,
};
</script>
