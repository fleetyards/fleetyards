<template>
  <NavItem
    :label="t('nav.tools.index')"
    :submenu-active="active"
    menu-key="tools-menu"
    icon="fad fa-toolbox"
  >
    <template slot="submenu">
      <!-- <NavItem
        :to="{
          name: 'travel-times',
        }"
        :label="t('nav.tools.travelTimes')"
        icon="fad fa-route"
      /> -->
      <NavItem
        :to="{
          name: 'trade-routes',
          query: filterFor('trade-routes'),
        }"
        :label="t('nav.tools.tradeRoutes')"
        icon="fad fa-pallet-alt"
      />
    </template>
  </NavItem>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router/composables";
import { useI18n } from "@/frontend/composables/useI18n";
import Store from "@/frontend/lib/Store";
import NavItem from "../NavItem/index.vue";

const { t } = useI18n();

const route = useRoute();

const filters = computed(() => Store.getters.filters);

const filterFor = (route: string) => {
  if (!filters[route]) {
    return null;
  }

  return {
    q: filters[route],
  };
};

const active = computed(() =>
  ["travel-times", "trade-routes"].includes(route.name || ""),
);
</script>

<script lang="ts">
export default {
  name: "ToolsNav",
};
</script>
