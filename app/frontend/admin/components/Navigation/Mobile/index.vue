<script lang="ts">
export default {
  name: "FrontendNavigationMobile",
};
</script>

<script lang="ts" setup>
import AppNavigationItems from "@/shared/components/AppNavigation/Items/index.vue";
import AppNavigationMobile from "@/shared/components/AppNavigation/Mobile/index.vue";
import AdminNotificationsNav from "@/admin/components/Notifications/index.vue";
import { storeToRefs } from "pinia";
import { useSessionStore } from "@/admin/stores/session";
import { routes } from "@/admin/pages/routes";
import { checkAccess } from "@/shared/utils/Access";

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

const { isAuthenticated, currentUser, resourceAccess } =
  storeToRefs(sessionStore);

const hasAccessTo = (access?: string[]) => {
  return checkAccess(resourceAccess.value, access) || sessionStore.isSuperAdmin;
};
</script>

<template>
  <AppNavigationMobile>
    <!-- A tab bar has no room to expand a submenu into: it would push the
         children out over the page. Each tab links to its first child. -->
    <AppNavigationItems
      :routes="mobileRoutes"
      :current-route="route"
      :authenticated="isAuthenticated"
      :has-access-to="hasAccessTo"
      hide-submenus
    />
    <AdminNotificationsNav
      v-if="isAuthenticated && currentUser"
      :authenticated="isAuthenticated"
    />
  </AppNavigationMobile>
</template>
