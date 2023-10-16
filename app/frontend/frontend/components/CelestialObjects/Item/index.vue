<template>
  <Panel
    :id="id || celestialObject.slug"
    class="celestial-object-item"
    :bg-image="celestialObject.media.storeImage?.medium"
    :to="detailRoute"
    :link-label="celestialObject.name"
  >
    <PanelHeading level="h3" size="large" shadow="top">
      <router-link :to="detailRoute" :aria-label="celestialObject.name">
        {{ celestialObject.name }}
      </router-link>
    </PanelHeading>
  </Panel>

  <!-- <Panel :id="celestialObject.slug" class="celestial-object-item">
    <div
      :key="celestialObject.media?.storeImage?.large"
      v-lazy:background-image="celestialObject.media?.storeImage?.large"
      class="panel-bg lazy"
    />
    <div class="row">
      <div class="col-12">
        <div class="panel-heading">
          <h2 class="panel-title">
            <router-link :to="detailRoute" :aria-label="celestialObject.name">
              {{ celestialObject.name }}
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
              <CelestialObjectMoonItem :moon="moon" />
            </div>
          </transition-group>
        </template>
      </div>
    </div>
  </Panel> -->
</template>

<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";
import PanelHeading from "@/shared/components/Panel/Heading/index.vue";
import CelestialObjectMoonItem from "@/frontend/components/CelestialObjects/MoonItem/index.vue";
import type { CelestialObject } from "@/services/fyApi";
import { useApiClient } from "@/frontend/composables/useApiClient";

type Props = {
  celestialObject: CelestialObject;
  id?: string;
};

const props = defineProps<Props>();

const { celestialObjects: celestialObjectsService } = useApiClient();

onMounted(() => {
  fetchCelestialObjects();
});

const moons = ref<CelestialObject[]>([]);

const fetchCelestialObjects = async () => {
  try {
    const response = await celestialObjectsService.list({
      q: {
        parentEq: props.celestialObject.slug,
      },
    });

    moons.value = response.items;
  } catch (error) {
    console.error(error);
  }
};

const detailRoute = computed(() => {
  return {
    name: "celestial-object",
    params: {
      starsystem: props.celestialObject.starsystem.slug,
      slug: props.celestialObject.slug,
    },
  };
});
</script>

<script lang="ts">
export default {
  name: "PanelsList",
};
</script>
