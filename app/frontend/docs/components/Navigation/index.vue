<script lang="ts">
export default {
  name: "AdminNavigation",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import logo from "@/images/favicons/favicon.png";
import AppNavigation from "@/shared/components/AppNavigation/index.vue";
import AppNavigationItems from "@/shared/components/AppNavigation/Items/index.vue";
import { routes } from "@/docs/pages/routes";

const { t } = useI18n();

const currentRoute = useRoute();

const mainRoutes = computed(() => {
  return routes.filter(
    (route) => route.meta?.nav === "main" || !route.meta?.nav,
  );
});

const footerRoutes = computed(() => {
  return routes.filter((route) => route.meta?.nav === "footer");
});
</script>

<template>
  <AppNavigation :title="t('title.defaultDocsShort')" :logo="logo">
    <template #main>
      <AppNavigationItems :routes="mainRoutes" :current-route="currentRoute" />
    </template>
    <template #footer>
      <AppNavigationItems
        :routes="footerRoutes"
        :current-route="currentRoute"
      />
    </template>
  </AppNavigation>
</template>
