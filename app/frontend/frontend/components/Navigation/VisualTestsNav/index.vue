<template>
  <div>
    <NavItem
      :to="{ name: 'home' }"
      :label="t('nav.back')"
      icon="fal fa-chevron-left"
    />
    <NavItem
      :to="{ name: 'fleet', params: { slug: currentFleet.slug } }"
      :label="currentFleet.name"
      :image="currentFleet.logo || undefined"
      :active="route.name === 'fleet'"
      prefix="00"
    />
    <NavItem
      v-if="currentFleet.publicFleet || currentFleet.myFleet"
      :to="{ name: 'fleet-ships', params: { slug: currentFleet.slug } }"
      :label="t('nav.fleets.ships')"
      :active="shipsNavActive"
      prefix="01"
      icon="fad fa-starship"
    />
  </div>
</template>

<script lang="ts" setup>
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
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
  retry: false,
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
