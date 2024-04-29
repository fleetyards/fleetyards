<script lang="ts">
export default {
  name: "AdminNavigation",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import logo from "@/images/admin/favicon.png";
import AppNavigation from "@/shared/components/AppNavigation/index.vue";
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import routes from "@/admin/pages/routes";
import { type RouteRecordRaw } from "vue-router";

const { t } = useI18n();

const currentRoute = useRoute();

const isActive = (route: RouteRecordRaw) => {
  return [currentRoute.name, currentRoute.meta?.activeRoute]
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

const menuKey = (route: RouteRecordRaw) => {
  return route.children
    ? `admin-menu-${route.children[0].name as string}`
    : undefined;
};

const filteredRoutes = computed(() => {
  return routes.filter((route) => !route.meta?.hide);
});

const filteredChildRoutes = (children: RouteRecordRaw[]) => {
  return children.filter((child) => !child.children || !child.meta?.hide);
};
</script>

<template>
  <AppNavigation :title="t('title.defaultAdmin')" :logo="logo">
    <template #main>
      <NavItem
        v-for="route in filteredRoutes"
        :key="route.name"
        :to="{ name: route.name }"
        :label="t(`nav.${route.meta?.title}`)"
        :submenu-active="isSubmenuActive(route)"
        :active="isActive(route)"
        :menu-key="menuKey(route)"
        :icon="route.meta?.icon"
      >
        <template v-if="route.children" #submenu>
          <NavItem
            v-for="child in filteredChildRoutes(route.children)"
            :key="child.name"
            :to="{ name: child.name }"
            :label="t(`nav.${child.meta?.title}`)"
            :icon="child.meta?.icon"
            :active="isActive(child)"
          />
        </template>
      </NavItem>
    </template>
  </AppNavigation>
</template>
