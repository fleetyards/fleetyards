<script lang="ts">
export default {
  name: "AppNavigationVisualTestsNav",
};
</script>

<script lang="ts" setup>
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();
</script>

<template>
  <div>
    <NavItem
      :to="{ name: 'home' }"
      :label="t('nav.back')"
      icon="fa-light fa-chevron-left"
    />
    <NavItem
      :to="{ name: 'visual-tests-panels' }"
      :label="t('nav.visualTests.panels')"
      icon="fadt fa-columns-3"
      prefix="01"
    />
    <NavItem
      :to="{ name: 'visual-tests-buttons' }"
      :label="t('nav.visualTests.buttons')"
      icon="fadt fa-toggle-on"
      prefix="02"
    />
    <NavItem
      :to="{ name: 'visual-tests-typography' }"
      :label="t('nav.visualTests.typography')"
      icon="fadt fa-text-size"
      prefix="03"
    />
    <NavItem
      :to="{ name: 'visual-tests-forms' }"
      :label="t('nav.visualTests.forms')"
      icon="fadt fa-input-text"
      prefix="04"
    />
    <NavItem
      :to="{ name: 'visual-tests-tables' }"
      :label="t('nav.visualTests.tables')"
      icon="fadt fa-table"
      prefix="05"
    />
    <NavItem
      :to="{ name: 'visual-tests-lists' }"
      :label="t('nav.visualTests.lists')"
      icon="fadt fa-list-ul"
      prefix="06"
    />
    <NavItem
      :to="{ name: 'visual-tests-metrics' }"
      :label="t('nav.visualTests.metrics')"
      icon="fadt fa-gauge-high"
      prefix="07"
    />
    <NavItem
      :to="{ name: 'visual-tests-states' }"
      :label="t('nav.visualTests.states')"
      icon="fadt fa-spinner"
      prefix="08"
    />
    <NavItem
      :to="{ name: 'visual-tests-notifications' }"
      :label="t('nav.visualTests.notifications')"
      icon="fadt fa-bell"
      prefix="09"
    />
    <NavItem
      :to="{ name: 'visual-tests-sync-modal' }"
      :label="t('nav.visualTests.syncModal')"
      icon="fadt fa-arrows-rotate"
      prefix="10"
    />
    <NavItem
      :to="{ name: 'visual-tests-support-hint' }"
      :label="t('nav.visualTests.supportHint')"
      icon="fadt fa-heart"
      prefix="11"
    />
    <NavItem
      :to="{ name: 'visual-tests-chips' }"
      :label="t('nav.visualTests.chips')"
      icon="fadt fa-tag"
      prefix="12"
    />
    <NavItem
      :to="{ name: 'visual-tests-events' }"
      :label="t('nav.visualTests.events')"
      icon="fadt fa-calendar-day"
      prefix="13"
    />
  </div>
</template>
