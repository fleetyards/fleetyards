<template>
  <Panel :id="station.slug" class="station-panel">
    <div
      :key="station.storeImage"
      v-lazy:background-image="station.storeImage"
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

<script>
import LocationLabel from "@/frontend/components/Stations/LocationLabel/index.vue";
import Panel from "@/frontend/core/components/Panel/index.vue";
import Stats from "@/frontend/components/Stations/ListStats/index.vue";

export default {
  name: "StationsPanel",

  components: {
    Panel,
    Stats,
    LocationLabel,
  },

  props: {
    station: {
      type: Object,
      required: true,
    },
  },
};
</script>

<style lang="scss">
@import "index";
</style>
