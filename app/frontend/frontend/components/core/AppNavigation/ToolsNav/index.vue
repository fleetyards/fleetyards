<template>
  <NavItem
    :label="t('nav.tools.index')"
    :submenu-active="active"
    menu-key="tools-menu"
    icon="fad fa-toolbox"
  >
    <template #submenu>
      <NavItem
        :to="{
          name: 'travel-times',
        }"
        :label="t('nav.tools.travelTimes')"
        icon="fad fa-route"
      />
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
import { type LocationQueryRaw } from "vue-router";
import { useI18n } from "@/shared/composables/useI18n";
import { useFiltersStore } from "@/shared/stores/filters";
import { storeToRefs } from "pinia";
import NavItem from "../NavItem/index.vue";

const { t } = useI18n();

const route = useRoute();

const filtersStore = useFiltersStore();

const { filters } = storeToRefs(filtersStore);

const filterFor = (routeName: string) => {
  if (!filters.value[routeName]) {
    return undefined;
  }

  return {
    q: filters.value[routeName],
  } as unknown as LocationQueryRaw;
};

const active = computed(() =>
  ["travel-times", "trade-routes"].includes(String(route.name || "")),
);
</script>

<script lang="ts">
export default {
  name: "ToolsNav",
};
</script>
