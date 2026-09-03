<script lang="ts">
export default {
  name: "DashboardAttentionTile",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import NumberFlow from "@number-flow/vue";
import { type RouteLocationRaw } from "vue-router";

type Props = {
  count: number;
  label: string;
  icon: string;
  to: RouteLocationRaw;
  severity?: "warning" | "error";
};

withDefaults(defineProps<Props>(), {
  severity: "warning",
});
</script>

<template>
  <!--
    A queue, not a metric. It carries a count the way StatsPanel does, but it is
    always a link: the only reason to show the number is to send somebody to the
    list it counts. The rail is coloured by severity rather than the theme accent,
    so a full band reads as a priority order and not as decoration.
  -->
  <router-link
    :to="to"
    class="attention-tile"
    :class="`attention-tile--${severity}`"
    :data-test="`attention-tile-${severity}`"
  >
    <Panel :variant="PanelVariantsEnum.SLIM" :outer-spacing="false">
      <PanelBody class="attention-tile__body">
        <div class="metrics-card__tile metrics-card__tile--primary">
          <div class="metrics-card__tile__label">{{ label }}</div>
          <div class="metrics-card__tile__value">
            <NumberFlow :value="count" />
          </div>
          <i :class="icon" class="attention-tile__icon" />
        </div>
      </PanelBody>
    </Panel>
  </router-link>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

.attention-tile {
  display: block;
  text-decoration: none;
  color: inherit;

  &:hover,
  &:focus-visible {
    text-decoration: none;
    color: inherit;

    .metrics-card__tile {
      background: rgba(255, 255, 255, 0.04);
    }
  }

  .attention-tile__body {
    padding: 0;
  }

  .metrics-card__tile {
    background: transparent;
    padding: 16px 18px;
    transition: background 0.15s ease-in-out;
  }

  // Decoration behind the figure, matching StatsPanel's treatment so the two
  // bands sit together without one shouting.
  .attention-tile__icon {
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

  /*
   * The rail is `--primary`'s inset `::after`, recoloured - not a `border-left`.
   * A border runs the full height of the tile and sits hard against its edge, so
   * it escaped the Panel's rounded corner and drew as a bar floating beside the
   * card rather than a rail on it.
   */
  &.attention-tile--warning .metrics-card__tile--primary::after {
    background: linear-gradient($warning, rgba($warning, 0.15));
  }

  &.attention-tile--error {
    .metrics-card__tile--primary::after {
      background: linear-gradient($danger, rgba($danger, 0.15));
    }

    .metrics-card__tile__value {
      color: $danger;
    }
  }
}
</style>
