<script lang="ts">
export default {
  name: "DashboardLinkTile",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { type RouteLocationRaw } from "vue-router";

type Props = {
  label: string;
  icon: string;
  value: string;
  to: RouteLocationRaw;
  suffix?: string;
  outerSpacing?: boolean;
};

withDefaults(defineProps<Props>(), {
  suffix: undefined,
  // Matches StatsPanel's default. `panel--fill-height` subtracts the margin from
  // its min-height only when outer spacing is on, so a tile that opts out stands
  // exactly one margin taller than the StatsPanels it sits beside.
  outerSpacing: true,
});
</script>

<template>
  <!--
    StatsPanel for a value that is not a number. Same tile markup, same rail,
    same trailing icon, so it sits in a row of StatsPanels without reading as a
    different kind of card - StatsPanel itself cannot be reused because it puts
    its value through NumberFlow.
  -->
  <router-link :to="to" class="link-tile" data-test="link-tile">
    <Panel
      :variant="PanelVariantsEnum.SLIM"
      fill-height
      :outer-spacing="outerSpacing"
    >
      <PanelBody class="link-tile__body">
        <div class="metrics-card__tile metrics-card__tile--primary">
          <div class="metrics-card__tile__label">{{ label }}</div>
          <div class="metrics-card__tile__value">
            {{ value }}
            <span v-if="suffix" class="metrics-card__tile__unit">
              {{ suffix }}
            </span>
          </div>
          <i :class="icon" class="link-tile__icon" />
        </div>
      </PanelBody>
    </Panel>
  </router-link>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

.link-tile {
  display: block;
  text-decoration: none;
  color: inherit;
  height: 100%;

  &:hover,
  &:focus-visible {
    text-decoration: none;
    color: inherit;

    .metrics-card__tile {
      background: rgba(255, 255, 255, 0.04);
    }
  }

  .link-tile__body {
    padding: 0;
    flex: 1;
    display: flex;
  }

  // Grows to the height of the tallest card in the row rather than sizing to its
  // own shorter content, and centres what it holds.
  .metrics-card__tile {
    background: transparent;
    padding: 16px 18px;
    flex: 1;
    display: flex;
    flex-direction: column;
    justify-content: center;
    transition: background 0.15s ease-in-out;
  }

  .link-tile__icon {
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
}
</style>
