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
import { type RouteRecordRaw } from "vue-router";
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

const { isAuthenticated, currentUser, resourceAccess } =
  storeToRefs(sessionStore);

const hasAccessTo = (access?: string[]) => {
  return checkAccess(resourceAccess.value, access) || sessionStore.isSuperAdmin;
};

/*
 * Nineteen sections stood side by side, with Maintenance the only group. Grouped
 * by what the thing is, so the list is a handful of rows instead of nineteen.
 *
 * Presentation only: the members are route names, not nested routes, so no URL
 * moves. Each group's members are rendered by AppNavigationItems, which keeps
 * the access and feature-flag filtering rather than reimplementing it here.
 *
 * A group earns its drawer by being the thing the public site calls a section.
 * "Catalogue" holds what the public catalogue has tenants for and nothing else:
 * Models, Manufacturers and Images were in here too, which made the admin's
 * catalogue mean something different from the one a visitor browses, and buried
 * three of the most-used sections a click deep. They stand on their own now, and
 * so does Supporter Contributions.
 */
const GROUPS = [
  {
    key: "catalogue",
    // The section icon the public catalogue's own nav uses.
    icon: "fa-duotone fa-books",
    paths: ["/components/", "/equipment/", "/commodities/"],
  },
  {
    key: "community",
    icon: "fa-duotone fa-users",
    paths: ["/vehicles/", "/fleets/"],
  },
  {
    key: "people",
    icon: "fa-duotone fa-user-shield",
    paths: ["/users", "/admins/"],
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

const homeRoute = computed(() =>
  mainRoutes.value.filter((route) => String(route.path) === "/"),
);

/*
 * Mirrors the filtering AppNavigationItems applies to the members: without it a
 * group header renders even when every member of it is hidden, which is how the
 * whole grouped nav stayed visible while logged out.
 */
const isRouteVisible = (route: RouteRecordRaw) => {
  if (isAuthenticated.value) {
    if (route.meta?.hideWhenAuthenticated) {
      return false;
    }
  } else if (route.meta?.needsAuthentication) {
    return false;
  }

  return hasAccessTo(route.meta?.access);
};

/*
 * The nav in route order, with each group standing where its first member does.
 *
 * Built as one list rather than "the groups, then whatever they missed": a
 * section that belongs to no group is not an afterthought to be swept up at the
 * bottom -- Models would have rendered below System -- it is simply a row in the
 * same order routes.ts already puts everything in. Walking the routes is also
 * still the safety net the sweep was: a newly added section appears in the nav
 * rather than vanishing from it.
 */
type NavEntry =
  | { kind: "route"; route: RouteRecordRaw }
  | { kind: "group"; group: (typeof GROUPS)[number] };

const navEntries = computed<NavEntry[]>(() => {
  const seen = new Set<string>();

  return mainRoutes.value.reduce<NavEntry[]>((entries, route) => {
    const path = String(route.path);

    // Home is rendered on its own, ahead of everything.
    if (path === "/") return entries;

    const group = GROUPS.find((candidate) => candidate.paths.includes(path));

    if (!group) {
      if (isRouteVisible(route)) entries.push({ kind: "route", route });

      return entries;
    }

    if (seen.has(group.key)) return entries;
    seen.add(group.key);

    if (groupRoutes(group).some(isRouteVisible)) {
      entries.push({ kind: "group", group });
    }

    return entries;
  }, []);
});

const entryKey = (entry: NavEntry) =>
  entry.kind === "group" ? entry.group.key : String(entry.route.path);

const groupActive = (group: (typeof GROUPS)[number]) =>
  groupRoutes(group).some(
    (route) =>
      String(route.name) === String(currentRoute.name) ||
      currentRoute.matched.some((match) => match.path === route.path),
  );

const footerRoutes = computed(() => {
  return routes.filter((route) => route.meta?.nav === "footer");
});

const logout = async () => {
  await sessionStore.logout();
};

// Inside the gallery its own pages replace the admin sections, so the nav is
// about where you are rather than about everything there is.
const isVisualTestsRoute = computed(() =>
  String(currentRoute.name).startsWith("admin-visual-tests"),
);
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
        <!-- One list, in route order: a group stands where its first member
             does, and a section belonging to no group is a row like any other
             rather than a leftover swept to the bottom. -->
        <template v-for="entry in navEntries" :key="entryKey(entry)">
          <NavItem
            v-if="entry.kind === 'group'"
            :label="t(`nav.admin.groups.${entry.group.key}`)"
            :menu-key="`admin-${entry.group.key}`"
            :submenu-active="groupActive(entry.group)"
            :icon="entry.group.icon"
          >
            <template #submenu>
              <AppNavigationItems
                :routes="groupRoutes(entry.group)"
                :current-route="currentRoute"
                :authenticated="isAuthenticated"
                :has-access-to="hasAccessTo"
              />
            </template>
          </NavItem>
          <AppNavigationItems
            v-else
            :routes="[entry.route]"
            :current-route="currentRoute"
            :authenticated="isAuthenticated"
            :has-access-to="hasAccessTo"
          />
        </template>
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
