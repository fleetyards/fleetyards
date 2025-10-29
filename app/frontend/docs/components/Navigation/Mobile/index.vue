<script lang="ts">
export default {
  name: "FrontendNavigationMobile",
};
</script>

<script lang="ts" setup>
import AppNavigationItems from "@/shared/components/AppNavigation/Items/index.vue";
import AppNavigationMobile from "@/shared/components/AppNavigation/Mobile/index.vue";
import { storeToRefs } from "pinia";
import { useSessionStore } from "@/admin/stores/session";
import { routes } from "@/docs/pages/routes";

const mobileRoutes = computed(() => {
  return routes
    .filter((route) => route.meta?.mobileNav !== undefined)
    .sort((a, b) => {
      if (a.meta?.mobileNav !== undefined && b.meta?.mobileNav !== undefined) {
        return a.meta.mobileNav - b.meta.mobileNav;
      }

      return 0;
    });
});

const route = useRoute();

const sessionStore = useSessionStore();

const { isAuthenticated } = storeToRefs(sessionStore);
</script>

<template>
  <AppNavigationMobile>
    <AppNavigationItems
      :routes="mobileRoutes"
      :current-route="route"
      :authenticated="isAuthenticated"
    />
  </AppNavigationMobile>
</template>
