<template>
  <div v-if="currentFleet">
    <NavItem
      :to="{ name: 'home' }"
      :label="t('nav.back')"
      icon="fal fa-chevron-left"
      :exact="true"
    />
    <NavItem
      :to="{ name: 'fleet', params: { slug: currentFleet.slug } }"
      :label="currentFleet.name"
      :image="currentFleet.logo || undefined"
      :active="route.name === 'fleet'"
      prefix="00"
      :exact="true"
    />
    <NavItem
      v-if="currentFleet.publicFleet || currentFleet.myFleet"
      :to="{ name: 'fleet-ships', params: { slug: currentFleet.slug } }"
      :label="t('nav.fleets.ships')"
      :active="shipsNavActive"
      prefix="01"
      icon="fad fa-starship"
    />
    <template v-if="currentFleet.myFleet">
      <NavItem
        :to="{ name: 'fleet-members', params: { slug: currentFleet.slug } }"
        :label="t('nav.fleets.members')"
        :active="route.name === 'fleet-members'"
        icon="fad fa-users"
        prefix="02"
      />
      <NavItem
        :to="{ name: 'fleet-stats', params: { slug: currentFleet.slug } }"
        :label="t('nav.fleets.stats')"
        :active="route.name === 'fleet-stats'"
        icon="fad fa-chart-bar"
        prefix="03"
      />
      <NavItem
        :to="{ name: 'fleet-settings', params: { slug: currentFleet.slug } }"
        :label="t('nav.fleets.settings.index')"
        :active="route.name === 'fleet-settings'"
        icon="fad fa-cogs"
        prefix="04"
      />
    </template>
  </div>
</template>

<script lang="ts" setup>
import NavItem from "../NavItem/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useQuery } from "@tanstack/vue-query";
import { useComlink } from "@/shared/composables/useComlink";

const { t } = useI18n();
const currentFleet = computed(() => {
  if (!fleet.value) {
    return;
  }
  return fleet.value;
});

const { fleets: fleetsService } = useApiClient();

const route = useRoute();

const { data: fleet, refetch } = useQuery({
  queryKey: ["fleet", route.params.slug],
  queryFn: () =>
    fleetsService.fleet({
      slug: String(route.params.slug),
    }),
  enabled: route.params.slug !== undefined,
});

const shipsNavActive = computed(() => {
  return ["fleet-ships", "fleet-fleetchart"].includes(String(route.name));
});

const comlink = useComlink();

onMounted(() => {
  comlink.on("fleet-update", refetch);
});
</script>

<script lang="ts">
export default {
  name: "AppNavigationFleetNav",
};
</script>
