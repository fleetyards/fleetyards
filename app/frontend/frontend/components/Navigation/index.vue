<script lang="ts">
export default {
  name: "FrontendNavigation",
};
</script>

<script lang="ts" setup>
import { type LocationQueryRaw } from "vue-router";
import { useFleetRouteCheck } from "@/frontend/composables/useFleetRouteCheck";
import { useI18n } from "@/shared/composables/useI18n";
import AppNavigation from "@/shared/components/AppNavigation/index.vue";
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import FleetNav from "./FleetNav/index.vue";
import FleetsNav from "./FleetsNav/index.vue";
import { useSessionStore } from "@/frontend/stores/session";
import { useHangarStore } from "@/frontend/stores/hangar";
import { useFiltersStore } from "@/shared/stores/filters";
import { storeToRefs } from "pinia";
import rsiLogo from "@/images/rsi_logo.png";
import { useApiClient } from "@/frontend/composables/useApiClient";
import favicon from "@/images/favicon-small.png";

const { t } = useI18n();

const sessionStore = useSessionStore();

const { isAuthenticated, currentUser } = storeToRefs(sessionStore);

const hangarStore = useHangarStore();

const { preview: hangarPreview } = storeToRefs(hangarStore);

const { isFleetRoute } = useFleetRouteCheck();

const filtersStore = useFiltersStore();

const { filters } = storeToRefs(filtersStore);

const route = useRoute();

const isToolsRoute = computed(() => {
  if (!route.name) {
    return false;
  }

  return String(route.name).includes("tools");
});

const isShipRoute = computed(() => {
  if (!route.name) {
    return false;
  }

  return ["ships", "ship", "ship-images", "ship-videos"].includes(
    String(route.name),
  );
});

const isHangarRoute = computed(() => {
  if (!route.name) {
    return false;
  }

  return String(route.name).includes("hangar");
});

watch(
  () => route.path,
  () => {
    close();
  },
);

const filterFor = (routeName: string) => {
  if (!filters.value[routeName]) {
    return undefined;
  }

  return {
    q: filters.value[routeName],
  } as unknown as LocationQueryRaw;
};

const { sessions: sessionsService } = useApiClient();

const logout = async () => {
  await sessionsService.deleteSession();

  sessionStore.logout();
};

const settingsActive = computed(() => {
  return [
    "settings-profile",
    "settings-account",
    "settings-hangar",
    "settings-notifications",
    "settings-security-status",
    "settings-two-factor-enable",
    "settings-two-factor-disable",
    "settings-two-factor-backup-codes",
    "settings-change-password",
  ].includes(String(route.name));
});
</script>

<template>
  <AppNavigation :title="t('title.default')" :logo="favicon">
    <template #main>
      <FleetNav v-if="isFleetRoute" />
      <template v-else>
        <NavItem
          :to="{ name: 'home' }"
          :label="t('nav.home')"
          icon="fad fa-home-alt"
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
            name: 'ships',
            query: filterFor('ships'),
          }"
          :label="t('nav.ships.index')"
          :active="isShipRoute"
          icon="fad fa-starship"
        />
        <NavItem
          :to="{ name: 'compare' }"
          :label="t('nav.compare.ships')"
          icon="fad fa-code-compare"
        />
        <FleetsNav />
        <NavItem
          :to="{ name: 'images' }"
          :label="t('nav.images')"
          icon="fad fa-images"
        />
        <NavItem
          :to="{ name: 'tools' }"
          :label="t('nav.tools.index')"
          icon="fad fa-toolbox"
          :active="isToolsRoute"
        />
        <NavItem
          :to="{ name: 'stats' }"
          :label="t('nav.stats')"
          icon="fad fa-chart-bar"
        />
      </template>
    </template>
    <template #footer>
      <template v-if="isAuthenticated && currentUser">
        <NavItem
          :to="{ name: 'settings' }"
          :active="settingsActive"
          :label="t('nav.settings.index')"
          icon="fal fa-cog"
        />
        <template v-if="currentUser.rsiHandle">
          <NavItem
            :href="`https://robertsspaceindustries.com/citizens/${currentUser.rsiHandle}`"
            :label="t('nav.rsiProfile')"
            :image="rsiLogo"
          />
        </template>
        <NavItem
          :action="logout"
          menu-key="logout"
          :label="t('nav.logout')"
          icon="fal fa-sign-out"
        />
        <NavItem
          menu-key="user-menu"
          :image="currentUser.avatar"
          :avatar="true"
          :label="currentUser.username"
          class="user-menu mt-1"
        />
      </template>
      <NavItem
        v-else
        key="user-menu-guest"
        :to="{ name: 'login' }"
        :label="t('nav.login')"
        icon="fal fa-sign-in"
      />
    </template>
  </AppNavigation>
</template>

<style lang="scss" scoped>
@import "index";
</style>
