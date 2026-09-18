<script lang="ts">
export default {
  name: "AppNavigationCatalogueNav",
};
</script>

<script lang="ts" setup>
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const route = useRoute();

// The section holds four catalogues eventually -- components, blueprints,
// equipment and commodities. A tenant appears here when its pages exist, not
// when its API does: a tab pointing at a route with no page sends a visitor to
// the app's generic not-found, which is worse than the tab being absent.
//
// Each tenant names its list route and its detail route. A detail page is a
// sibling of its list rather than a child of it, so vue-router's own active
// matching does not light the list's tab there -- the tenant has to say which
// routes are its own, the way the flat Components tab did before it moved in
// here.
const TENANTS = {
  components: ["components", "component"],
  blueprints: ["blueprints", "blueprint"],
};

const isActive = (tenant: keyof typeof TENANTS) =>
  TENANTS[tenant].includes(String(route.name));

const active = computed(() =>
  Object.keys(TENANTS).some((tenant) =>
    isActive(tenant as keyof typeof TENANTS),
  ),
);
</script>

<template>
  <NavItem
    :label="t('nav.catalogue.index')"
    menu-key="catalogue-menu"
    :submenu-active="active"
    icon="fa-duotone fa-books"
    prefix="04"
  >
    <template #submenu>
      <NavItem
        :to="{ name: 'components' }"
        :label="t('nav.catalogue.components')"
        :active="isActive('components')"
        icon="fa-duotone fa-microchip"
      />
      <NavItem
        :to="{ name: 'blueprints' }"
        :label="t('nav.catalogue.blueprints')"
        :active="isActive('blueprints')"
        icon="fa-duotone fa-notes"
      />
    </template>
  </NavItem>
</template>
