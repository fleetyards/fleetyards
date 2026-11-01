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
import { useI18n } from "@/shared/composables/useI18n";
import {
  type NavEntry,
  type NavSectionItem,
  isAnyEntryActive,
  isSubsection,
} from "@/frontend/components/Navigation/entries";

/*
 * A section of the navigation built from the registry: one row that opens a
 * submenu of pages, some of them folded into sub-sections of their own. The
 * section marks itself while any of its pages is open, unless the caller knows
 * better.
 */
type Props = {
  label: string;
  icon: string | Glyph;
  menuKey: string;
  items: NavSectionItem[];
  // For a section that also owns pages it does not list, like the hangar's
  // vehicle pages.
  active?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  active: false,
});

const { t } = useI18n();

const route = useRoute();

const { isFeatureEnabled } = useFeatures();

const { isAuthenticated } = storeToRefs(useSessionStore());

const visible = (entry: NavEntry) =>
  (!entry.requiresAuth || isAuthenticated.value) &&
  (!entry.featureFlag || isFeatureEnabled(entry.featureFlag));

// A sub-section left with nothing to show is left out with its rows.
const visibleItems = computed(() =>
  props.items
    .map((item) =>
      isSubsection(item)
        ? { ...item, entries: item.entries.filter(visible) }
        : item,
    )
    .filter((item) =>
      isSubsection(item) ? item.entries.length > 0 : visible(item),
    ),
);

const routeName = computed(() => String(route.name ?? ""));

const submenuActive = computed(
  () => props.active || isAnyEntryActive(props.items, routeName.value),
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
      <template v-for="item in visibleItems" :key="item.key">
        <NavItem
          v-if="isSubsection(item)"
          :label="t(item.labelKey)"
          :menu-key="item.key"
          :icon="item.icon"
          :submenu-active="isAnyEntryActive(item.entries, routeName)"
          overlay
        >
          <template #submenu>
            <EntryItem
              v-for="entry in item.entries"
              :key="entry.key"
              :entry="entry"
            />
          </template>
        </NavItem>
        <EntryItem v-else :entry="item" />
      </template>
    </template>
  </NavItem>
</template>
