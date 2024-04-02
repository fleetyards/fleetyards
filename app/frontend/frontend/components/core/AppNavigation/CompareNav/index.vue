<template>
  <NavItem
    :label="t('nav.compare.index')"
    :submenu-active="active"
    menu-key="compare-menu"
    icon="fad fa-code-compare"
  >
    <template #submenu>
      <NavItem
        :to="{ name: 'compare-ships' }"
        :label="t('nav.compare.ships')"
        icon="fad fa-starship"
      />
    </template>
  </NavItem>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router";
import { useI18n } from "@/shared/composables/useI18n";
import NavItem from "../NavItem/index.vue";

const { t } = useI18n();

const route = useRoute();

const active = computed(() => ["compare-ships"].includes(route.name || ""));
</script>

<script lang="ts">
export default {
  name: "CompareNav",
};
</script>
