<script lang="ts">
export default {
  name: "AppNavigationVisualTestsNav",
};
</script>

<script lang="ts" setup>
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

/*
 * Fourteen flat entries had outgrown a single list, so the pages are grouped by
 * what they are for: the base visual language, how data is displayed, and how
 * the app reports back. Forms and Events stay on their own - a group of one is
 * just an entry wearing a folder.
 *
 * The grouping lives here and not in the route paths. Route names and URLs stay
 * flat, so the e2e specs keep working and there is one place to regroup rather
 * than two that can drift apart.
 */
const GROUPS = [
  {
    key: "foundations",
    icon: "fadt fa-shapes",
    members: ["typography", "panels", "buttons", "chips"],
  },
  {
    key: "data",
    icon: "fadt fa-chart-simple",
    members: ["tables", "lists", "metrics", "charts"],
  },
  {
    key: "feedback",
    icon: "fadt fa-comment-dots",
    members: ["states", "notifications", "support-hint", "sync-modal"],
  },
];

const ITEMS: Record<string, { route: string; label: string; icon: string }> = {
  typography: {
    route: "visual-tests-typography",
    label: "typography",
    icon: "fadt fa-text-size",
  },
  panels: {
    route: "visual-tests-panels",
    label: "panels",
    icon: "fadt fa-columns-3",
  },
  buttons: {
    route: "visual-tests-buttons",
    label: "buttons",
    icon: "fadt fa-toggle-on",
  },
  chips: { route: "visual-tests-chips", label: "chips", icon: "fadt fa-tag" },
  tables: {
    route: "visual-tests-tables",
    label: "tables",
    icon: "fadt fa-table",
  },
  lists: {
    route: "visual-tests-lists",
    label: "lists",
    icon: "fadt fa-list-ul",
  },
  metrics: {
    route: "visual-tests-metrics",
    label: "metrics",
    icon: "fadt fa-gauge-high",
  },
  charts: {
    route: "visual-tests-charts",
    label: "charts",
    icon: "fadt fa-chart-line",
  },
  states: {
    route: "visual-tests-states",
    label: "states",
    icon: "fadt fa-spinner",
  },
  notifications: {
    route: "visual-tests-notifications",
    label: "notifications",
    icon: "fadt fa-bell",
  },
  "support-hint": {
    route: "visual-tests-support-hint",
    label: "supportHint",
    icon: "fadt fa-heart",
  },
  "sync-modal": {
    route: "visual-tests-sync-modal",
    label: "syncModal",
    icon: "fadt fa-arrows-rotate",
  },
};

const { t } = useI18n();

const route = useRoute();

const groupItems = (members: string[]) =>
  members.map((member) => ITEMS[member]);

// A group stays highlighted while one of its pages is open, which is what tells
// you where you are once the submenu has closed again.
const groupActive = (members: string[]) =>
  groupItems(members).some((item) => item.route === String(route.name));
</script>

<template>
  <div>
    <NavItem
      :to="{ name: 'home' }"
      :label="t('nav.back')"
      icon="fa-light fa-chevron-left"
    />

    <NavItem
      v-for="(group, index) in GROUPS"
      :key="group.key"
      :label="t(`nav.visualTests.groups.${group.key}`)"
      :menu-key="`visual-tests-${group.key}-menu`"
      :submenu-active="groupActive(group.members)"
      :icon="group.icon"
      :prefix="String(index + 1).padStart(2, '0')"
    >
      <template #submenu>
        <NavItem
          v-for="item in groupItems(group.members)"
          :key="item.route"
          :to="{ name: item.route }"
          :label="t(`nav.visualTests.${item.label}`)"
          :icon="item.icon"
        />
      </template>
    </NavItem>

    <NavItem
      :to="{ name: 'visual-tests-forms' }"
      :label="t('nav.visualTests.forms')"
      icon="fadt fa-input-text"
      prefix="04"
    />
    <NavItem
      :to="{ name: 'visual-tests-events' }"
      :label="t('nav.visualTests.events')"
      icon="fadt fa-calendar-day"
      prefix="05"
    />
  </div>
</template>
