<script lang="ts">
export default {
  name: "AppNavigationToolsNav",
};
</script>

<script lang="ts" setup>
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFeatures } from "@/frontend/composables/useFeatures";

const { t } = useI18n();
const { isFeatureEnabled } = useFeatures();

const route = useRoute();

const active = computed(() => {
  return ["tools", "travel-times", "cargo-grids"].includes(String(route.name));
});
</script>

<template>
  <NavItem
    :label="t('nav.tools.index')"
    menu-key="tools-menu"
    :submenu-active="active"
    icon="fa-duotone fa-toolbox"
    prefix="07"
  >
    <template #submenu>
      <NavItem
        :to="{ name: 'tools' }"
        :label="t('nav.tools.index')"
        icon="fa-duotone fa-browsers"
      />
      <NavItem
        v-if="isFeatureEnabled('tools_travel_times')"
        :to="{ name: 'travel-times' }"
        :label="t('nav.tools.travelTimes')"
        icon="fa-duotone fa-gauge-high"
      />
      <NavItem
        v-if="isFeatureEnabled('tools_cargo_grids')"
        :to="{ name: 'cargo-grids' }"
        :label="t('nav.tools.cargoGrids')"
        icon="fa-duotone fa-thin fa-cubes"
      />
    </template>
  </NavItem>
</template>
