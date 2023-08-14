<template>
  <Panel :id="item.slug" class="station-list">
    <div
      :key="item.storeImage"
      v-lazy:background-image="item.storeImage"
      class="panel-bg lazy"
    />
    <div class="row">
      <div class="col-12">
        <div class="panel-heading">
          <h2 class="panel-title">
            <router-link :to="route" :aria-label="item.name">
              {{ item.name }}
            </router-link>
          </h2>
        </div>
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6 col-xl-4" />
      <div class="col-12 col-md-6 col-xl-8 items">
        <template v-if="celestialObjects.length">
          <h3 class="sr-only">
            {{ t("headlines.celestialObjects") }}
          </h3>
          <transition-group name="fade-list" class="row" tag="div" appear>
            <div
              v-for="celestialObject in celestialObjects"
              :key="celestialObject.slug"
              class="col-12 col-lg-3 fade-list-item"
            >
              <PlanetPanel
                :item="celestialObject"
                :route="{
                  name: 'celestial-object',
                  params: {
                    starsystem: item.slug,
                    slug: celestialObject.slug,
                  },
                }"
              />
            </div>
          </transition-group>
        </template>
      </div>
    </div>
  </Panel>
</template>

<script lang="ts" setup>
import Panel from "@/frontend/core/components/Panel/index.vue";
import PlanetPanel from "@/frontend/components/Planets/Panel/index.vue";
import type { Location } from "vue-router";
import type { Starsystem, CelestialObject } from "@/services/fyApi";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useI18n } from "@/frontend/composables/useI18n";

const { t } = useI18n();

type Props = {
  route: Location;
  item: Starsystem;
};

const props = defineProps<Props>();

const { celestialObjects: celestialObjectsService } = useApiClient();

onMounted(() => {
  fetchCelestialObjects();
});

const celestialObjects = ref<CelestialObject[]>([]);

const fetchCelestialObjects = async () => {
  try {
    const response = await celestialObjectsService.celestialObjects({
      q: {
        starsystemEq: props.item.slug,
        parentIdNull: true,
      },
    });

    celestialObjects.value = response;
  } catch (error) {
    console.error(error);
  }
};
</script>

<script lang="ts">
export default {
  name: "StarsystemsList",
};
</script>

<style lang="scss">
@import "index";
</style>
