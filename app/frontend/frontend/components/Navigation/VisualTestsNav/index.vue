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
    members: [
      "typography",
      "panels",
      "buttons",
      "chips",
      "verifiedBadges",
      "media",
      "themes",
    ],
  },
  {
    key: "data",
    icon: "fadt fa-chart-simple",
    members: ["tables", "lists", "metrics", "charts"],
  },
  {
    key: "feedback",
    icon: "fadt fa-comment-dots",
    members: [
      "alerts",
      "states",
      "notifications",
      "notification-center",
      "install-prompt",
      "support-hint",
      "sync-modal",
      "buyback-sync-modal",
      "rsi-verification-modal",
      "fleet-rsi-verification-modal",
      "overlays",
    ],
  },
  {
    key: "features",
    icon: "fadt fa-puzzle-piece",
    members: ["blueprints", "squadrons"],
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
  verifiedBadges: {
    route: "visual-tests-verified-badges",
    label: "verifiedBadges",
    icon: "fadt fa-badge-check",
  },
  media: {
    route: "visual-tests-media",
    label: "media",
    icon: "fadt fa-image",
  },
  themes: {
    route: "visual-tests-themes",
    label: "themes",
    icon: "fadt fa-palette",
  },
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
  alerts: {
    route: "visual-tests-alerts",
    label: "alerts",
    icon: "fadt fa-circle-exclamation",
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
  "notification-center": {
    route: "visual-tests-notification-center",
    label: "notificationCenter",
    icon: "fadt fa-inbox",
  },
  "install-prompt": {
    route: "visual-tests-install-prompt",
    label: "installPrompt",
    icon: "fadt fa-mobile-screen",
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
  "buyback-sync-modal": {
    route: "visual-tests-buyback-sync-modal",
    label: "buybackSyncModal",
    icon: "fadt fa-clock-rotate-left",
  },
  "rsi-verification-modal": {
    route: "visual-tests-rsi-verification-modal",
    label: "rsiVerificationModal",
    icon: "fadt fa-badge-check",
  },
  "fleet-rsi-verification-modal": {
    route: "visual-tests-fleet-rsi-verification-modal",
    label: "fleetRsiVerificationModal",
    icon: "fadt fa-shield-check",
  },
  overlays: {
    route: "visual-tests-overlays",
    label: "overlays",
    icon: "fadt fa-window-restore",
  },
  blueprints: {
    route: "visual-tests-blueprints",
    label: "blueprints",
    icon: "fadt fa-compass-drafting",
  },
  squadrons: {
    route: "visual-tests-squadrons",
    label: "squadrons",
    icon: "fadt fa-people-group",
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
  <NavItem
    :to="{ name: 'home' }"
    :label="t('nav.back')"
    icon="fa-light fa-chevron-left"
  />

  <NavItem
    v-for="group in GROUPS"
    :key="group.key"
    :label="t(`nav.visualTests.groups.${group.key}`)"
    :menu-key="`visual-tests-${group.key}-menu`"
    :submenu-active="groupActive(group.members)"
    :icon="group.icon"
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
  />
  <NavItem
    :to="{ name: 'visual-tests-events' }"
    :label="t('nav.visualTests.events')"
    icon="fadt fa-calendar-day"
  />
</template>
