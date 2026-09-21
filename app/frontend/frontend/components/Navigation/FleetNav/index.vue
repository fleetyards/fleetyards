<script lang="ts">
export default {
  name: "AppNavigationFleetNav",
};
</script>

<script lang="ts" setup>
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import {
  useFleet as useFleetQuery,
  usePublicFleet as usePublicFleetQuery,
} from "@/services/fyApi";
import { useSessionStore } from "@/frontend/stores/session";
import { useFleetNavAccess } from "@/frontend/composables/useFleetNavAccess";

const { t } = useI18n();

const route = useRoute();

const sessionStore = useSessionStore();

const fleetSlug = computed(() => {
  return route.params.slug as string;
});

const hasSlug = computed(() => route.params.slug !== undefined);

const { data: fleet, refetch } = useFleetQuery(fleetSlug, {
  query: {
    retry: false,
    enabled: computed(() => hasSlug.value && sessionStore.isAuthenticated),
  },
});

const { data: publicFleet } = usePublicFleetQuery(fleetSlug, {
  query: {
    retry: false,
    enabled: computed(
      () => hasSlug.value && (!sessionStore.isAuthenticated || !fleet.value),
    ),
  },
});

const currentFleet = computed(() => {
  return fleet.value || publicFleet.value;
});

const {
  membership,
  showAssetsNav,
  assetsNavActive,
  showShipsNav,
  shipsNavActive,
  showBlueprintsNav,
  blueprintsNavActive,
  showLogisticsNav,
  logisticsNavActive,
  showSquadronsNav,
  squadronsNavActive,
  showAlliesNav,
  showContractsNav,
  showEventsNav,
  eventsNavRoute,
  contractsNavActive,
  eventsNavActive,
} = useFleetNavAccess(currentFleet);

// The tab keeps its place in the order but says where it goes: a role that
// reads missions and not events is sent to the missions list.
const eventsNavLabel = computed(() =>
  eventsNavRoute.value === "fleet-missions"
    ? t("nav.fleets.missions.index")
    : t("nav.fleets.events.index"),
);

const comlink = useComlink();

onMounted(() => {
  comlink.on("fleet-update", refetch);
});
</script>

<template>
  <div>
    <NavItem
      :to="{ name: 'home' }"
      :label="t('nav.back')"
      icon="fa-light fa-chevron-left"
    />
    <template v-if="currentFleet">
      <NavItem
        :to="{ name: 'fleet', params: { slug: currentFleet.slug } }"
        :label="currentFleet.name"
        :image="currentFleet.logo?.smallUrl || undefined"
        :active="route.name === 'fleet'"
      />
      <!-- Top-level, and staying there: this is the one tab somebody outside
           the fleet can reach, and a public surface behind a parent is a click
           added for the reader least able to guess what the parent holds. -->
      <NavItem
        v-if="showShipsNav"
        :to="{ name: 'fleet-ships', params: { slug: currentFleet.slug } }"
        :label="t('nav.fleets.ships')"
        :active="shipsNavActive"
        icon="fa-duotone fa-starship"
      />

      <NavItem
        v-if="membership"
        :to="{ name: 'fleet-members', params: { slug: currentFleet.slug } }"
        :label="t('nav.fleets.members.index')"
        :active="String(route.name).startsWith('fleet-members')"
        icon="fa-duotone fa-users"
      />

      <!-- Next to Members rather than in a group of its own: a squadron is
           the roster sub-divided, and somebody looking for one looks where
           the people are. -->
      <NavItem
        v-if="showSquadronsNav"
        :to="{ name: 'fleet-squadrons', params: { slug: currentFleet.slug } }"
        :label="t('nav.fleets.squadrons')"
        :active="squadronsNavActive"
        icon="fa-duotone fa-users-rectangle"
      />

      <!-- What the fleet holds between its members: the recipes they can make
           and the stock they have put in. -->
      <NavItem
        v-if="showAssetsNav"
        :label="t('nav.fleets.assets')"
        menu-key="fleet-assets-menu"
        :submenu-active="assetsNavActive"
        icon="fa-duotone fa-layer-group"
      >
        <template #submenu>
          <NavItem
            v-if="showBlueprintsNav"
            :to="{
              name: 'fleet-blueprints',
              params: { slug: currentFleet.slug },
            }"
            :label="t('nav.fleets.blueprints')"
            :active="blueprintsNavActive"
            icon="fa-duotone fa-notes"
          />
          <NavItem
            v-if="showLogisticsNav"
            :to="{
              name: 'fleet-logistics',
              params: { slug: currentFleet.slug },
            }"
            :label="t('nav.fleets.logistics.index')"
            :active="logisticsNavActive"
            icon="fa-duotone fa-boxes-stacked"
          />
        </template>
      </NavItem>

      <NavItem
        v-if="showContractsNav"
        :to="{
          name: 'fleet-contracts',
          params: { slug: currentFleet.slug },
        }"
        :label="t('nav.fleets.contracts.index')"
        :active="contractsNavActive"
        icon="fa-duotone fa-clipboard-list"
      />

      <!-- Tours has no row of its own: it is reached from the events page, the
           way missions already are, and this tab stays lit while a reader is
           in there. -->
      <NavItem
        v-if="showEventsNav"
        :to="{
          name: eventsNavRoute,
          params: { slug: currentFleet.slug },
        }"
        :label="eventsNavLabel"
        :active="eventsNavActive"
        icon="fa-duotone fa-calendar-day"
      />

      <!-- Every membership-only row carries its own guard rather than sharing
           a wrapper: they no longer sit together, and Stats between them is
           not one of them -- a fleet publishing its stats shows them to a
           stranger. -->
      <NavItem
        v-if="showAlliesNav"
        :to="{
          name: 'fleet-allies',
          params: { slug: currentFleet.slug },
        }"
        :label="t('nav.fleets.allies')"
        :active="String(route.name).startsWith('fleet-allies')"
        icon="fa-duotone fa-handshake"
      />
      <NavItem
        v-if="currentFleet.publicFleetStats || membership"
        :to="{ name: 'fleet-stats', params: { slug: currentFleet.slug } }"
        :label="t('nav.fleets.stats')"
        :active="route.name === 'fleet-stats'"
        icon="fa-duotone fa-chart-bar"
      />
      <NavItem
        v-if="membership"
        :to="{ name: 'fleet-settings', params: { slug: currentFleet.slug } }"
        :label="t('nav.fleets.settings.index')"
        :active="String(route.name).startsWith('fleet-settings')"
        icon="fa-duotone fa-cogs"
      />
    </template>
  </div>
</template>
