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
import ToolsNav from "./ToolsNav/index.vue";
import VisualTestsNav from "./VisualTestsNav/index.vue";
import { useSessionStore } from "@/frontend/stores/session";
import { useHangarStore } from "@/frontend/stores/hangar";
import { useFiltersStore } from "@/shared/stores/filters";
import { storeToRefs } from "pinia";
import rsiLogo from "@/images/rsi_logo.png";
import { useDestroySession as useDestroySessionMutation } from "@/services/fyApi";
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

const isVisualTestsRoute = computed(() => {
  if (process.env.NODE_ENV === "production") {
    return false;
  }

  if (!route.name) {
    return false;
  }

  return String(route.name).includes("visual-tests");
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

const filterFor = (routeName: string) => {
  if (!filters.value[routeName]) {
    return undefined;
  }

  return {
    q: filters.value[routeName],
  } as unknown as LocationQueryRaw;
};

const mutation = useDestroySessionMutation();

const logout = async () => {
  await mutation.mutateAsync();

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
    <template v-if="route.name" #main>
      <VisualTestsNav v-if="isVisualTestsRoute" />
      <FleetNav v-else-if="isFleetRoute" />
      <template v-else>
        <NavItem
          :to="{ name: 'home' }"
          :label="t('nav.home')"
          icon="fad fa-home-alt"
          prefix="01"
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
          prefix="02"
        />
        <NavItem
          v-else
          :to="{ name: 'hangar-preview' }"
          :label="t('nav.hangar')"
          icon="fal fa-warehouse"
          prefix="02"
        />
        <NavItem
          :to="{
            name: 'ships',
            query: filterFor('ships'),
          }"
          :label="t('nav.ships.index')"
          :active="isShipRoute"
          icon="fad fa-starship"
          prefix="03"
        />
        <NavItem
          :to="{ name: 'compare' }"
          :label="t('nav.compare.ships')"
          icon="fad fa-code-compare"
          prefix="04"
        />
        <FleetsNav />
        <NavItem
          :to="{ name: 'images' }"
          :label="t('nav.images')"
          icon="fad fa-images"
          prefix="06"
        />
        <ToolsNav />
        <NavItem
          :to="{ name: 'stats' }"
          :label="t('nav.stats')"
          icon="fad fa-chart-bar"
          prefix="08"
        />
      </template>
    </template>
    <template v-if="route.name" #footer>
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
