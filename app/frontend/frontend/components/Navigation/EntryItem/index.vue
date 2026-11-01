<script lang="ts">
export default {
  name: "AppNavigationEntryItem",
};
</script>

<script lang="ts" setup>
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type NavEntry,
  isEntryActive,
} from "@/frontend/components/Navigation/entries";

type Props = {
  entry: NavEntry;
};

const props = defineProps<Props>();

const { t } = useI18n();

const route = useRoute();

const active = computed(() =>
  isEntryActive(props.entry, String(route.name ?? "")),
);
</script>

<template>
  <NavItem
    :to="{ name: entry.route }"
    :menu-key="entry.key"
    :label="t(entry.labelKey)"
    :icon="entry.icon"
    :active="active"
  />
</template>
