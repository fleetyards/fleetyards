<script lang="ts">
export default {
  name: "AppNavigationToolsNav",
};
</script>

<script lang="ts" setup>
import EntriesNav from "@/frontend/components/Navigation/EntriesNav/index.vue";
import { TOOLS_ITEMS } from "@/frontend/components/Navigation/entries";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();
</script>

<template>
  <EntriesNav
    :label="t('nav.tools.index')"
    menu-key="tools-menu"
    icon="fa-duotone fa-toolbox"
    :items="TOOLS_ITEMS"
  />
</template>
