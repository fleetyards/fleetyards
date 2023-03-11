<template>
  <NavItem
    :label="$t('nav.stations.index')"
    :submenu-active="active"
    menu-key="stations-menu"
    icon="fad fa-planet-ringed"
  >
    <template slot="submenu">
      <NavItem
        :to="{ name: 'stations' }"
        :label="$t('nav.stations.overview')"
        icon="fad fa-planet-ringed"
      />
      <NavItem
        :to="{ name: 'starsystems' }"
        :label="$t('nav.stations.starsystems')"
        icon="fad fa-solar-system"
      />
      <NavItem :divider="true" />
      <NavItem
        :to="{ name: 'shops' }"
        :label="$t('nav.stations.shops')"
        icon="fad fa-store-alt"
      />
    </template>
  </NavItem>
</template>

<script lang="ts" setup>
import { computed } from "vue";
import { useRoute } from "vue-router/composables";
import NavItem from "@/frontend/core/components/Navigation/NavItem/index.vue";

const route = useRoute();

const active = computed(() =>
  [
    "stations",
    "station",
    "shops",
    "shop",
    "starsystems",
    "starsystem",
    "celestial-object",
    "station-images",
  ].includes(route.name || "")
);
</script>

<script lang="ts">
export default {
  name: "StationsNav",
};
</script>
