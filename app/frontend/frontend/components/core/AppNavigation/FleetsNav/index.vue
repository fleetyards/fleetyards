<template>
  <NavItem
    :label="t('nav.fleets.index')"
    :submenu-active="active"
    menu-key="fleets-menu"
    icon="fad fa-users"
    prefix="04"
  >
    <template #submenu>
      <NavItem
        v-for="fleet in fleets"
        :key="fleet.slug"
        :menu-key="fleet.slug"
        :to="{ name: 'fleet', params: { slug: fleet.slug } }"
        :label="fleet.name"
        :image="fleet.logo || undefined"
      />
      <NavItem
        v-if="isAuthenticated && fleetInvites && fleetInvites.length"
        :to="{ name: 'fleet-invites' }"
        :label="t('nav.fleets.invites')"
        icon="fad fa-envelope-open-text"
      />
      <NavItem
        v-if="isAuthenticated || !fleetPreview"
        :to="{ name: 'fleet-add' }"
        :label="t('nav.fleets.add')"
        icon="fal fa-plus"
      />
      <NavItem
        v-else
        :to="{ name: 'fleet-preview' }"
        :label="t('nav.fleets.add')"
        icon="fal fa-plus"
      />
    </template>
  </NavItem>
</template>

<script lang="ts" setup>
import NavItem from "../NavItem/index.vue";
import { useFleetStore } from "@/frontend/stores/fleet";
import { storeToRefs } from "pinia";
import { useSessionStore } from "@/frontend/stores/session";
import { useI18n } from "@/frontend/composables/useI18n";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useQuery } from "@tanstack/vue-query";

const { t } = useI18n();

const fleetStore = useFleetStore();

const { preview: fleetPreview } = storeToRefs(fleetStore);

const sessionStore = useSessionStore();

const { isAuthenticated } = storeToRefs(sessionStore);

const route = useRoute();

const active = computed(() => {
  return ["fleets", "fleet-add", "fleet-preview", "fleet-invites"].includes(
    String(route.name),
  );
});

const { fleets: fleetsService } = useApiClient();

const { data: fleets, refetch: refetchMyFleets } = useQuery({
  refetchOnWindowFocus: false,
  queryKey: ["myFleets"],
  queryFn: () => fleetsService.myFleets(),
  enabled: isAuthenticated.value,
});

const { data: fleetInvites, refetch: refetchInvites } = useQuery({
  queryKey: ["myFleetInvites"],
  queryFn: () => fleetsService.fleetInvites(),
  enabled: isAuthenticated.value && active.value,
});

watch(
  () => isAuthenticated.value,
  () => {
    if (isAuthenticated.value) {
      refetchMyFleets();
      refetchInvites();
    }
  },
);
</script>

<script lang="ts">
export default {
  name: "AppNavigationFleetsNav",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
