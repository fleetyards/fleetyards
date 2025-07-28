<script lang="ts">
export default {
  name: "AppNavigationVisualTestsNav",
};
</script>

<script lang="ts" setup>
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();
</script>

<template>
  <div>
    <NavItem
      :to="{ name: 'home' }"
      :label="t('nav.back')"
      icon="fal fa-chevron-left"
    />
    <NavItem
      :to="{ name: 'visual-tests-panels' }"
      :label="t('nav.visualTests.panels')"
      icon="fadt fa-columns-3"
      prefix="01"
    />
    <NavItem
      :to="{ name: 'visual-tests-buttons' }"
      :label="t('nav.visualTests.buttons')"
      icon="fadt fa-toggle-on"
      prefix="02"
    />
    <NavItem
      :to="{ name: 'visual-tests-tables' }"
      :label="t('nav.visualTests.tables')"
      icon="fadt fa-table"
      prefix="02"
    />
  </div>
</template>
