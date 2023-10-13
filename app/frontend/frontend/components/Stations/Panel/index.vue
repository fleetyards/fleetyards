<template>
  <Panel :id="station.slug" class="station-panel">
    <div
      :key="station.media.storeImage?.large"
      v-lazy:background-image="station.media.storeImage?.large"
      class="panel-bg lazy"
    />
    <div class="row">
      <div class="col-12">
        <div class="panel-heading">
          <h2 class="panel-title">
            <router-link
              :to="{
                name: 'station',
                params: {
                  slug: station.slug,
                },
              }"
              :aria-label="station.name"
            >
              {{ station.name }}
            </router-link>
            <small class="text-muted">
              <LocationLabel :station="station" />
            </small>
          </h2>
        </div>
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6 col-xl-4">
        <div class="panel-stats">
          <Stats :station="station" />
        </div>
      </div>
      <div class="col-12 col-md-6 col-xl-8 items">
        <slot />
      </div>
    </div>
  </Panel>
</template>

<script lang="ts" setup>
import LocationLabel from "@/frontend/components/Stations/LocationLabel/index.vue";
import Stats from "@/frontend/components/Stations/ListStats/index.vue";
import Panel from "@/shared/components/Panel/index.vue";
import type { Station } from "@/services/fyApi";

type Props = {
  station: Station;
};

defineProps<Props>();
</script>

<script lang="ts">
export default {
  name: "StationsPanel",
};
</script>

<style lang="scss">
@import "index";
</style>
