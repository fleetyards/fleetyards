<script lang="ts">
export default {
  name: "AdminNavigationVisualTestsNav",
};
</script>

<script lang="ts" setup>
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

/*
 * Replaces the admin nav while the gallery is open, the same way the frontend's
 * does: inside a gallery the twenty admin sections are noise, and the pages of
 * the gallery are what you want to move between.
 *
 * Explicit entries rather than derived from the routes, matching the frontend -
 * the order here is editorial, and the route file's order is not.
 */
const { t } = useI18n();
</script>

<template>
  <div>
    <NavItem
      :to="{ name: 'home' }"
      :label="t('nav.back')"
      icon="fa-light fa-chevron-left"
    />
    <NavItem
      :to="{ name: 'admin-visual-tests-notifications' }"
      :label="t('nav.admin.visualTests.notifications')"
      icon="fadt fa-bell"
      prefix="01"
    />
  </div>
</template>
