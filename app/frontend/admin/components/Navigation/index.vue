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

/*
 * Nineteen sections stood side by side, with Maintenance the only group. Grouped
 * by what the thing is, so the list is six rows instead of nineteen.
 *
 * Presentation only: the members are route names, not nested routes, so no URL
 * moves. Each group's members are rendered by AppNavigationItems, which keeps
 * the access and feature-flag filtering rather than reimplementing it here.
 */
const GROUPS = [
  {
    key: "catalogue",
    icon: "fa-duotone fa-rocket",
    paths: [
      "/models/",
      "/components/",
      "/equipment/",
      "/commodities/",
      "/manufacturers/",
      "/images",
    ],
  },
  {
    key: "community",
    icon: "fa-duotone fa-users",
    paths: ["/vehicles/", "/fleets/"],
  },
  {
    key: "people",
    icon: "fa-duotone fa-user-shield",
    paths: ["/users", "/admins/", "/supporter-contributions/"],
  },
  {
    // Was "Maintenance", which stopped covering it once the OAuth apps moved in
    // and the maintenance URLs were flattened to top level.
    key: "system",
    icon: "fa-duotone fa-screwdriver-wrench",
    paths: [
      "/oauth-applications/",
      "/imports/",
      "/features/",
      "/workers/",
      "/pghero/",
      "/tasks/",
      "/rsi-api-status/",
    ],
  },
];

/*
 * Members are matched by path, not by route name: a section is mounted as a
 * parent with no name of its own, and it is the parent that carries the title
 * and the icon. Matching names picked up the children instead, which is how the
 * first attempt produced a menu of "missing translation".
 */
const mainRoutes = computed(() => {
  return routes.filter(
    (route) => route.meta?.nav === "main" || !route.meta?.nav,
  );
});

const groupRoutes = (group: (typeof GROUPS)[number]) =>
  mainRoutes.value.filter((route) => group.paths.includes(String(route.path)));

const groupedPaths = computed(
  () => new Set(GROUPS.flatMap((group) => group.paths)),
);

/*
 * The safety net. Rendering only Home and the groups would make a newly added
 * section vanish from the nav rather than appear in it, and nobody would notice
 * until they went looking for the page.
 */
const ungroupedRoutes = computed(() =>
  mainRoutes.value.filter(
    (route) =>
      String(route.path) !== "/" && !groupedPaths.value.has(String(route.path)),
  ),
);

const homeRoute = computed(() =>
  mainRoutes.value.filter((route) => String(route.path) === "/"),
);

const groupActive = (group: (typeof GROUPS)[number]) =>
  groupRoutes(group).some(
    (route) =>
      String(route.name) === String(currentRoute.name) ||
      currentRoute.matched.some((match) => match.path === route.path),
  );

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
          :routes="homeRoute"
          :current-route="currentRoute"
          :authenticated="isAuthenticated"
          :has-access-to="hasAccessTo"
        />
        <NavItem
          v-for="group in GROUPS"
          :key="group.key"
          :label="t(`nav.admin.groups.${group.key}`)"
          :menu-key="`admin-${group.key}`"
          :submenu-active="groupActive(group)"
          :icon="group.icon"
        >
          <template #submenu>
            <AppNavigationItems
              :routes="groupRoutes(group)"
              :current-route="currentRoute"
              :authenticated="isAuthenticated"
              :has-access-to="hasAccessTo"
            />
          </template>
        </NavItem>
        <!-- Anything a group forgot, so a new section appears rather than
             disappearing. -->
        <AppNavigationItems
          v-if="ungroupedRoutes.length"
          :routes="ungroupedRoutes"
          :current-route="currentRoute"
          :authenticated="isAuthenticated"
          :has-access-to="hasAccessTo"
        />
        <!--
          Last, and separated - but without a divider of its own: a NavItem with
          a submenu already closes with one, and System is the item above. The
          frontend's nav can add one because a plain item sits there instead.
        -->
        <template v-if="visualTestsEnabled && isAuthenticated">
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
