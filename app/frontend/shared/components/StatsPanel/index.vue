<script lang="ts">
export default {
  name: "StatsPanel",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import NumberFlow from "@number-flow/vue";

type Props = {
  label: string;
  icon: string;
  value: number;
  prefix?: string;
  suffix?: string;
  outerSpacing?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  outerSpacing: true,
  value: undefined,
  prefix: undefined,
  suffix: undefined,
});

const innerValue = computed(() => {
  return props.value;
});

const prefix = computed(() => {
  if (!props.prefix) {
    return undefined;
  }

  return ` ${props.prefix}`;
});

const suffix = computed(() => {
  if (!props.suffix) {
    return undefined;
  }

  return ` ${props.suffix}`;
});
</script>

<template>
  <!--
    A metrics tile, not a filled panel. The blue fill this used to carry came
    from Panel's bgColor and was the loudest thing on any stats page - sixteen
    saturated blocks on hangar/stats alone. The emphasis is now the tile's 3px
    $primary rail, which is how the ship page's cards mark their headline figure.

    `slim` because these repeat: sixteen full frames with end-caps in col-lg-3
    columns is exactly the noise that variant exists to avoid.
  -->
  <Panel
    class="stats-panel"
    :variant="PanelVariantsEnum.SLIM"
    :outer-spacing="outerSpacing"
  >
    <PanelBody class="stats-panel__body">
      <div class="metrics-card__tile metrics-card__tile--primary">
        <div class="metrics-card__tile__label">{{ label }}</div>
        <div class="metrics-card__tile__value">
          <NumberFlow :value="innerValue" :prefix="prefix" />
          <span v-if="suffix" class="metrics-card__tile__unit">
            {{ suffix }}
          </span>
        </div>
        <i :class="icon" class="stats-panel__icon" />
      </div>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Models/metricsCard";

/* The tile is the whole body, so the body adds no padding of its own. */
.stats-panel__body {
  padding: 0;
}

.stats-panel {
  .metrics-card__tile {
    // Its own fill and radius, rather than the hero's, since there is no shared
    // container here - one tile per panel until the host grids are collapsed.
    background: transparent;
    padding: 16px 18px;
  }

  // The icon is decoration behind the figure, not a peer of it: quiet, and out of
  // the flow so a long value keeps the full width of the tile.
  .stats-panel__icon {
    position: absolute;
    top: 50%;
    right: 16px;
    transform: translateY(-50%);
    font-size: 34px;
    color: $gray-light;
    opacity: 0.22;
    pointer-events: none;
  }
}
</style>
