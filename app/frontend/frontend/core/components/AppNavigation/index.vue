<template>
  <nav
    ref="navigation"
    :class="{
      visible: !navCollapsed,
      'nav-slim': slim,
    }"
    role="navigation"
  >
    <div
      :class="{
        'nav-container-slim': slim,
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
            <span v-if="!slim" class="logo-menu-label">
              {{ t("app") }}
            </span>
          </NavItem>
          <FleetNav v-if="isFleetRoute" />
          <template v-else>
            <NavItem
              :to="{ name: 'home' }"
              :label="t('nav.home')"
              icon="fad fa-home-alt"
              :exact="true"
            />
            <NavItem
              v-if="isAuthenticated || !hangarPreview"
              :to="{
                name: 'hangar',
                query: filterFor('hangar'),
              }"
              :label="t('nav.hangar')"
              :active="isHangarRoute"
              icon="fad fa-warehouse"
            />
            <NavItem
              v-else
              :to="{ name: 'hangar-preview' }"
              :label="t('nav.hangar')"
              icon="fal fa-warehouse"
            />
            <NavItem
              :to="{
                name: 'models',
                query: filterFor('models'),
              }"
              :label="t('nav.models.index')"
              :active="isModelRoute"
              icon="fad fa-starship"
            />
            <CompareNav />
            <StationsNav />
            <FleetsNav />
            <NavItem
              :to="{ name: 'images' }"
              :label="t('nav.images')"
              icon="fad fa-images"
            />
            <ToolsNav />
            <NavItem
              :to="{ name: 'roadmap' }"
              :label="t('nav.roadmap.index')"
              icon="fad fa-tasks-alt"
              :active="isRoadmapRoute"
            />
            <NavItem
              :to="{ name: 'stats' }"
              :label="t('nav.stats')"
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
import { useRoute } from "vue-router/composables";
import { isFleetRoute as fleetRouteCheck } from "@/frontend/utils/Routes/Fleets";
import Store from "@/frontend/lib/Store";
import { useI18n } from "@/frontend/composables/useI18n";
import NavItem from "./NavItem/index.vue";
import FleetNav from "./FleetNav/index.vue";
import FleetsNav from "./FleetsNav/index.vue";
import StationsNav from "./StationsNav/index.vue";
import ToolsNav from "./ToolsNav/index.vue";
import NavFooter from "./NavFooter/index.vue";
import CompareNav from "./CompareNav/index.vue";

const { t } = useI18n();

const mobile = computed(() => Store.getters.mobile);

const navSlim = computed(() => Store.getters["app/navSlim"]);

const isAuthenticated = computed(
  () => Store.getters["session/isAuthenticated"],
);

const slim = computed(() => navSlim.value && !mobile.value);

const isFleetRoute = computed(() => fleetRouteCheck(route.name || ""));

const filters = computed(() => Store.getters.filters);

const navCollapsed = computed(() => Store.getters["app/navCollapsed"]);

const hangarPreview = computed(() => Store.getters["hangar/preview"]);

const route = useRoute();

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

  return ["models", "model", "model-images", "model-videos"].includes(
    route.name || "",
  );
});

const isHangarRoute = computed(() => {
  if (!route.name) {
    return false;
  }

  return route.name.includes("hangar");
});

watch(
  () => route.path,
  () => {
    close();
  },
);

onMounted(() => {
  document.addEventListener("click", documentClick);
});

onBeforeUnmount(() => {
  document.removeEventListener("click", documentClick);

  close();
});

const filterFor = (route: string) => {
  if (!filters[route]) {
    return null;
  }

  return {
    q: filters[route],
  };
};

const navigation = ref<HTMLElement | null>(null);

const documentClick = (event: Event) => {
  const element = navigation.value;
  const { target } = event;

  if (element !== target && !element?.contains(target as Node)) {
    close();
  }
};

const close = () => {
  Store.commit("app/closeNav");
};
</script>

<script lang="ts">
export default {
  name: "AppNavigation",
};
</script>
