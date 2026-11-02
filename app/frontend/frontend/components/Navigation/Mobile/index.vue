<script lang="ts">
export default {
  name: "FrontendNavigationMobile",
};
</script>

<script lang="ts" setup>
import { SHIP_GLYPH } from "@/shared/glyphs/ships";
import AppNavigationMobile from "@/shared/components/AppNavigation/Mobile/index.vue";
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import NotificationsNav from "@/frontend/components/Navigation/NotificationsNav/index.vue";
import FleetHub from "./FleetHub/index.vue";
import { useSessionStore } from "@/frontend/stores/session";
import { storeToRefs } from "pinia";
import { useNavContext } from "@/frontend/composables/useNavContext";
import { useHangarStore } from "@/frontend/stores/hangar";
import { useNavStore } from "@/shared/stores/nav";
import { useFleetNavAccess } from "@/frontend/composables/useFleetNavAccess";
import { fleetInitials } from "@/frontend/utils/fleetInitials";
import {
  useFleet as useFleetQuery,
  usePublicFleet as usePublicFleetQuery,
} from "@/services/fyApi";

const sessionStore = useSessionStore();

const { isAuthenticated } = storeToRefs(sessionStore);

const route = useRoute();

// The sidebar's context, so an account page opened from a fleet keeps the
// fleet's tabs here as well.
const { fleetSlug: contextFleetSlug } = useNavContext();

const isFleetRoute = computed(() => !!contextFleetSlug.value);

const hangarStore = useHangarStore();

const { preview: hangarPreview } = storeToRefs(hangarStore);

const navStore = useNavStore();

const { collapsed: navCollapsed } = storeToRefs(navStore);

const routeActive = (routeName: string) => {
  return routeName === route.name;
};

const fleetSlug = computed(() => contextFleetSlug.value ?? "");

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

const { showContractsNav, showEventsNav } = useFleetNavAccess(currentFleet);

const hubOpen = ref(false);

// The drawer slides the bar aside, and the sheet docked to it with it.
watch(navCollapsed, (collapsed) => {
  if (!collapsed) {
    hubOpen.value = false;
  }
});

watch([isFleetRoute, currentFleet], ([inFleet, fleet]) => {
  if (!inFleet || !fleet) {
    hubOpen.value = false;
  }
});
</script>

<template>
  <AppNavigationMobile v-if="route.name">
    <template v-if="isFleetRoute && currentFleet" #overlay>
      <FleetHub v-model:open="hubOpen" :fleet="currentFleet" />
    </template>
    <template v-if="isFleetRoute">
      <template v-if="currentFleet">
        <NavItem
          :to="{ name: 'home' }"
          :active="routeActive('home')"
          icon="fa-duotone fa-home-alt"
        />
        <NavItem
          v-if="isAuthenticated || !hangarPreview"
          :to="{ name: 'hangar' }"
          icon="fa-duotone fa-warehouse"
        />
        <NavItem
          v-else
          :to="{ name: 'hangar-preview' }"
          icon="fa-light fa-warehouse"
        />
        <!-- Every section of the fleet, and the way out of it, behind its own
             mark: the bar keeps one shape whatever the reader's role. -->
        <li class="fleet-hub-trigger">
          <button
            type="button"
            class="fleet-hub-trigger__button"
            :class="{ 'fleet-hub-trigger__button--open': hubOpen }"
            :aria-label="currentFleet.name"
            :aria-expanded="hubOpen"
            aria-controls="fleet-hub-sheet"
            data-test="fleet-hub-trigger"
            @click="hubOpen = !hubOpen"
          >
            <img
              v-if="currentFleet.logo?.smallUrl"
              :src="currentFleet.logo.smallUrl"
              alt=""
              class="fleet-hub-trigger__logo"
            />
            <span v-else aria-hidden="true">
              {{ fleetInitials(currentFleet.name) }}
            </span>
          </button>
          <!-- The fleet tour spotlights these sections on the hub's button,
               and skips a step whose section is switched off. -->
          <span
            v-if="showEventsNav"
            class="fleet-hub-trigger__tour"
            data-tour="fleet-events"
          />
          <span
            v-if="showContractsNav"
            class="fleet-hub-trigger__tour"
            data-tour="fleet-contracts"
          />
        </li>
        <NotificationsNav v-if="isAuthenticated" icon-only />
      </template>
    </template>
    <template v-else>
      <NavItem
        :to="{ name: 'home' }"
        :active="routeActive('home')"
        icon="fa-duotone fa-home-alt"
      />
      <NavItem :to="{ name: 'ships' }" :icon="SHIP_GLYPH" />
      <NavItem
        v-if="isAuthenticated || !hangarPreview"
        :to="{ name: 'hangar' }"
        icon="fa-duotone fa-warehouse"
      />
      <NavItem
        v-else
        :to="{ name: 'hangar-preview' }"
        icon="fa-light fa-warehouse"
      />
      <NotificationsNav v-if="isAuthenticated" icon-only />
    </template>
  </AppNavigationMobile>
</template>

<style lang="scss" scoped>
.fleet-hub-trigger__button {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 56px;
  height: 56px;
  margin-top: -18px;
  padding: 0;
  overflow: hidden;
  font-family: "Orbitron", sans-serif;
  font-size: 1.125rem;
  color: var(--color-lifted, #eee);
  background: var(--color-gray-black, #1a1d21);
  border: 2px solid var(--color-edge, rgb(122 130 136 / 0.5));
  border-radius: 50%;
  cursor: pointer;
  transition:
    border-color 150ms ease,
    box-shadow 150ms ease;

  &--open {
    border-color: var(--color-primary, #428bca);
    box-shadow: 0 0 12px
      color-mix(in srgb, var(--color-primary-shade, #245682) 90%, transparent);
  }
}

.fleet-hub-trigger__tour {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.fleet-hub-trigger__logo {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
</style>
