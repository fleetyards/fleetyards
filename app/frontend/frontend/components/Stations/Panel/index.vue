<template>
  <Panel
    :id="station.slug"
    class="station-panel"
    :bg-image="station.media.storeImage?.large"
    :bg-align="showStats ? 'right' : undefined"
    :shadow="showStats ? 'left' : undefined"
  >
    <PanelHeading
      level="h2"
      class="station-panel-heading"
      size="large"
      :shadow="showStats ? undefined : 'top'"
    >
      <template #default>
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
      </template>
      <template #subtitle>
        <LocationLabel :station="station" />
      </template>
    </PanelHeading>
    <PanelBody class="station-panel-body">
      <div v-if="showStats" class="row">
        <div class="col-12 col-md-6 col-xl-4">
          <div class="panel-stats">
            <Stats :station="station" />
          </div>
        </div>
        <div class="col-12 col-md-6 col-xl-8 items">
          <slot />
        </div>
      </div>
    </PanelBody>
  </Panel>
</template>

<script lang="ts" setup>
import LocationLabel from "@/frontend/components/Stations/LocationLabel/index.vue";
import Stats from "@/frontend/components/Stations/ListStats/index.vue";
import Panel from "@/shared/components/Panel/index.vue";
import PanelHeading from "@/shared/components/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/Panel/Body/index.vue";
import type { Station } from "@/services/fyApi";

type Props = {
  station: Station;
  showStats?: boolean;
};

withDefaults(defineProps<Props>(), {
  showStats: false,
});
</script>

<script lang="ts">
export default {
  name: "StationsPanel",
};
</script>

<style lang="scss">
@import "index";
</style>
