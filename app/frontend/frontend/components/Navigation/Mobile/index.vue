<script lang="ts">
export default {
  name: "FrontendNavigationMobile",
};
</script>

<script lang="ts" setup>
import AppNavigationMobile from "@/shared/components/AppNavigation/Mobile/index.vue";
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import { useSessionStore } from "@/frontend/stores/session";
import { storeToRefs } from "pinia";
import { useFleetRouteCheck } from "@/frontend/composables/useFleetRouteCheck";
import { useFiltersStore } from "@/shared/stores/filters";
import { useHangarStore } from "@/frontend/stores/hangar";
import { type LocationQueryRaw } from "vue-router";
import { useFleet as useFleetQuery } from "@/services/fyApi";

const sessionStore = useSessionStore();

const { isAuthenticated } = storeToRefs(sessionStore);

const route = useRoute();

const { isFleetRoute } = useFleetRouteCheck();

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

const hangarStore = useHangarStore();

const { preview: hangarPreview } = storeToRefs(hangarStore);

const routeActive = (routeName: string) => {
  return routeName === route.name;
};

const shipsNavActive = computed(() => {
  return ["fleet-ships", "fleet-fleetchart"].includes(String(route.name));
});

const fleetSlug = computed(() => {
  return route.params.slug as string;
});

const { data: currentFleet } = useFleetQuery(fleetSlug, {
  query: {
    enabled: isFleetRoute,
  },
});
</script>

<template>
  <AppNavigationMobile v-if="route.name">
    <template v-if="isFleetRoute">
      <template v-if="currentFleet">
        <NavItem
          :to="{ name: 'fleet', params: { slug: currentFleet.slug } }"
          :image="currentFleet.logo"
          :active="routeActive('fleet')"
          :label="currentFleet.name"
        />
        <NavItem
          v-if="currentFleet.publicFleet || currentFleet.myFleet"
          :to="{ name: 'fleet-ships', params: { slug: currentFleet.slug } }"
          :active="shipsNavActive"
          icon="fad fa-starship"
        />
        <template v-if="currentFleet.myFleet">
          <NavItem
            :to="{
              name: 'fleet-members',
              params: { slug: currentFleet.slug },
            }"
            :active="routeActive('fleet-members')"
            icon="fad fa-users"
          />
          <NavItem
            :to="{
              name: 'fleet-settings',
              params: { slug: currentFleet.slug },
            }"
            :active="routeActive('fleet-settings')"
            icon="fad fa-cogs"
          />
        </template>
      </template>
    </template>
    <template v-else>
      <NavItem
        :to="{ name: 'home' }"
        :active="routeActive('home')"
        icon="fad fa-home-alt"
      />
      <NavItem
        :to="{
          name: 'ships',
          query: filterFor('ships'),
        }"
        icon="fad fa-starship"
      />
      <NavItem :to="{ name: 'search' }" icon="fa fa-search" />
      <NavItem
        v-if="isAuthenticated || !hangarPreview"
        :to="{
          name: 'hangar',
          query: filterFor('hangar'),
        }"
        icon="fad fa-warehouse"
      />
      <NavItem
        v-else
        :to="{ name: 'hangar-preview' }"
        icon="fal fa-warehouse"
      />
    </template>
  </AppNavigationMobile>
</template>
