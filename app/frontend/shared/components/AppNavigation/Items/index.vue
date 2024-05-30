<script lang="ts">
export default {
  name: "AppNavigationItems",
};
</script>
<script lang="ts" setup>
import {
  type RouteLocationNormalizedLoaded,
  type RouteRecordRaw,
} from "vue-router";
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

type NavTypes = "main" | "footer" | "hidden";

type Props = {
  routes: RouteRecordRaw[];
  currentRoute: RouteLocationNormalizedLoaded;
  authenticated: boolean;
};

const props = defineProps<Props>();

const { t } = useI18n();

const filteredRoutes = computed(() => {
  if (props.authenticated) {
    return props.routes.filter((route) => !route.meta?.hideWhenAuthenticated);
  } else {
    return props.routes.filter((route) => !route.meta?.needsAuthentication);
  }
});

const filteredChildRoutes = (
  children: RouteRecordRaw[],
  nav: NavTypes = "main",
) => {
  return children.filter(
    (child) =>
      !child.children &&
      (child.meta?.nav === nav || (!child.meta?.nav && nav === "main")),
  );
};

const isActive = (route: RouteRecordRaw) => {
  return [props.currentRoute.name, props.currentRoute.meta?.activeRoute]
    .filter((item) => item)
    .includes(route.name);
};

const isSubmenuActive = (route: RouteRecordRaw): boolean => {
  return (route.children || []).some((child) => {
    if (child.children) {
      return isSubmenuActive(child);
    }

    return isActive(child);
  });
};

const hasSubmenu = (route: RouteRecordRaw) => {
  const childRoutes = filteredChildRoutes(route.children || []);

  return childRoutes.length > 1;
};

const menuKey = (route: RouteRecordRaw) => {
  return route.children
    ? `admin-menu-${route.children[0].name as string}`
    : undefined;
};

const routeTo = (route: RouteRecordRaw, nav: NavTypes = "main") => {
  const childRoutes = filteredChildRoutes(route.children || [], nav);

  if (childRoutes.length == 1) {
    return { name: childRoutes[0].name };
  }

  return { name: route.name };
};
</script>

<template>
  <NavItem
    v-for="route in filteredRoutes"
    :key="route.name"
    :to="routeTo(route)"
    :label="t(`nav.${route.meta?.title}`)"
    :submenu-active="isSubmenuActive(route)"
    :active="isActive(route)"
    :menu-key="menuKey(route)"
    :icon="route.meta?.icon"
  >
    <template v-if="hasSubmenu(route)" #submenu>
      <NavItem
        v-for="child in filteredChildRoutes(route.children || [])"
        :key="child.name"
        :to="{ name: child.name }"
        :label="t(`nav.${child.meta?.title}`)"
        :icon="child.meta?.icon"
        :active="isActive(child)"
      />
    </template>
  </NavItem>
</template>
