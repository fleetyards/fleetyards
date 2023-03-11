<template>
  <nav
    ref="navigation"
    :class="{
      visible: !navCollapsed,
      'nav-slim': slimNavigation,
    }"
    role="navigation"
  >
    <div
      :class="{
        'nav-container-slim': slimNavigation,
      }"
      class="nav-container"
    >
      <div class="nav-container-inner">
        <ul>
          <NavItem class="logo-menu">
            <img
              v-lazy="require('@/images/favicon-small.png')"
              class="logo-menu-image"
              alt="logo"
            />
            <span v-if="!slimNavigation" class="logo-menu-label">
              {{ $t("app") }}
            </span>
          </NavItem>
          <FleetNav v-if="isFleetRoute" />
          <template v-else>
            <NavItem
              :to="{ name: 'home' }"
              :label="$t('nav.home')"
              icon="fad fa-home-alt"
              :exact="true"
            />
            <NavItem
              v-if="isAuthenticated || !hangarPreview"
              :to="{
                name: 'hangar',
                query: filterFor('hangar'),
              }"
              :label="$t('nav.hangar')"
              :active="isHangarRoute"
              icon="fad fa-warehouse"
            />
            <NavItem
              v-else
              :to="{ name: 'hangar-preview' }"
              :label="$t('nav.hangar')"
              icon="fal fa-warehouse"
            />
            <NavItem
              :to="{
                name: 'models',
                query: filterFor('models'),
              }"
              :label="$t('nav.models.index')"
              :active="isModelRoute"
              icon="fad fa-starship"
            />
            <StationsNav />
            <FleetsNav />
            <NavItem
              :to="{ name: 'images' }"
              :label="$t('nav.images')"
              icon="fad fa-images"
            />
            <NavItem
              :to="{
                name: 'trade-routes',
                query: filterFor('trade-routes'),
              }"
              :label="$t('nav.tradeRoutes')"
              icon="fad fa-pallet-alt"
            />
            <NavItem
              :to="{ name: 'roadmap' }"
              :label="$t('nav.roadmap.index')"
              icon="fad fa-tasks-alt"
              :active="isRoadmapRoute"
            />
            <NavItem
              :to="{ name: 'stats' }"
              :label="$t('nav.stats')"
              icon="fad fa-chart-bar"
            />
          </template>
        </ul>
        <NavFooter />
      </div>
    </div>
  </nav>
</template>

<script lang="ts" setup>
import { ref, computed, watch, onUnmounted, onBeforeUnmount } from "vue";
import { storeToRefs } from "pinia";
import { useRoute } from "vue-router/composables";
import { isFleetRoute as isFleetRouteCheck } from "@/frontend/utils/Routes/Fleets";
import { useAppStore } from "@/frontend/stores/App";
import { useHangarStore } from "@/frontend/stores/Hangar";
import { useSessionStore } from "@/frontend/stores/Session";
import NavItem from "@/frontend/core/components/Navigation/NavItem/index.vue";
import FleetNav from "@/frontend/core/components/Navigation/FleetNav/index.vue";
import FleetsNav from "@/frontend/core/components/Navigation/FleetsNav/index.vue";
import StationsNav from "@/frontend/core/components/Navigation/StationsNav/index.vue";
import NavFooter from "@/frontend/core/components/Navigation/NavFooter/index.vue";

const route = useRoute();

const appStore = useAppStore();

const { navCollapsed, slimNavigation } = storeToRefs(appStore);

const sessionStore = useSessionStore();

const { isAuthenticated } = storeToRefs(sessionStore);

const hangarStore = useHangarStore();
const { preview: hangarPreview } = storeToRefs(hangarStore);

const isFleetRoute = computed(() => isFleetRouteCheck(route.name || ""));

const isRoadmapRoute = computed(() => {
  if (!route.name) {
    return false;
  }

  return route.name.includes("roadmap");
});

const isModelRoute = computed(() => {
  if (!route.name) {
    return false;
  }

  return route.name.includes("model");
});

const isHangarRoute = computed(() => {
  if (!route.name) {
    return false;
  }

  return route.name.includes("hangar");
});

const filterFor = (route: string) => {
  // // TODO: disabled until vue-router supports navigation to same route
  // return null
  if (!appStore.filters[route]) {
    return null;
  }

  return {
    q: appStore.filters[route],
  };
};

const close = () => {
  appStore.closeNav();
};

watch(
  () => route,
  () => {
    close();
  },
  { deep: true }
);

const navigation = ref<HTMLElement | null>(null);

const documentClick = (event: Event) => {
  const { target } = event;

  if (
    navigation.value &&
    navigation.value !== target &&
    !navigation.value.contains(target as Node)
  ) {
    close();
  }
};

document.addEventListener("click", documentClick);

onUnmounted(() => {
  document.removeEventListener("click", documentClick);
});

onBeforeUnmount(() => {
  close();
});
</script>

<script lang="ts">
export default {
  name: "NavigationComponent",
};
</script>
