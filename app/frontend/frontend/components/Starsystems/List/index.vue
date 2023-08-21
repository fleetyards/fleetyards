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
import Panel from "@/shared/components/Panel/index.vue";
</script>

<script lang="ts">
export default {
  name: "StarsystemsList",
};
</script>

<style lang="scss">
@import "index";
</style>
