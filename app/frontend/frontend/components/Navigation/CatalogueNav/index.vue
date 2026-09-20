<script lang="ts">
export default {
  name: "AppNavigationCatalogueNav",
};
</script>

<script lang="ts" setup>
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  CATALOGUE_TENANTS,
  isTenantActive,
} from "@/frontend/pages/catalogue/tenants";

const { t } = useI18n();

const route = useRoute();

// The tenants and their order live with the routes they build, so this menu and
// the `/catalogue/` entry cannot disagree about which catalogue comes first.
const activeTenant = computed(() =>
  CATALOGUE_TENANTS.find((tenant) =>
    isTenantActive(tenant, String(route.name)),
  ),
);
</script>

<template>
  <NavItem
    :label="t('nav.catalogue.index')"
    menu-key="catalogue-menu"
    :submenu-active="!!activeTenant"
    icon="fa-duotone fa-books"
  >
    <template #submenu>
      <NavItem
        v-for="tenant in CATALOGUE_TENANTS"
        :key="tenant.key"
        :to="{ name: tenant.listRoute }"
        :label="t(`nav.catalogue.${tenant.key}`)"
        :active="activeTenant?.key === tenant.key"
        :icon="tenant.icon"
      />
    </template>
  </NavItem>
</template>
