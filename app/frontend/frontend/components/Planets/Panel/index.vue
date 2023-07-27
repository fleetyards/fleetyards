<template>
  <Panel :id="id || item.slug" class="station-item">
    <div class="panel-image text-center">
      <router-link
        :key="item.media?.storeImage?.medium"
        v-lazy:background-image="item.media?.storeImage?.medium"
        :to="route"
        :aria-label="item.name"
        class="lazy"
      />
    </div>
    <h2 class="panel-title">
      <router-link :to="route" :aria-label="item.name">
        {{ item.name }}
      </router-link>
    </h2>
  </Panel>
</template>

<script lang="ts" setup>
import type { CelestialObjectMinimal } from "@/services/fyApi";
import type { RouteLocationRaw } from "vue-router";
import Panel from "@/shared/components/Panel/index.vue";

type Props = {
  item: CelestialObjectMinimal;
  route: RouteLocationRaw;
  id?: string;
};

withDefaults(defineProps<Props>(), {
  id: undefined,
});
</script>

<script lang="ts">
export default {
  name: "PlanetsPanel",
};
</script>

<style lang="scss">
@import "index";
</style>
