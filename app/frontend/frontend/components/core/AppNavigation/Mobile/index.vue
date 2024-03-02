<template>
  <div class="navigation-mobile noselect">
    <div v-if="route.name" class="navigation-items">
      <template v-if="isFleetRoute && currentFleet">
        <Btn
          variant="link"
          size="large"
          :inline="true"
          :to="{ name: 'fleet', params: { slug: currentFleet.slug } }"
          :image="currentFleet.logo"
          :class="{ active: routeActive('fleet') }"
          exact
        >
          <img
            v-if="currentFleet.logo"
            :src="currentFleet.logo"
            :alt="`${currentFleet.name} image`"
            class="navigation-item-image"
          />
          <span v-else class="nav-item-image-empty">
            {{ firstLetter }}
          </span>
        </Btn>
        <Btn
          v-if="currentFleet.publicFleet || currentFleet.myFleet"
          variant="link"
          size="large"
          :inline="true"
          :to="{ name: 'fleet-ships', params: { slug: currentFleet.slug } }"
          :class="{ active: shipsNavActive }"
          :active="shipsNavActive"
        >
          <i class="fad fa-starship" />
        </Btn>
        <template v-if="currentFleet.myFleet">
          <Btn
            variant="link"
            size="large"
            :inline="true"
            :to="{ name: 'fleet-members', params: { slug: currentFleet.slug } }"
            :class="{ active: routeActive('fleet-members') }"
          >
            <i class="fad fa-users" />
          </Btn>
          <Btn
            variant="link"
            size="large"
            :inline="true"
            :to="{
              name: 'fleet-settings',
              params: { slug: currentFleet.slug },
            }"
            :class="{ active: routeActive('fleet-settings') }"
          >
            <i class="fad fa-cogs" />
          </Btn>
        </template>
      </template>
      <template v-else>
        <Btn
          variant="link"
          size="large"
          :inline="true"
          :to="{ name: 'home' }"
          :class="{ active: routeActive('home') }"
          :exact="true"
        >
          <i class="fad fa-home-alt" />
        </Btn>
        <Btn
          variant="link"
          size="large"
          :inline="true"
          :to="{
            name: 'models',
            query: filterFor('models'),
          }"
        >
          <i class="fad fa-starship" />
        </Btn>
        <Btn
          variant="link"
          size="large"
          :inline="true"
          :to="{ name: 'search' }"
        >
          <i class="fa fa-search" />
        </Btn>
        <Btn
          v-if="isAuthenticated || !hangarPreview"
          variant="link"
          size="large"
          :inline="true"
          :to="{
            name: 'hangar',
            query: filterFor('hangar'),
          }"
        >
          <i class="fad fa-warehouse" />
        </Btn>
        <Btn
          v-else
          variant="link"
          size="large"
          :inline="true"
          :to="{ name: 'hangar-preview' }"
        >
          <i class="fal fa-warehouse" />
        </Btn>
      </template>
      <button
        :class="{
          collapsed: navCollapsed,
        }"
        class="nav-toggle"
        type="button"
        aria-label="Toggle Navigation"
        @click.stop.prevent="navStore.toggle"
      >
        <span class="sr-only">
          {{ t("labels.toggleNavigation") }}
        </span>
        <span class="icon-bar top-bar" />
        <span class="icon-bar middle-bar" />
        <span class="icon-bar bottom-bar" />
      </button>
    </div>
  </div>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { isFleetRoute as fleetRouteCheck } from "../utils";
import { useFiltersStore } from "@/shared/stores/filters";
import { useNavStore } from "@/frontend/stores/nav";
import { useSessionStore } from "@/frontend/stores/session";
import { useHangarStore } from "@/frontend/stores/hangar";
import { storeToRefs } from "pinia";
import { useI18n } from "@/shared/composables/useI18n";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useQuery } from "@tanstack/vue-query";
import { useComlink } from "@/shared/composables/useComlink";

const { t, currentLocale } = useI18n();

const navStore = useNavStore();

const { collapsed: navCollapsed } = storeToRefs(navStore);

const sessionStore = useSessionStore();

const { isAuthenticated } = storeToRefs(sessionStore);

const hangarStore = useHangarStore();

const { preview: hangarPreview } = storeToRefs(hangarStore);

const filtersStore = useFiltersStore();

const { filters } = storeToRefs(filtersStore);

const route = useRoute();

const isFleetRoute = computed(() => {
  return fleetRouteCheck(String(route.name));
});

const shipsNavActive = computed(() => {
  return ["fleet-ships", "fleet-fleetchart"].includes(String(route.name));
});

const firstLetter = computed(() => {
  return currentFleet.value?.name?.charAt(0);
});

const filterFor = (routeName: string) => {
  // // TODO: disabled until vue-router supports navigation to same route
  // return null
  if (!filters.value[routeName]) {
    return null;
  }

  return {
    q: filters.value[routeName],
  };
};

const routeActive = (routeName: string) => {
  return routeName === route.name;
};

const { fleets: fleetsService } = useApiClient();

const { refetch, data: currentFleet } = useQuery({
  queryKey: ["fleet", route.params.slug],
  queryFn: () =>
    fleetsService.fleet({
      slug: String(route.params.slug),
    }),
  enabled: route.params.slug !== undefined && isFleetRoute.value,
});

const comlink = useComlink();

onMounted(() => {
  comlink.on("fleet-update", refetch);
});
</script>

<script lang="ts">
export default {
  name: "AppNavigationMobile",
};
</script>
