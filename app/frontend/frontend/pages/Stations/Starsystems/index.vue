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
            <img :src="mapImageUrl" alt="map" />
            <router-link
              v-for="starsystem in items"
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
    <div id="starsystems" class="row">
      <div class="col-12">
        <Pagination
          :pagination="pagination"
          :per-page="perPage"
          :update-per-page="updatePerPage"
          hash="starsystems"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <transition-group name="fade-list" class="row" tag="div" appear>
          <div
            v-for="starsystem in items"
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
                          starsystem: starsystem?.slug,
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
        <Loader :loading="isLoading" :fixed="true" />
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <Pagination
          :pagination="pagination"
          :per-page="perPage"
          :update-per-page="updatePerPage"
          hash="starsystems"
        />
      </div>
    </div>
  </section>
</template>

<script lang="ts" setup>
import Loader from "@/frontend/core/components/Loader/index.vue";
import Panel from "@/frontend/core/components/Panel/index.vue";
import Pagination from "@/frontend/core/components/Pagination/index.vue";
import StarsystemList from "@/frontend/components/Starsystems/List/index.vue";
import PlanetPanel from "@/frontend/components/Planets/Panel/index.vue";
import mapImageUrl from "@/images/map.png";
import { useMetaInfo } from "@/frontend/composables/useMetaInfo";
import { useI18n } from "@/frontend/composables/useI18n";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { usePagination } from "@/frontend/composables/usePagination";
import { useQuery } from "@tanstack/vue-query";
import { useRoute } from "vue-router/composables";
import { StarsystemQuery, BaseList } from "@/services/fyApi";

const { t } = useI18n();

useMetaInfo();

const { starsystems: starsystemsClient } = useApiClient();

const route = useRoute();

const items = computed(() => starsystems.value?.items ?? []);

const {
  isLoading,
  data: starsystems,
  refetch,
} = useQuery({
  queryKey: ["starsystems"],
  queryFn: () =>
    starsystemsClient.list({
      page: page.value,
      perPage: perPage.value,
      q: route.query.q as StarsystemQuery,
    }),
});

const { perPage, page, pagination, updatePerPage } = usePagination(
  "starsystems",
  starsystems as Ref<BaseList>,
  refetch
);
</script>

<script lang="ts">
export default {
  name: "StarsystemsPage",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
