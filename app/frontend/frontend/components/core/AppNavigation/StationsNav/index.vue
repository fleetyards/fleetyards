<template>
  <NavItem
    :label="t('nav.stations.index')"
    :submenu-active="active"
    menu-key="stations-menu"
    icon="fad fa-planet-ringed"
  >
    <template #submenu>
      <NavItem
        :to="{ name: 'stations' }"
        :label="t('nav.stations.overview')"
        icon="fad fa-planet-ringed"
      />
      <NavItem
        :to="{ name: 'starsystems' }"
        :active="starsystemActive"
        :label="t('nav.stations.starsystems')"
        icon="fad fa-solar-system"
      />
      <NavItem :divider="true" />
      <NavItem
        :to="{ name: 'shops' }"
        :label="t('nav.stations.shops')"
        icon="fad fa-store-alt"
      />
    </template>
  </NavItem>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router";
import { useI18n } from "@/shared/composables/useI18n";
import NavItem from "../NavItem/index.vue";

const { t } = useI18n();

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
  ].includes(String(route.name || "")),
);

const starsystemActive = computed(() =>
  ["starsystems", "starsystem", "celestial-object"].includes(
    String(route.name || ""),
  ),
);
</script>

<script lang="ts">
export default {
  name: "StationsNav",
};
</script>
