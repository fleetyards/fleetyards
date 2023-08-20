<template>
  <Panel :id="item.slug" class="station-list">
    <div
      :key="item.media?.storeImage?.large"
      v-lazy:background-image="item.media?.storeImage?.large"
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
        <template v-if="moons.length">
          <h3 class="sr-only">
            {{ t("headlines.celestialObjects") }}
          </h3>
          <transition-group name="fade-list" class="row" tag="div" appear>
            <div
              v-for="moon in moons"
              :key="moon.slug"
              class="col-12 col-lg-3 fade-list-item"
            >
              <MoonPanel
                :item="moon"
                :route="{
                  name: 'celestial-object',
                  params: {
                    starsystem: item.starsystem?.slug,
                    slug: moon.slug,
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

<script lang="ts" setup lang="ts" setup>
import type { CelestialObjectMinimal } from "@/services/fyApi";
import type { RouteLocationRaw } from "vue-router";
import Panel from "@/shared/components/Panel/index.vue";
import MoonPanel from "@/frontend/components/Planets/Panel/index.vue";
import type { Location } from "vue-router";
import type { CelestialObject } from "@/services/fyApi";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useI18n } from "@/frontend/composables/useI18n";

const { t } = useI18n();

type Props = {
  route: RouteLocationRaw;
  item: CelestialObject;
};

const props = defineProps<Props>();

const { celestialObjects: celestialObjectsService } = useApiClient();

onMounted(() => {
  fetchCelestialObjects();
});

const moons = ref<CelestialObject[]>([]);

const fetchCelestialObjects = async () => {
  try {
    const response = await celestialObjectsService.celestialObjects({
      q: {
        parentEq: props.item.slug,
      },
    });

    moons.value = response;
  } catch (error) {
    console.error(error);
  }
};
</script>

<script lang="ts">
export default {
  name: "PanelsList",
};
</script>

<style lang="scss">
@import "index";
</style>
