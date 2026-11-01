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
import { storeToRefs } from "pinia";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const { preview: fleetPreview } = storeToRefs(useFleetStore());

const route = useRoute();

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
