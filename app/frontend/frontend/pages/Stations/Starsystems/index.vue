<template>
  <section class="container">
    <div class="row">
      <div class="col-12">
        <h1 class="sr-only">
          {{ t("headlines.starsystems") }}
        </h1>
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <Panel>
          <div class="starmap">
            <img :src="require('@/images/map.png')" alt="map" />
            <router-link
              v-for="starsystem in collection.records"
              :key="starsystem.slug"
              :to="{
                name: 'starsystem',
                params: {
                  slug: starsystem.slug,
                },
              }"
              :style="{
                left: `${starsystem.mapX}%`,
                top: `${starsystem.mapY}%`,
              }"
              class="starsystem"
            />
          </div>
        </Panel>
      </div>
    </div>

    <FilteredList
      key="starsystems"
      :collection="collection"
      :name="route.name"
      :route-query="route.query"
      :hash="route.hash"
      :paginated="true"
    >
      <template #default="{ records }">
        <transition-group name="fade-list" class="row" tag="div" appear>
          <div
            v-for="starsystem in records"
            :key="starsystem.slug"
            class="col-12 fade-list-item"
          >
            <StarsystemList
              :item="starsystem"
              :route="{
                name: 'starsystem',
                params: {
                  slug: starsystem.slug,
                },
              }"
            >
              <template v-if="starsystem.celestialObjects.length">
                <h3 class="sr-only">
                  {{ t("headlines.celestialObjects") }}
                </h3>
                <transition-group name="fade-list" class="row" tag="div" appear>
                  <div
                    v-for="celestialObject in starsystem.celestialObjects"
                    :key="celestialObject.slug"
                    class="col-12 col-lg-3 fade-list-item"
                  >
                    <PlanetPanel
                      :item="celestialObject"
                      :route="{
                        name: 'celestial-object',
                        params: {
                          starsystem: celestialObject.starsystem.slug,
                          slug: celestialObject.slug,
                        },
                      }"
                    />
                  </div>
                </transition-group>
              </template>
            </StarsystemList>
          </div>
        </transition-group>
      </template>
    </FilteredList>
  </section>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router";
import Panel from "@/frontend/core/components/Panel/index.vue";
import StarsystemList from "@/frontend/components/Starsystems/List/index.vue";
import FilteredList from "@/frontend/core/components/FilteredList/index.vue";
import PlanetPanel from "@/frontend/components/Planets/Panel/index.vue";
import starsystemCollection from "@/frontend/api/collections/Starsystems";
import { useI18n } from "@/frontend/composables/useI18n";

const collection = starsystemCollection;

const route = useRoute();

const { t } = useI18n();
</script>

<script lang="ts">
export default {
  name: "StarsystemsPage",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
