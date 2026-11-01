<script lang="ts">
export default {
  name: "FrontendNavigation",
};
</script>

<script lang="ts" setup>
import { SHIP_GLYPH } from "@/shared/glyphs/ships";
import { useNavContext } from "@/frontend/composables/useNavContext";
import { useI18n } from "@/shared/composables/useI18n";
import AppNavigation from "@/shared/components/AppNavigation/index.vue";
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";

import ScDataSourceSwitch from "@/frontend/components/ScDataSource/index.vue";

import FleetNav from "./FleetNav/index.vue";
import CatalogueNav from "@/frontend/components/Navigation/CatalogueNav/index.vue";
import FleetsNav from "./FleetsNav/index.vue";
import ToolsNav from "./ToolsNav/index.vue";
import ContextSwitcher from "./ContextSwitcher/index.vue";
import AccountMenu from "./AccountMenu/index.vue";
import EntriesNav from "./EntriesNav/index.vue";
import EntryItem from "./EntryItem/index.vue";
import {
  HANGAR_ITEMS,
  HOME_ENTRY,
  LOCATIONS_ENTRY,
  SHIPS_ITEMS,
  STATS_ENTRY,
} from "./entries";
import { useInstallPrompt } from "@/frontend/composables/useInstallPrompt";
import { useSessionStore } from "@/frontend/stores/session";
import { useHangarStore } from "@/frontend/stores/hangar";
import { storeToRefs } from "pinia";
import { useMediaQuery } from "@vueuse/core";
import favicon from "@/images/favicon-small.png";

const { t } = useI18n();

const sessionStore = useSessionStore();

const { isAuthenticated, currentUser } = storeToRefs(sessionStore);

const hangarStore = useHangarStore();

const { preview: hangarPreview } = storeToRefs(hangarStore);

const { canInstall, isIos, install: installApp } = useInstallPrompt();

// Desktop browsers offer the install in their address bar already; on phones
// and tablets it hides in a menu. iOS has no browser prompt at all, and an iPad
// with a trackpad reports a fine pointer, so it is kept by name.
const touchDevice = useMediaQuery("(pointer: coarse)");

const showInstall = computed(
  () => canInstall.value && (touchDevice.value || isIos.value),
);

const { fleetSlug: contextFleetSlug } = useNavContext();

const route = useRoute();

/*
 * Vite mode, not NODE_ENV: a build sets NODE_ENV to "production" whatever the
 * mode, so the old gate hid these routes on stage too. Mode is Rails.env, so
 * stage and the e2e build keep them and only live strips them.
 */
const visualTestsEnabled = import.meta.env.MODE !== "production";

const VisualTestsNav = visualTestsEnabled
  ? defineAsyncComponent(() => import("./VisualTestsNav/index.vue"))
  : undefined;

const isVisualTestsRoute = computed(() => {
  if (import.meta.env.MODE === "production") {
    return false;
  }

  if (!route.name) {
    return false;
  }

  return String(route.name).includes("visual-tests");
});

const isHangarRoute = computed(() => {
  if (!route.name) {
    return false;
  }

  // Every hangar route is named from its path, so they all lead with it. A
  // match anywhere in the name also lit the hangar up on `settings-hangar`.
  return String(route.name).startsWith("hangar");
});
</script>

<template>
  <AppNavigation :title="t('title.default')" :logo="favicon">
    <template v-if="isAuthenticated" #logo>
      <ContextSwitcher :logo="favicon" :title="t('title.default')" />
    </template>
    <template #main>
      <VisualTestsNav v-if="isVisualTestsRoute" />
      <template v-else>
        <!-- Inside a fleet the navigation is the fleet's alone; the switcher
             above is the way back out. -->
        <FleetNav v-if="contextFleetSlug" :slug="contextFleetSlug" />
        <template v-else>
          <EntryItem :entry="HOME_ENTRY" />
          <!-- The hangar's own pages used to be reachable only from buttons on
             the hangar page, so a signed-in reader gets them as its section. -->
          <EntriesNav
            v-if="isAuthenticated"
            :label="t('nav.hangar.index')"
            menu-key="hangar-menu"
            icon="fa-duotone fa-warehouse"
            :items="HANGAR_ITEMS"
            :active="isHangarRoute"
          />
          <NavItem
            v-else-if="!hangarPreview"
            :to="{ name: 'hangar' }"
            :label="t('nav.hangar.index')"
            :active="isHangarRoute"
            icon="fa-duotone fa-warehouse"
          />
          <NavItem
            v-else
            :to="{ name: 'hangar-preview' }"
            :label="t('nav.hangar.index')"
            icon="fa-light fa-warehouse"
          />
          <!-- A signed-in reader reaches fleets from the switcher. -->
          <FleetsNav v-if="!isAuthenticated" />
          <EntriesNav
            :label="t('nav.ships.index')"
            menu-key="ships-menu"
            :icon="SHIP_GLYPH"
            :items="SHIPS_ITEMS"
          />
          <!-- Route meta alone does not put anything here: both menus are written
             out by hand and read none of it, so `nav: "main"` on the route left
             the catalogue reachable only by typing the address. -->
          <CatalogueNav />
          <EntryItem :entry="LOCATIONS_ENTRY" />
          <ToolsNav />
          <EntryItem :entry="STATS_ENTRY" />
          <template v-if="visualTestsEnabled">
            <li class="nav-item__divider" />
            <NavItem
              :to="{ name: 'visual-tests' }"
              :label="t('nav.visualTests.index')"
              icon="fa-duotone fa-pen-swirl"
            />
          </template>
        </template>
      </template>
    </template>
    <template #footer>
      <ScDataSourceSwitch />
      <AccountMenu
        v-if="isAuthenticated && currentUser"
        :show-install="showInstall"
        @install="installApp"
      />
      <template v-else>
        <NavItem
          v-if="showInstall"
          :action="installApp"
          menu-key="install-app"
          :label="t('nav.installApp')"
          icon="fa-light fa-mobile-screen"
          data-test="install-app"
        />
        <NavItem
          key="user-menu-guest"
          :to="{ name: 'login' }"
          :label="t('nav.login')"
          icon="fa-light fa-sign-in"
        />
      </template>
    </template>
  </AppNavigation>
</template>

<style lang="scss" scoped>
@import "index";
</style>
