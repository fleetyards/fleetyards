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
  showBlueprintsNav,
  showLogisticsNav,
  showAlliesNav,
  showContractsNav,
  showEventsNav,
  eventsNavRoute,
  showToursNav,
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

const shipsNavActive = computed(() => {
  return ["fleet-ships", "fleet-fleetchart"].includes(String(route.name));
});

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
        prefix="00"
      />
      <NavItem
        v-if="currentFleet.publicFleet || membership"
        :to="{ name: 'fleet-ships', params: { slug: currentFleet.slug } }"
        :label="t('nav.fleets.ships')"
        :active="shipsNavActive"
        prefix="01"
        icon="fa-duotone fa-starship"
      />
      <NavItem
        v-if="currentFleet.publicFleetStats || membership"
        :to="{ name: 'fleet-stats', params: { slug: currentFleet.slug } }"
        :label="t('nav.fleets.stats')"
        :active="route.name === 'fleet-stats'"
        icon="fa-duotone fa-chart-bar"
        prefix="02"
      />
      <template v-if="membership">
        <NavItem
          :to="{ name: 'fleet-members', params: { slug: currentFleet.slug } }"
          :label="t('nav.fleets.members.index')"
          :active="String(route.name).startsWith('fleet-members')"
          icon="fa-duotone fa-users"
          prefix="03"
        />
        <NavItem
          v-if="showLogisticsNav"
          :to="{
            name: 'fleet-logistics',
            params: { slug: currentFleet.slug },
          }"
          :label="t('nav.fleets.logistics.index')"
          :active="String(route.name).startsWith('fleet-logistics')"
          icon="fa-duotone fa-boxes-stacked"
          prefix="04"
        />
        <NavItem
          v-if="showBlueprintsNav"
          :to="{
            name: 'fleet-blueprints',
            params: { slug: currentFleet.slug },
          }"
          :label="t('nav.fleets.blueprints')"
          :active="route.name === 'fleet-blueprints'"
          icon="fa-duotone fa-notes"
          prefix="05"
        />
        <NavItem
          v-if="showAlliesNav"
          :to="{
            name: 'fleet-allies',
            params: { slug: currentFleet.slug },
          }"
          :label="t('nav.fleets.allies')"
          :active="String(route.name).startsWith('fleet-allies')"
          icon="fa-duotone fa-handshake"
          prefix="06"
        />
        <NavItem
          v-if="showContractsNav"
          :to="{
            name: 'fleet-contracts',
            params: { slug: currentFleet.slug },
          }"
          :label="t('nav.fleets.contracts.index')"
          :active="contractsNavActive"
          icon="fa-duotone fa-clipboard-list"
          prefix="07"
        />
        <NavItem
          v-if="showEventsNav"
          :to="{
            name: eventsNavRoute,
            params: { slug: currentFleet.slug },
          }"
          :label="eventsNavLabel"
          :active="eventsNavActive"
          icon="fa-duotone fa-calendar-day"
          prefix="08"
        />
        <NavItem
          v-if="showToursNav"
          :to="{
            name: 'fleet-tours',
            params: { slug: currentFleet.slug },
          }"
          :label="t('nav.fleets.tours')"
          :active="String(route.name).startsWith('fleet-tour')"
          icon="fa-duotone fa-coins"
          prefix="09"
        />
        <NavItem
          :to="{ name: 'fleet-settings', params: { slug: currentFleet.slug } }"
          :label="t('nav.fleets.settings.index')"
          :active="String(route.name).startsWith('fleet-settings')"
          icon="fa-duotone fa-cogs"
          prefix="10"
        />
      </template>
    </template>
  </div>
</template>
