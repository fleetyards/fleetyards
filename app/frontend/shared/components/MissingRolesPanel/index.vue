<script lang="ts">
export default {
  name: "MissingRolesPanel",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  roles: string[];
  outerSpacing?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  outerSpacing: true,
});

const { t } = useI18n();

const labels = computed(() =>
  props.roles.map((role) =>
    role.replace(/_/g, " ").replace(/\b\w/g, (letter) => letter.toUpperCase()),
  ),
);
</script>

<template>
  <!--
    Same tile as StatsPanel rather than a headed Panel with a prose paragraph:
    this sits in the stats grid beside a dozen tiles, and an H2 plus a
    comma-joined sentence was the one block on the page in a different language.
    The chips stand in for the figure - a count above a list of that many chips
    said the same thing twice and cost the tile a whole line of height.
  -->
  <Panel
    class="missing-roles-panel"
    :variant="PanelVariantsEnum.SLIM"
    :outer-spacing="outerSpacing"
    fill-height
  >
    <PanelBody class="missing-roles-panel__body">
      <div class="metrics-card__tile metrics-card__tile--primary">
        <div class="metrics-card__tile__label">
          {{ t("labels.hangarMetrics.missingClassifications") }}
        </div>
        <i class="fa-duotone fa-puzzle-piece fa-4x missing-roles-panel__icon" />
        <ul class="missing-roles-panel__list">
          <li
            v-for="label in labels"
            :key="label"
            class="missing-roles-panel__chip"
          >
            {{ label }}
          </li>
        </ul>
      </div>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

// Stretched so the box matches the figure-bearing tiles beside it - one or two
// chips make a shorter panel, and a short tile in a row of tall ones reads as a
// rendering fault. The content stays top-aligned inside it, so the label sits on
// the same line as every other tile's.
.missing-roles-panel__body {
  display: flex;
  flex: 1 0 auto;
  padding: 0;
}

.missing-roles-panel {
  .metrics-card__tile {
    display: flex;
    flex: 1;
    flex-direction: column;
    background: transparent;
    padding: 16px 18px;
  }

  // Both keep clear of the icon: it is centred on the tile as StatsPanel's is,
  // so with three rows of chips the glyph sits over the middle one.
  .metrics-card__tile__label,
  .missing-roles-panel__list {
    padding-right: 46px;
  }

  .missing-roles-panel__icon {
    position: absolute;
    top: 50%;
    right: 16px;
    transform: translateY(-50%);
    font-size: 34px;
    color: $gray-lighter;
    opacity: 0.4;
    --fa-secondary-opacity: 1;
    pointer-events: none;
  }

  .missing-roles-panel__list {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
    margin: 0;
    padding: 0;
    list-style: none;
  }

  // The toggle pill's shape without its affordances - these are read-only, so
  // no hover and a quieter edge than a control would carry.
  .missing-roles-panel__chip {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 10px;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    padding: 5px 11px;
    color: $text-color;
    border: 1px solid rgba($gray-light, 0.35);
    border-radius: 999px;
  }
}
</style>
