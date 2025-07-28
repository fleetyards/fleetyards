<script lang="ts">
export default {
  name: "AppNavigationToolsNav",
};
</script>

<script lang="ts" setup>
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

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
    icon="fad fa-toolbox"
    prefix="07"
  >
    <template #submenu>
      <NavItem
        :to="{ name: 'tools' }"
        :label="t('nav.tools.index')"
        icon="fad fa-telescope"
      />
      <NavItem
        :to="{ name: 'travel-times' }"
        :label="t('nav.tools.travelTimes')"
        icon="fad fa-gauge-high"
      />
      <NavItem
        :to="{ name: 'cargo-grids' }"
        :label="t('nav.tools.cargoGrids')"
        icon="fad fa-box-taped"
      />
    </template>
  </NavItem>
</template>
