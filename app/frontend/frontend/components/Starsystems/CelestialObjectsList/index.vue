<template>
  <div class="#celestial-objects">
    <div class="row">
      <div class="col-12">
        <Pagination
          :pagination="pagination"
          :per-page="perPage"
          :update-per-page="updatePerPage"
          hash="celestial-objects"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <transition-group name="fade-list" class="row" tag="div" appear>
          <div
            v-for="celestialObject in items"
            :key="celestialObject.slug"
            class="col-12 fade-list-item"
          >
            <PlanetList
              :item="celestialObject"
              :route="{
                name: 'celestial-object',
                params: {
                  starsystem: celestialObject.starsystem?.slug,
                  slug: celestialObject.slug,
                },
              }"
            >
              <template v-if="celestialObject.moons?.length">
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
                          starsystem: celestialObject.starsystem?.slug,
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
        <Loader :loading="isLoading" :fixed="true" />
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <Pagination
          :pagination="pagination"
          :per-page="perPage"
          :update-per-page="updatePerPage"
          hash="celestial-objects"
        />
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import Pagination from "@/frontend/core/components/Pagination/index.vue";
import PlanetList from "@/frontend/components/Planets/List/index.vue";
import MoonPanel from "@/frontend/components/Planets/Panel/index.vue";
import Loader from "@/frontend/core/components/Loader/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useQuery } from "@tanstack/vue-query";
import { useRoute } from "vue-router/composables";
import { usePagination } from "@/frontend/composables/usePagination";
import { BaseList } from "@/services/fyApi";

const { t } = useI18n();

const { celestialObjects: celestialObjectsClient } = useApiClient();

const route = useRoute();

const items = computed(() => celestialObjects.value?.items ?? []);

const {
  isLoading,
  data: celestialObjects,
  refetch,
} = useQuery({
  queryKey: ["celestialObjects"],
  queryFn: () =>
    celestialObjectsClient.list({
      page: page.value,
      perPage: perPage.value,
      q: {
        parentIdNull: true,
        starsystemEq: String(route.params.slug),
      },
    }),
});

const { perPage, page, pagination, updatePerPage } = usePagination(
  "celestialObjects",
  celestialObjects as Ref<BaseList>,
  refetch
);
</script>

<script lang="ts">
export default {
  name: "CelestialObjectsList",
};
</script>
