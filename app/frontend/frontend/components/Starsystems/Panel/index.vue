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
            <router-link :to="detailRoute" :aria-label="item.name">
              {{ item.name }}
            </router-link>
          </h2>
        </div>
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6 col-xl-4" />
      <div class="col-12 col-md-6 col-xl-8 items">
        <template v-if="celestialObjects && celestialObjects.items.length">
          <h3 class="sr-only">
            {{ t("headlines.celestialObjects") }}
          </h3>
          <transition-group name="fade-list" class="row" tag="div" appear>
            <div
              v-for="celestialObject in celestialObjects.items"
              :key="celestialObject.slug"
              class="col-12 col-lg-3 fade-list-item"
            >
              <CelestialObjectSubItem :item="celestialObject" />
            </div>
          </transition-group>
        </template>
      </div>
    </div>
  </Panel>
</template>

<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";
import CelestialObjectSubItem from "@/frontend/components/CelestialObjects/SubItem/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useQuery } from "@tanstack/vue-query";
import type { Starsystem } from "@/services/fyApi";

const { t, currentLocale } = useI18n();

type Props = {
  item: Starsystem;
};

const props = defineProps<Props>();

const detailRoute = computed(() => {
  return { name: "starsystem", params: { slug: props.item.slug } };
});

const { celestialObjects: celestialObjectsService } = useApiClient();

const { data: celestialObjects } = useQuery({
  queryKey: ["celestialObjects", props.item.slug],
  queryFn: () =>
    celestialObjectsService.list({
      q: {
        parentIdNull: true,
        starsystemEq: props.item.slug,
      },
    }),
});
</script>

<script lang="ts">
export default {
  name: "StarsystemPanel",
};
</script>

<style lang="scss">
@import "index";
</style>
