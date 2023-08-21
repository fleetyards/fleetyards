<template>
  <NavItem
    :label="t('nav.compare.index')"
    :submenu-active="active"
    menu-key="compare-menu"
    icon="fad fa-code-compare"
  >
    <template slot="submenu">
      <NavItem
        :to="{ name: 'models-compare' }"
        :label="t('nav.compare.models')"
        icon="fad fa-starship"
      />
    </template>
  </NavItem>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router";
import { useI18n } from "@/frontend/composables/useI18n";
import NavItem from "../NavItem/index.vue";

const { t } = useI18n();

const route = useRoute();

const active = computed(() => ["models-compare"].includes(route.name || ""));
</script>

<script lang="ts">
export default {
  name: "CompareNav",
};
</script>
