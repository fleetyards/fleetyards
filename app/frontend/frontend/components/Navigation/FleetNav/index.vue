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
  useFleetMembership as useFleetMembershipQuery,
} from "@/services/fyApi";
import { useSessionStore } from "@/frontend/stores/session";

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

const { data: membership } = useFleetMembershipQuery(fleetSlug, {
  query: {
    retry: false,
    enabled: computed(() => hasSlug.value && sessionStore.isAuthenticated),
  },
});

const currentFleet = computed(() => {
  return fleet.value || publicFleet.value;
});

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
          :to="{ name: 'fleet-settings', params: { slug: currentFleet.slug } }"
          :label="t('nav.fleets.settings.index')"
          :active="String(route.name).startsWith('fleet-settings')"
          icon="fa-duotone fa-cogs"
          prefix="04"
        />
      </template>
    </template>
  </div>
</template>
