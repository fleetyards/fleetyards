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
        <slot />
      </div>
    </div>
  </Panel>
</template>

<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";
import type { RouteLocationRaw } from "vue-router";
import type { StarsystemMinimal } from "@/services/fyApi";

type Props = {
  item: StarsystemMinimal;
  route: RouteLocationRaw;
};

defineProps<Props>();
</script>

<script lang="ts">
export default {
  name: "StarsystemsList",
};
</script>

<style lang="scss">
@import "index";
</style>
