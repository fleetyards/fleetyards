<script lang="ts">
export default {
  name: "AppNavigationEntriesNav",
};
</script>

<script lang="ts" setup>
import type { Glyph } from "@/shared/components/DuotoneGlyph/glyph";
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import EntryItem from "@/frontend/components/Navigation/EntryItem/index.vue";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { useSessionStore } from "@/frontend/stores/session";
import { storeToRefs } from "pinia";
import {
  type NavEntry,
  isAnyEntryActive,
} from "@/frontend/components/Navigation/entries";

/*
 * A section of the navigation built from the registry: one row that opens a
 * submenu, with the groups inside it separated by dividers. The section marks
 * itself while any of its pages is open, unless the caller knows better.
 */
type Props = {
  label: string;
  icon: string | Glyph;
  menuKey: string;
  groups: NavEntry[][];
  // For a section that also owns pages it does not list, like the hangar's
  // vehicle pages.
  active?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  active: false,
});

const route = useRoute();

const { isFeatureEnabled } = useFeatures();

const { isAuthenticated } = storeToRefs(useSessionStore());

const visibleGroups = computed(() =>
  props.groups
    .map((group) =>
      group.filter(
        (entry) =>
          (!entry.requiresAuth || isAuthenticated.value) &&
          (!entry.featureFlag || isFeatureEnabled(entry.featureFlag)),
      ),
    )
    .filter((group) => group.length),
);

const submenuActive = computed(
  () =>
    props.active || isAnyEntryActive(props.groups, String(route.name ?? "")),
);
</script>

<template>
  <NavItem
    :label="label"
    :menu-key="menuKey"
    :submenu-active="submenuActive"
    :icon="icon"
  >
    <template #submenu>
      <template v-for="(group, index) in visibleGroups" :key="index">
        <NavItem v-if="index > 0" divider />
        <EntryItem v-for="entry in group" :key="entry.key" :entry="entry" />
      </template>
    </template>
  </NavItem>
</template>
