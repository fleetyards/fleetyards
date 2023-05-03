<template>
  <NavItem
    :label="t('nav.fleets.index')"
    :submenu-active="active"
    menu-key="fleets-menu"
    icon="fad fa-users"
    prefix="04"
  >
    <template slot="submenu">
      <NavItem
        v-for="fleet in collection.records"
        :key="fleet.slug"
        :menu-key="fleet.slug"
        :to="{ name: 'fleet', params: { slug: fleet.slug } }"
        :label="fleet.name"
        :image="fleet.logo"
      />
      <NavItem
        v-if="isAuthenticated && invitesCollection.records.length"
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
import { computed, onMounted, watch } from "vue";
import { useRoute } from "vue-router/composables";
import { storeToRefs } from "pinia";
import NavItem from "@/frontend/core/components/Navigation/NavItem/index.vue";
import fleetsCollection from "@/frontend/api/collections/Fleets";
import type { FleetsCollection } from "@/frontend/api/collections/Fleets";
import fleetInvitesCollection from "@/frontend/api/collections/FleetInvites";
import type { FleetInvitesCollection } from "@/frontend/api/collections/FleetInvites";
import { useSessionStore } from "@/frontend/stores/Session";
import { useFleetStore } from "@/frontend/stores/Fleet";
import { useI18n } from "@/frontend/composables/useI18n";

const { t } = useI18n();

const collection: FleetsCollection = fleetsCollection;

const invitesCollection: FleetInvitesCollection = fleetInvitesCollection;

const sessionStore = useSessionStore();
const { isAuthenticated } = storeToRefs(sessionStore);

const fleetStore = useFleetStore();
const { preview: fleetPreview } = storeToRefs(fleetStore);

const route = useRoute();

const active = computed(() =>
  ["fleets", "fleet-add", "fleet-preview", "fleet-invites"].includes(
    route.name || ""
  )
);

const fetch = async () => {
  if (!isAuthenticated.value) {
    return;
  }

  await collection.findAllForCurrent("nav");
  await invitesCollection.findAllForCurrent("nav");
};

watch(
  () => route,
  () => {
    fetch();
  },
  { deep: true }
);

onMounted(() => {
  fetch();
});
</script>

<script lang="ts">
export default {
  name: "FleetsNav",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
