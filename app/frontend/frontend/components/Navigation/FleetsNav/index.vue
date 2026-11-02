<script lang="ts">
export default {
  name: "AppNavigationFleetsNav",
};
</script>

<script lang="ts" setup>
import { FLEET_GLYPH } from "@/shared/glyphs/fleets";
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import EntryItem from "@/frontend/components/Navigation/EntryItem/index.vue";
import { FLEET_DIRECTORY_ENTRY } from "@/frontend/components/Navigation/entries";
import { useFleetStore } from "@/frontend/stores/fleet";
import { useSessionStore } from "@/frontend/stores/session";
import { storeToRefs } from "pinia";
import { useI18n } from "@/shared/composables/useI18n";
import { useMyFleets as useMyFleetsQuery } from "@/services/fyApi";

const { t } = useI18n();

const { preview: fleetPreview } = storeToRefs(useFleetStore());

const { isAuthenticated } = storeToRefs(useSessionStore());

const route = useRoute();

const { data: fleets } = useMyFleetsQuery({
  query: { refetchOnWindowFocus: false, enabled: isAuthenticated },
});

const myFleets = computed(() => (isAuthenticated.value ? fleets.value : []));

const active = computed(() =>
  ["fleet-add", "fleet-preview", "fleet-directory"].includes(
    String(route.name),
  ),
);
</script>

<template>
  <NavItem
    :label="t('nav.fleets.index')"
    :submenu-active="active"
    menu-key="fleets-menu"
    :icon="FLEET_GLYPH"
  >
    <template #submenu>
      <NavItem
        v-for="fleet in myFleets"
        :key="fleet.slug"
        :menu-key="fleet.slug"
        :to="{ name: 'fleet', params: { slug: fleet.slug } }"
        :label="fleet.name"
        :image="fleet.logo?.smallUrl || undefined"
        :data-test="`fleets-nav-fleet-${fleet.slug}`"
      />
      <EntryItem :entry="FLEET_DIRECTORY_ENTRY" />
      <NavItem
        v-if="!fleetPreview"
        :to="{ name: 'fleet-add' }"
        :label="t('nav.fleets.add')"
        icon="fa-light fa-plus"
      />
      <NavItem
        v-else
        :to="{ name: 'fleet-preview' }"
        :label="t('nav.fleets.add')"
        icon="fa-light fa-plus"
      />
    </template>
  </NavItem>
</template>

<style lang="scss" scoped>
@import "index";
</style>
