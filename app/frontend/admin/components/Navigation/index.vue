<script lang="ts">
export default {
  name: "AdminNavigation",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import logo from "@/images/admin/favicon.png";
import AppNavigation from "@/shared/components/AppNavigation/index.vue";
import AppNavigationItems from "@/shared/components/AppNavigation/Items/index.vue";
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import routes from "@/admin/pages/routes";
import { storeToRefs } from "pinia";
import { useSessionStore } from "@/admin/stores/session";
import { useDestroySession as useDestroySessionMutation } from "@/services/fyAdminApi";

const { t } = useI18n();

const currentRoute = useRoute();

const sessionStore = useSessionStore();

const mainRoutes = computed(() => {
  return routes.filter(
    (route) => route.meta?.nav === "main" || !route.meta?.nav,
  );
});

const footerRoutes = computed(() => {
  return routes.filter((route) => route.meta?.nav === "footer");
});

const { isAuthenticated, currentUser } = storeToRefs(sessionStore);

const mutation = useDestroySessionMutation();

const logout = async () => {
  await mutation.mutateAsync();

  sessionStore.logout();
};
</script>

<template>
  <AppNavigation :title="t('title.defaultAdminShort')" :logo="logo">
    <template #main>
      <AppNavigationItems
        :routes="mainRoutes"
        :current-route="currentRoute"
        :authenticated="isAuthenticated"
        :has-access-to="sessionStore.hasAccessTo"
      />
    </template>
    <template #footer>
      <AppNavigationItems
        :routes="footerRoutes"
        :current-route="currentRoute"
        :authenticated="isAuthenticated"
        :has-access-to="sessionStore.hasAccessTo"
      />
      <template v-if="isAuthenticated && currentUser">
        <NavItem
          :action="logout"
          menu-key="logout"
          :label="t('nav.logout')"
          icon="fal fa-sign-out"
        />
        <NavItem
          menu-key="user-menu"
          :avatar="true"
          :label="currentUser.username"
          class="user-menu mt-1"
        />
      </template>
    </template>
  </AppNavigation>
</template>
