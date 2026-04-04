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
import {
  useFleet as useFleetQuery,
  usePublicFleet as usePublicFleetQuery,
} from "@/services/fyApi";

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

const { data: fleetData } = useFleetQuery(fleetSlug, {
  query: {
    enabled: computed(() => isFleetRoute.value && isAuthenticated.value),
    retry: false,
  },
});

const { data: publicFleetData } = usePublicFleetQuery(fleetSlug, {
  query: {
    enabled: computed(
      () => isFleetRoute.value && (!isAuthenticated.value || !fleetData.value),
    ),
    retry: false,
  },
});

const currentFleet = computed(() => fleetData.value || publicFleetData.value);
</script>

<template>
  <AppNavigationMobile v-if="route.name">
    <template v-if="isFleetRoute">
      <template v-if="currentFleet">
        <NavItem
          :to="{ name: 'fleet', params: { slug: currentFleet.slug } }"
          :image="currentFleet.logo?.smallUrl"
          :active="routeActive('fleet')"
          :label="currentFleet.name"
        />
        <NavItem
          v-if="currentFleet.publicFleet || currentFleet.myFleet"
          :to="{ name: 'fleet-ships', params: { slug: currentFleet.slug } }"
          :active="shipsNavActive"
          icon="fa-duotone fa-starship"
        />
        <NavItem
          v-if="currentFleet.publicFleetStats || currentFleet.myFleet"
          :to="{
            name: 'fleet-stats',
            params: { slug: currentFleet.slug },
          }"
          :active="routeActive('fleet-stats')"
          icon="fa-duotone fa-chart-bar"
        />
        <template v-if="currentFleet.myFleet">
          <NavItem
            :to="{
              name: 'fleet-members',
              params: { slug: currentFleet.slug },
            }"
            :active="routeActive('fleet-members')"
            icon="fa-duotone fa-users"
          />
          <NavItem
            :to="{
              name: 'fleet-settings',
              params: { slug: currentFleet.slug },
            }"
            :active="routeActive('fleet-settings')"
            icon="fa-duotone fa-cogs"
          />
        </template>
      </template>
    </template>
    <template v-else>
      <NavItem
        :to="{ name: 'home' }"
        :active="routeActive('home')"
        icon="fa-duotone fa-home-alt"
      />
      <NavItem
        :to="{
          name: 'ships',
          query: filterFor('ships'),
        }"
        icon="fa-duotone fa-starship"
      />
      <NavItem
        v-if="isAuthenticated || !hangarPreview"
        :to="{
          name: 'hangar',
          query: filterFor('hangar'),
        }"
        icon="fa-duotone fa-warehouse"
      />
      <NavItem
        v-else
        :to="{ name: 'hangar-preview' }"
        icon="fa-light fa-warehouse"
      />
      <NavItem :to="{ name: 'fleets' }" icon="fa-duotone fa-users" />
    </template>
  </AppNavigationMobile>
</template>
