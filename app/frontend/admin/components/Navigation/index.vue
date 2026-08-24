<script lang="ts">
export default {
  name: "AdminNavigation",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import logo from "@/images/admin/favicons/favicon.png";
import AppNavigation from "@/shared/components/AppNavigation/index.vue";
import AppNavigationItems from "@/shared/components/AppNavigation/Items/index.vue";
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import AdminNotificationsNav from "@/admin/components/Notifications/index.vue";
import { routes } from "@/admin/pages/routes";
import { storeToRefs } from "pinia";
import { useSessionStore } from "@/admin/stores/session";
import { checkAccess } from "@/shared/utils/Access";

/*
 * Vite mode, not NODE_ENV: a build sets NODE_ENV to "production" whatever the
 * mode, so a NODE_ENV gate would hide this on stage too.
 */
const visualTestsEnabled = import.meta.env.MODE !== "production";

const VisualTestsNav = visualTestsEnabled
  ? defineAsyncComponent(() => import("./VisualTestsNav/index.vue"))
  : undefined;

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

const { isAuthenticated, currentUser, resourceAccess } =
  storeToRefs(sessionStore);

const logout = async () => {
  await sessionStore.logout();
};

// Inside the gallery its own pages replace the admin sections, so the nav is
// about where you are rather than about everything there is.
const isVisualTestsRoute = computed(() =>
  String(currentRoute.name).startsWith("admin-visual-tests"),
);

const hasAccessTo = (access?: string[]) => {
  return checkAccess(resourceAccess.value, access) || sessionStore.isSuperAdmin;
};
</script>

<template>
  <AppNavigation :title="t('title.defaultAdminShort')" :logo="logo">
    <template #main>
      <VisualTestsNav v-if="isVisualTestsRoute" />
      <template v-else>
        <AppNavigationItems
          :routes="mainRoutes"
          :current-route="currentRoute"
          :authenticated="isAuthenticated"
          :has-access-to="hasAccessTo"
        />
        <!-- Last, behind a divider: a way in, not one of the admin sections. -->
        <template v-if="visualTestsEnabled && isAuthenticated">
          <li class="nav-item__divider" />
          <NavItem
            :to="{ name: 'admin-visual-tests' }"
            :label="t('nav.admin.visualTests.index')"
            icon="fa-duotone fa-pen-swirl"
          />
        </template>
      </template>
    </template>
    <template #footer>
      <AppNavigationItems
        :routes="footerRoutes"
        :current-route="currentRoute"
        :authenticated="isAuthenticated"
        :has-access-to="hasAccessTo"
      />
      <template v-if="isAuthenticated && currentUser">
        <AdminNotificationsNav :authenticated="isAuthenticated" />
        <NavItem
          :action="logout"
          menu-key="logout"
          :label="t('nav.logout')"
          icon="fa-light fa-sign-out"
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
